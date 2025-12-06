#!/bin/bash
set -e

# Vérifie que les variables d'environnement sont définies
if [[ -z "$PR_URL" || -z "$HF_TOKEN" ]]; then
  echo "ERREUR : PR_URL ou HF_TOKEN non défini"
  exit 1
fi

# Récupérer le diff complet du PR (optionnel si nécessaire)
curl -s -H "Accept: application/vnd.github.v3.diff" "$PR_URL" > diff.txt
DIFF=$(sed 's/"/\\"/g' diff.txt)

# Lancer ESLint pour détecter toutes les variables non utilisées
eslint_output=$(npx eslint . --format json || true)

#  Préparer le prompt pour l'IA
PROMPT=$(cat <<EOF
Tu es un expert Playwright + TypeScript.
Voici la sortie JSON d'ESLint pour les problèmes de code :
$eslint_output

Règles supplémentaires :
1. Toutes les variables déclarées avec const ou let doivent être en camelCase.
2. Liste également toutes les variables, constantes ou fonctions définies mais jamais utilisées.
3. Pour chaque problème détecté, renvoie un objet JSON avec :
   - file : nom du fichier
   - line : numéro de ligne du problème
   - message : description claire et suggestion de correction

Exemple de format attendu :
[
  {"file": "tests/example.spec.ts", "line": 4, "message": "Variable 'User_Name' doit être renommée en camelCase, par exemple 'userName'"},
  {"file": "tests/example.spec.ts", "line": 5, "message": "Variable définie mais jamais utilisée"}
]
EOF
)

# Appel au modèle IA
JSON=$(jq -n --arg prompt "$PROMPT" '{
  model: "meta-llama/Llama-3.1-8B-Instruct",
  messages: [{role: "user", content: $prompt}],
  max_tokens: 1500,
  temperature: 0.2
}')

RESPONSE=$(curl -s -X POST \
  -H "Authorization: Bearer $HF_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$JSON" \
  https://router.huggingface.co/v1/chat/completions)

#  Stocker la réponse brute pour GitHub Actions
echo "AI_REVIEW=$RESPONSE" >> $GITHUB_ENV

#!/bin/bash
set -e

# Vérifie que les variables d'environnement sont définies
if [[ -z "$PR_URL" || -z "$HF_TOKEN" ]]; then
  echo "ERREUR : PR_URL ou HF_TOKEN non défini"
  exit 1
fi

# Récupérer le diff complet du PR
curl -s -H "Accept: application/vnd.github.v3.diff" "$PR_URL" > diff.txt
DIFF=$(sed 's/"/\\"/g' diff.txt)

# Préparer le prompt pour l'IA
PROMPT=$(cat <<EOF
Tu es un expert Playwright + TypeScript.
Analyse le diff suivant et détecte :
1. Variables ou fonctions définies mais jamais utilisées.
2. Toutes les variables const ou let doivent être en camelCase.
3. Autres problèmes de code pertinents.

Renvoie un JSON avec :
[
  {
    "file": "nom du fichier",
    "line": numéro de ligne,
    "message": "texte clair avec suggestion de correction"
  }
]

Diff :
$DIFF
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

# Stocker la réponse brute pour GitHub Actions
echo "AI_REVIEW=$RESPONSE" >> $GITHUB_ENV

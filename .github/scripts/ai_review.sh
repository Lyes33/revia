#!/bin/bash
set -e

# Vérifier que les variables d'environnement sont définies
if [[ -z "$PR_URL" ]]; then
  echo "ERREUR : PR_URL n'est pas défini."
  exit 1
fi
if [[ -z "$HF_TOKEN" ]]; then
  echo "ERREUR : HF_TOKEN n'est pas défini."
  exit 1
fi

# Récupérer le diff de la PR
curl -s -H "Accept: application/vnd.github.v3.diff" "$PR_URL" > diff.txt

# Échapper les guillemets pour JSON
DIFF=$(sed 's/"/\\"/g' diff.txt)

# Construire le prompt
PROMPT=$(cat <<'EOF'
Analyse le diff suivant comme expert Playwright + TypeScript.
Trouve :
- variables non utilisées
- imports inutiles
- code mort
- selectors fragiles
- tests potentiellement flaky
- mauvaises pratiques Playwright

Fournis :
1. Résumé clair
2. Liste des problèmes détectés
3. Suggestions + code corrigé

Diff :
EOF
)
PROMPT="$PROMPT$DIFF"

# Préparer le JSON pour HuggingFace
JSON=$(jq -n --arg prompt "$PROMPT" '{
  model: "deepseek-ai/DeepSeek-Coder-V2-Lite-Instruct",
  messages: [{role: "user", content: $prompt}],
  max_tokens: 800,
  temperature: 0.2
}')

# Appel API HuggingFace
RESPONSE=$(curl -s -X POST \
  -H "Authorization: Bearer $HF_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$JSON" \
  https://router.huggingface.co/v1/chat/completions)

# Stocker la réponse dans une variable d'environnement pour GitHub Actions
echo "AI_REVIEW=$RESPONSE" >> $GITHUB_ENV

#!/bin/bash
set -e

# Récupérer le diff
curl -s -H "Accept: application/vnd.github.v3.diff" "${PR_URL}" > diff.txt
DIFF=$(sed 's/"/\\"/g' diff.txt)

# Préparer le prompt
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

# Préparer le JSON
JSON=$(jq -n --arg prompt "$PROMPT" '{
  model: "deepseek-ai/DeepSeek-Coder-V2-Lite-Instruct",
  messages: [{role: "user", content: $prompt}],
  max_tokens: 800,
  temperature: 0.2
}')

# Appel à l'API HuggingFace
RESPONSE=$(curl -s -X POST \
  -H "Authorization: Bearer $HF_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$JSON" \
  https://router.huggingface.co/v1/chat/completions)

# Stocker la réponse dans une variable d'environnement
echo "AI_REVIEW=$RESPONSE" >> $GITHUB_ENV

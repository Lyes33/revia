#!/bin/bash
set -e

if [[ -z "$PR_URL" ]]; then
  echo "ERREUR : PR_URL n'est pas défini."
  exit 1
fi
if [[ -z "$HF_TOKEN" ]]; then
  echo "ERREUR : HF_TOKEN n'est pas défini."
  exit 1
fi

curl -s -H "Accept: application/vnd.github.v3.diff" "$PR_URL" > diff.txt
DIFF=$(sed 's/"/\\"/g' diff.txt)

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

JSON=$(jq -n --arg prompt "$PROMPT" '{
  model: "meta-llama/Llama-3.1-8B-Instruct",
  messages: [{role: "user", content: $prompt}],
  max_tokens: 800,
  temperature: 0.2
}')

RESPONSE=$(curl -s -X POST \
  -H "Authorization: Bearer $HF_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$JSON" \
  https://router.huggingface.co/v1/chat/completions)

echo "AI_REVIEW=$RESPONSE" >> $GITHUB_ENV

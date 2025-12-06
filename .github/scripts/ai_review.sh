#!/bin/bash
set -e

# Variables d'environnement
if [[ -z "$PR_URL" || -z "$HF_TOKEN" ]]; then
  echo "ERREUR : PR_URL ou HF_TOKEN non défini"
  exit 1
fi

# Récupérer le diff
curl -s -H "Accept: application/vnd.github.v3.diff" "$PR_URL" > diff.txt
DIFF=$(sed 's/"/\\"/g' diff.txt)

# Prompt JSON
PROMPT=$(cat <<EOF
Analyse le diff suivant comme expert Playwright + TypeScript.  
Pour chaque problème détecté, renvoie **toutes** les variables, constantes ou fonctions qui sont définies mais jamais utilisées, ainsi que tout autre problème pertinent.  
Pour chaque problème détecté, renvoie un objet JSON avec :  
- file : nom du fichier  
- line : numéro de ligne du diff où le problème apparaît  
- message : description du problème et suggestion de correction  

Diff :
$DIFF

Le JSON final doit être sous la forme :  
[
  {"file": "<nom du fichier>", "line": <numéro de ligne>, "message": "<texte explicatif>"}
]
EOF
)

JSON=$(jq -n --arg prompt "$PROMPT" '{
  model: "meta-llama/Llama-3.1-8B-Instruct",
  messages: [{role: "user", content: $prompt}],
  max_tokens: 1000,
  temperature: 0.2
}')

RESPONSE=$(curl -s -X POST \
  -H "Authorization: Bearer $HF_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$JSON" \
  https://router.huggingface.co/v1/chat/completions)

# Stocker la réponse brute pour GitHub Actions
echo "AI_REVIEW=$RESPONSE" >> $GITHUB_ENV

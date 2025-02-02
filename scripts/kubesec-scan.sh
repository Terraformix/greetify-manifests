#!/bin/bash

# 🚀 Kubernetes Manifest Security Scanner 🚀

if ! command -v jq &> /dev/null; then
  echo "🔧 jq is not installed. Installing it now..."
  sudo apt update && sudo apt install -y jq

  echo "✅ jq installed successfully!"
else
  echo "✅ jq is already installed!"
fi

# Check for the correct number of arguments
if [ "$#" -lt 1 ]; then
  echo "⚠️ Usage: $0 <ENVIRONMENT>"
  echo "Example: $0 aks or $0 k3s"
  exit 1
fi

ENV=$1

HELM_RELEASE_NAME="greetify"
PASSING_SCORE=3

GREETIFY_BACKEND_DEPLOYMENT="greetify-backend-deployment.yaml"
GREETIFY_DB_STATEFULSET="greetify-db-statefulset.yaml"
GREETIFY_VALIDATOR_DEPLOYMENT="greetify-validator-deployment.yaml"
GREETIFY_FRONTEND_DEPLOYMENT="greetify-frontend-deployment.yaml"

files_to_scan=("$GREETIFY_BACKEND_DEPLOYMENT" "$GREETIFY_DB_STATEFULSET" "$GREETIFY_VALIDATOR_DEPLOYMENT" "$GREETIFY_FRONTEND_DEPLOYMENT")

echo "🌍 Performing Kubesec scan - Static security analysis for Kubernetes manifests in $ENV"
echo "📄 Number of files to scan: ${#files_to_scan[@]}"
echo "**************************************************"

for file in "${files_to_scan[@]}"; do
  echo "🔍 Scanning file: $file"

  scan_result=$(helm template "$HELM_RELEASE_NAME" "../helm/$HELM_RELEASE_NAME/" --show-only "templates/$file" | curl -sSX POST --data-binary @- https://v2.kubesec.io/scan)

  if [[ $? -ne 0 || -z "$scan_result" ]]; then
    echo "❌ Failed to render the Helm manifest or perform the scan for $file."
    exit 1
  fi

  scan_message=$(echo "$scan_result" | jq -r '.[0].message')
  scan_score=$(echo "$scan_result" | jq -r '.[0].score')
  scan_file=$(echo "$scan_result" | jq -r '.[0].object')

  echo "📄 File: $scan_file"
  echo "💬 Message: $scan_message"
  echo "🔢 Score: $scan_score"
  echo "Result: $scan_result"

  if [[ "$scan_score" -ge "$PASSING_SCORE" ]]; then
    echo "✅ Score meets the threshold. Security check passed!"
  else
    echo "❌ Score of $scan_score is below the passing threshold ($PASSING_SCORE)."
    echo "❌ Scanning Kubernetes Resource has Failed."
    exit 1
  fi

  echo "**************************************************"
done

echo "🎉 All files scanned successfully! No issues found."

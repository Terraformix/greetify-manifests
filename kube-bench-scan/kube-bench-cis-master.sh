#!/bin/bash

# Define configuration directory and output file names
CONFIG_DIR="./cfg"
mkdir -p results
JSON_OUTPUT_FILE="./results/kube-bench-results-master-$(date +%Y%m%d).json"
YAML_OUTPUT_FILE="./results/kube-bench-results-master-$(date +%Y%m%d).yaml"

echo "🚀 Running kube-bench security scan for Master Node..."
./kube-bench run --config-dir $CONFIG_DIR --targets master --json > "$JSON_OUTPUT_FILE"

# Extract pass/fail counts from JSON
total_fail=$(jq '.Totals.total_fail' "$JSON_OUTPUT_FILE")
total_pass=$(jq '.Totals.total_pass' "$JSON_OUTPUT_FILE")

# Convert JSON results to YAML using yq (Fixed command)
echo "📄 Converting scan results to YAML..."
cat $JSON_OUTPUT_FILE | yq -P > $YAML_OUTPUT_FILE
cat $YAML_OUTPUT_FILE

rm $JSON_OUTPUT_FILE 

# Print Summary
echo "✅ Scan Completed!"
echo "🔹 Passed: $total_pass"
echo "🔻 Failed: $total_fail"
echo "📂 YAML results saved to: $YAML_OUTPUT_FILE"

# Failure threshold check
if [[ "$total_fail" -gt 9999 ]]; then
  echo "❌ CIS Benchmark Failed for Master Node with score of $total_fail"
  exit 1
else
  echo "✅ CIS Benchmark Passed for Master Node"
fi

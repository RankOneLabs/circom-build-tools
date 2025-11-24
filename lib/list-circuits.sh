#!/bin/bash
# List all available circuits from config
# Usage: ./lib/list-circuits.sh [config_file]

CONFIG_FILE="${1:-circuits.config.json}"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file not found: $CONFIG_FILE"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed."
    exit 1
fi

echo "Available circuits in $CONFIG_FILE:"
echo ""

jq -r '.circuits[] | "  \(.name)
    Display: \(.displayName)
    Description: \(.description)
    Constraints: \(.constraints)
    ptau: \(.ptauSize)
"' "$CONFIG_FILE"

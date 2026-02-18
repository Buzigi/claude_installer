#!/bin/bash
# Embed API key into Linux/macOS installer for CI builds
#
# Usage:
#   ./embed-api-key.sh --api-key "id.secret" --input ./install-claude-code.sh --output ./claude-installer-linux.sh
#
# Environment variables:
#   Z_AI_API_KEY - API key to embed (alternative to --api-key)

set -e

# Parse arguments
API_KEY=""
INPUT_FILE=""
OUTPUT_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --api-key)
            API_KEY="$2"
            shift 2
            ;;
        --input)
            INPUT_FILE="$2"
            shift 2
            ;;
        --output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 --api-key KEY --input FILE --output FILE"
            echo ""
            echo "Options:"
            echo "  --api-key KEY    API key to embed"
            echo "  --input FILE     Input installer script"
            echo "  --output FILE    Output embedded installer"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Validate arguments
if [ -z "$API_KEY" ]; then
    API_KEY="${Z_AI_API_KEY:-}"
fi

if [ -z "$API_KEY" ]; then
    echo "Error: API key required. Use --api-key or set Z_AI_API_KEY"
    exit 1
fi

if [ -z "$INPUT_FILE" ] || [ -z "$OUTPUT_FILE" ]; then
    echo "Error: --input and --output required"
    exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file not found: $INPUT_FILE"
    exit 1
fi

echo "Embedding API key into Linux installer..."

# Read the installer
content=$(cat "$INPUT_FILE")

# Replace the placeholder with actual API key
# The placeholder is: EMBEDDED_API_KEY="__EMBEDDED_API_KEY_PLACEHOLDER__"
embedded=$(echo "$content" | sed "s|EMBEDDED_API_KEY=\"__EMBEDDED_API_KEY_PLACEHOLDER__\"|EMBEDDED_API_KEY=\"$API_KEY\"|g")

# Also set EMBEDDED=true in default
embedded=$(echo "$embedded" | sed 's|EMBEDDED=false|EMBEDDED=true|g')

# Write output
echo "$embedded" > "$OUTPUT_FILE"
chmod +x "$OUTPUT_FILE"

echo "[OK] Embedded installer created: $OUTPUT_FILE"
echo "API key length: ${#API_KEY} characters"

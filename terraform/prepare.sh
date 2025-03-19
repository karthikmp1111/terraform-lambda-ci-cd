#!/bin/bash
set -e  # Exit on error

# Get the directory of this script (Terraform folder)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAMBDA_DIR="$SCRIPT_DIR/../lambda"

# Check if the Lambda directory exists
if [ ! -d "$LAMBDA_DIR" ]; then
    echo "❌ Lambda folder not found in $LAMBDA_DIR!"
    exit 1  # Fail the build
fi

echo "✅ Lambda folder found. Preparing ZIP..."

# Create ZIP only if lambda function exists
if [ -f "$LAMBDA_DIR/lambda_function.py" ]; then
    echo "📦 Creating Lambda ZIP..."
    zip -r "$LAMBDA_DIR/lambda_function.zip" "$LAMBDA_DIR/lambda_function.py"
else
    echo "⚠️ No lambda_function.py found! Skipping ZIP creation."
    exit 1
fi

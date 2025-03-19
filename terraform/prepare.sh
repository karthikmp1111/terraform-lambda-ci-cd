#!/bin/bash
set -e  # Exit on error

LAMBDA_DIR="../lambda"

if [ ! -d "$LAMBDA_DIR" ]; then
    echo "❌ Lambda folder not found!"
    exit 1  # Fail the build
fi

# Create ZIP only if lambda function exists
if [ -f "$LAMBDA_DIR/lambda_function.py" ]; then
    echo "📦 Creating Lambda ZIP..."
    zip -r "$LAMBDA_DIR/lambda_function.zip" "$LAMBDA_DIR/lambda_function.py"
else
    echo "⚠️ No lambda_function.py found! Skipping ZIP creation."
    exit 1
fi

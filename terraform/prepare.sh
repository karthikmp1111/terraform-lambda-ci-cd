#!/bin/bash

LAMBDA_FOLDER="../lambda"

if [ -d "$LAMBDA_FOLDER" ]; then
    echo "📦 Creating ZIP for Lambda function..."
    cd "$LAMBDA_FOLDER" || exit
    zip -qr lambda_function.zip lambda_function.py
    cd - > /dev/null
    echo "✅ Lambda ZIP created successfully!"
else
    echo "❌ Lambda folder not found!"
    exit 1
fi
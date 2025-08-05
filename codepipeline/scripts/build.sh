#!/bin/bash

set -e  # Exit on any error
echo "Starting SAM build process from script..."

cd serverless-app-sam/

sam validate
echo "SAM template validated"

echo "Building SAM application..."
sam build --cached --parallel
echo "SAM build completed successfully"

echo "Build script completed successfully!"
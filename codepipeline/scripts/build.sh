#!/bin/bash

set -e  # Exit on any error
echo "Starting SAM build process from script..."

cd serverless-app-sam/

sam validate
echo "SAM template validated"

echo "Building SAM application..."
sam build
echo "SAM build completed successfully"

echo "Build artifacts created:"
echo "Build script completed successfully!"
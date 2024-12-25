#!/bin/bash

# Determine the host OS
HOST_OS=$(uname)

# Check if HOST_OS is set correctly
if [[ "$HOST_OS" == "Darwin" || "$HOST_OS" == "Linux" ]]; then
    echo "Detected OS: $HOST_OS"
else
    echo "Unsupported OS: $HOST_OS"
    exit 1
fi

# Set ENTRYPOINT_DIR (same for both OS types in this case)
ENTRYPOINT_DIR="/app"

# Start Docker Compose with HOST_OS and ENTRYPOINT_DIR as environment variables
echo "Starting Docker Compose with HOST_OS=${HOST_OS} and ENTRYPOINT_DIR=${ENTRYPOINT_DIR}..."
if ! HOST_OS=${HOST_OS} ENTRYPOINT_DIR=${ENTRYPOINT_DIR} docker compose -f ./docker-compose.yml up --build --force-recreate; then
    echo "Docker Compose failed."
    exit 1 
fi

echo "Docker Compose finished successfully."

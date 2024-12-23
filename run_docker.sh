#!/bin/bash

# Determine the host OS
if [[ "$(uname)" == "Darwin" ]]; then
    export HOST_OS="Darwin"
elif [[ "$(uname)" == "Linux" ]]; then
    export HOST_OS="Linux"
else
    echo "Unsupported OS: $(uname)"
    exit 1
fi

# Run Docker Compose with the HOST_OS argument
echo "Starting Docker Compose with HOST_OS=${HOST_OS}..."
if ! HOST_OS=${HOST_OS} docker compose -f ./docker-compose.yml up --build --force-recreate; then
    echo "Docker Compose failed."
    exit 1
fi

echo "Docker Compose finished successfully."

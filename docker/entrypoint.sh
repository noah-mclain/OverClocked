#!/bin/bash

# Change to the appropriate working directory based on ENTRYPOINT_DIR (set by run_docker.sh)
cd $ENTRYPOINT_DIR || { echo "Failed to change directory to $ENTRYPOINT_DIR"; exit 1; }

# List contents of the docker directory for debugging
echo "Contents of $ENTRYPOINT_DIR/docker:"
ls -l ./docker  

# Execute gui.sh instead of calling entrypoint.sh again
if [[ -f ./scripts/gui.sh ]]; then
    echo "Starting GUI script..."
    exec ./scripts/gui.sh
else
    echo "gui.sh not found!"
    exit 1
fi

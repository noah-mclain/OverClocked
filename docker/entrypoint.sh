#!/bin/bash

# Entry point for the docker container

export NO_AT_BRIDGE=1

start_gui() {
    echo "Starting the GUI..."
    ./scripts/gui.sh
}

echo "Detected OS: $OS_NAME"

# Collect metrics based on the detected OS
if [[ "$OS_NAME" == "Darwin" ]]; then
    echo "Collecting macOS metrics..."
    ./scripts/collect_macos_metrics.sh
elif [[ "$OS_NAME" == "Linux" ]]; then
    echo "Collecting Linux metrics..."
    ./scripts/collect_linux_metrics.sh
else
    echo "Unsupported OS Detected"
    exit 1
fi

# Start the GUI after collecting metrics
start_gui

# Execute any additional commands passed to the script
exec "$@"

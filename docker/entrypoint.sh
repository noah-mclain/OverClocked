#!/bin/bash

# Entry point for the docker container
export NO_AT_BRIDGE=1

start_gui() {
    echo "Starting the GUI..."
    ./scripts/gui.sh
}

echo "Detected OS: $OS_NAME"

# Start the GUI first
start_gui &  # Run the GUI in the background

# Wait for a moment to ensure the GUI is fully up (you may need to adjust this)
sleep 5

# Collect metrics based on the detected OS
if [[ "$OS_NAME" == "Darwin" ]]; then
    echo "Detected macOS environment"
    
    # Check if macos_container is running
    if [ ! "$(docker ps -q -f name=macos_container)" ]; then
        echo "Starting macOS container..."
        docker run -d \
            --name macos_container \
            --device /dev/kvm \
            -p 50922:10022 \
            -v /tmp/.X11-unix:/tmp/.X11-unix \
            -e DISPLAY="${DISPLAY:-host.docker.internal:0}" \
            sickcodes/docker-osx:latest
        
        # Wait for a moment to ensure the container is fully up
        sleep 10
    fi

    echo "Collecting macOS metrics..."
    if ! docker exec macos_container /app/macos/collect_macos_metrics.sh; then
        echo "Failed to collect macOS metrics."
        exit 1
    fi

elif [[ "$OS_NAME" == "Linux" ]]; then
    echo "Collecting Linux metrics..."
    if ! ./linux/collect_linux_metrics.sh; then
        echo "Failed to collect Linux metrics."
        exit 1
    fi

else
    echo "Unsupported OS Detected"
    exit 1
fi

# Wait for the GUI process to finish (if applicable)
wait  # This will wait for the background GUI process to complete

# Execute any additional commands passed to the script
exec "$@"

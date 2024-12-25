#!/bin/bash

if [ "$OS_NAME" == "Darwin" ]; then
    echo "Detected macOS. Executing macOS metrics collection script."
    ./macos/collect_macos_metrics.sh
elif [ "$OS_NAME" == "Linux" ]; then 
    echo "Detected Linux. Executing Linux metrics collection script."
    ./linux/collect_linux_metrics.sh
else
    echo "No valid OS detected. Exiting program..."
    exit 1
fi
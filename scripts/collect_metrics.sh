#!/bin/bash

# Detect OS and call the correct file's metric collection function based on that
# detect_os() {
#     case "$(uname)" in
#         Darwin)
#             echo "macOS"
#             ;;
#         Linux)
#             echo "Linux"
#             ;;
#         *)
#             echo "Unsupported OS"
#             exit 1
#             ;;
#     esac
# }

# # Main <3
# os=$(detect_os)

if [ "$OS_NAME" == "Darwin" ]; then
    echo "Detected macOS. Executing macOS metrics collection script."
    /app/scripts/collect_macos_metrics.sh
elif [ "$OS_NAME" == "Linux" ]; then 
    echo "Detected Linux. Executing Linux metrics collection script."
    /app/scripts/collect_linux_metrics.sh
else
    echo "No valid OS detected. Exiting program..."
    exit 1
fi
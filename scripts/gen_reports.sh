#!/bin/bash

# Function to kill processes using a specific port
kill_processes_on_port() {
    local PORT=$1
    # Find and kill processes using the specified port
    PIDS=$(sudo lsof -t -i tcp:$PORT)
    if [ -n "$PIDS" ]; then
        echo "Killing processes on port $PORT..."
        sudo kill -9 $PIDS
    else
        echo "No processes found on port $PORT."
    fi
}

# Kill any processes on ports 5000 and 5001
kill_processes_on_port 5000
kill_processes_on_port 5001

# Check if an HTML file is provided as an argument
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <path_to_html_file>"
    exit 1
fi

HTML_FILE="$1"
MARKDOWN_REPORT="reports/system_report.md"
HTML_REPORT="system_report.html"

# Check if the provided HTML file exists
if [[ ! -f $HTML_FILE ]]; then
    echo "Error: Input file '$HTML_FILE' not found!"
    exit 1
fi

# Create reports directory if it doesn't exist
mkdir -p reports

# Start the Flask app in the background
python3 report_metrics.py &

# Wait until Flask is running on port 5000 (or change to 5001 if needed)
while ! nc -z localhost 5000; do   
    sleep 0.1  # wait for 0.1 seconds before checking again
done

# Open the report in the default web browser
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    xdg-open http://127.0.0.1:5001/  # For Linux systems
elif [[ "$OSTYPE" == "darwin"* ]]; then
    open http://127.0.0.1:5001/  # For macOS systems
else
    echo "Unsupported OS. Please open your browser and navigate to http://127.0.0.1:5001/"
fi

# Initializes the reports with headers
echo "# System Performance Report" > $MARKDOWN_REPORT
echo "<html><body><h1>System Performance Report</h1>" > $HTML_REPORT

# Generates the report with markdown from the HTML file...
# (rest of your script remains unchanged)

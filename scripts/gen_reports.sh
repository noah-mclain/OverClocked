#!/bin/bash

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
python3 report_metrics.py &  # Adjust path as necessary

# Wait for a moment to ensure Flask is up and running (you might want to use a more robust method)
sleep 5

# Open the report in the default web browser
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    xdg-open http://127.0.0.1:5000/  # For Linux systems
elif [[ "$OSTYPE" == "darwin"* ]]; then
    open http://127.0.0.1:5000/  # For macOS systems
else
    echo "Unsupported OS. Please open your browser and navigate to http://127.0.0.1:5000/"
fi

# Initializes the reports with headers
echo "# System Performance Report" > $MARKDOWN_REPORT
echo "<html><body><h1>System Performance Report</h1>" > $HTML_REPORT

# Generates the report with markdown from the HTML file
generate_markdown_report() {
    echo "## Collected Metrics" >> $MARKDOWN_REPORT
    echo "\`\`\`" >> $MARKDOWN_REPORT
    
    # Convert HTML to Markdown using markdownify (ensure markdownify is installed)
    python3 -c "from markdownify import markdownify as md; print(md(open('$HTML_FILE').read()))" >> $MARKDOWN_REPORT
    
    echo "\`\`\`" >> $MARKDOWN_REPORT
}

# Generates the report with HTML from the HTML file
generate_html_report() {
    echo "<h2>Collected Metric</h2>" >> $HTML_REPORT
    echo "<pre>" >> $HTML_REPORT
    cat "$HTML_FILE" >> $HTML_REPORT  # Read from the provided HTML file
    echo "</pre>" >> $HTML_REPORT
}

# Call the functions after they have been defined.
generate_markdown_report
generate_html_report

echo "</body></html>" >> $HTML_REPORT

# Letting the user know that the reports were generated
echo "Reports generated: "
echo "- Markdown Report: ${MARKDOWN_REPORT}"
echo "- HTML Report: ${HTML_REPORT}"

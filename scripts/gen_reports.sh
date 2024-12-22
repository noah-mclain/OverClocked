#!/bin/bash

MARKDOWN_REPORT="reports/system_report.md"
HTML_REPORT="system_report.html"

# This checks to make sure that the input file exists
if [[ ! -f $INPUT_FILE ]]; then
    echo "Error: Input file '$INPUT_FILE' not found!"
    exit 1
fi

# Initializes the reports with headers
echo "# System Performance Report" > $MARKDOWN_REPORT
echo "<html><body><h1>System Performance Report</h1>" > $HTML_REPORT

# Generates the report with markdown
generate_markdown_report() {
    echo "## Collected Metrics" >> $MARKDOWN_REPORT
    echo "\`\`\`" >> $MARKDOWN_REPORT
    cat $INPUT_FILE >> $MARKDOWN_REPORT
    echo "\`\`\`" >> $MARKDOWN_REPORT
}

# Generates the report with HTML
generate_html_report() {
    echo "<h2>Collected Metric</h2>" >> $HTML_REPORT
    echo "<pre>" >> $HTML_REPORT
    cat $INPUT_FILE >> $HTML_REPORT
    echo "</pre>" >> $HTML_REPORT
}

# Call the functions after they have been defined.
generate_markdown_report
generate_html_report

echo "</body></html>" >> $HTML_REPORT

# Start the Flask app in the background
python3 report_metrics.py &  # Adjust path as necessary

# Wait for a moment to ensure Flask is up and running (you might want to use a more robust method)
sleep 5

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    xdg-open http://127.0.0.1:5000/  # For Linux systems
elif [[ "$OSTYPE" == "darwin"* ]]; then
    open http://127.0.0.1:5000/  # For macOS systems
else
    echo "Unsupported OS. Please open your browser and navigate to http://127.0.0.1:5000/"
fi

# Letting the user know that the Flask app has started
echo "Flask app started. Reports are available at http://127.0.0.1:5000/"

# Letting the user know that the reports were generated
echo "Reports generated: "
echo "- Markdown Report: ${MARKDOWN_REPORT}"
echo "- HTML Report: ${HTML_REPORT}"

#!/bin/bash

INPUT_FILE="system_metrics.txt"
MARKDOWN_REPORT="system_report.md"
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


generate_markdown_report
generate_html_report

echo "</body></html>" >> $HTML_REPORT

# Letting the user know that the reports were generated
echo "Reports generated: "
echo "- Markdown Report: ${MARKDOWN_REPORT}"
echo "- HTML Report: ${HTML_REPORT}"


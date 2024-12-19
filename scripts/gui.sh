#!/bin/bash

INPUT_FILE="system_metrics.txt"
MARKDOWN_REPORT="system_report.md"
HTML_REPORT="systems_report.html"

# Calls to collect the system metrics from the function in collect_metrics.sh
collect_metrics() {
    ./collect_metrics.sh

    if [[ $? -eq 0 ]]; then
        zenity -- info --texts="System metrics collected successfully!"
    else
        zenity --error --text="Error: Failed to collect system metrics"
    fi
}

# Calls the function in gen_reports.sh to generate the reports
generate_reports() {
    # Check if the input file exists
    if [[ ! -f $INPUT_FILE ]]; then
        zenity --error --text="Error: Input file '$INPUT_FILE' not found! Please collect metrics first."
        return
    fi

    ./gen_reports.sh

    zenity --info --text="Reports generated:\n- Markdown Report: ${MARKDOWN_REPORT}\n- HTML Report: ${HTML_REPORT}"

    view_reports_buttons
}

# Display the buttons for opening te reports
view_reports_buttons() {
    RESPONSE=$(zenity --question --text="Do you want to view the reports?" --ok-label="Yoi" --cancel-label="Noi")

    if [[ $? -eq 0 ]]; then
        REPORT_TYPE=$(zenity --list \
                            --title="View Reports" \
                            --column="Select Report" \
                            "View Markdown Report" \
                            "View HTML Report"
                    )

        case $REPORT_TYPE in
            "View Markdown Report")
                zenity --info --text="Opening Markdown report in a text viewer..." 
                xdg-open "$MARKDOWN_REPORT" &  # Open in default text viewer
                ;;
            "View HTML Report")
                zenity --info --text="Opening HTML report in browser..." 
                xdg-open "$HTML_REPORT" &  # Open in default web browser
                ;;
        esac
    fi
}

display_reports() {
    if [[ ! -f $MARKDOWN_REPORT || ! -f $HTML_REPORT ]]; then
        zenity --error --text="Error: Reports not found! Please generate the reports first!"
        return
    fi

    REPORT=$(zenity --list \
                    --title="Select Report" \
                    --column="Reports" \
                    "${MARKDOWN_REPORT}" \
                    "${HTML_REPORT}"
            )

    if [[ $? -eq 0 ]]; then
        zenity --text-info --filename="$REPORT" --title="Report Viewer"
    fi
}

# Main <3
while true; do
    ACTION=$(zenity --list \
                    --title="System Monitoring Took" \
                    --column="Actions" \
                    "Collect Metrics" \
                    "Generate Reports" \
                    "Display Reports" \
                    "Exit"
            )

    case $? in
    0)
        case $ACTION in
            "Collected Metrics")
                collect_metrics ;;
            "Generated Reports")
                generate_reports ;;
            "Display Reports")
                display_reports ;;
            "Exit")
                exit 0 ;;
        esac ;;
    1)
        exit 0 ;;
    255)
        exit 0 ;;
    esac
done

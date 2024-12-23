import os
import platform
import logging
from flask import Flask, render_template, send_file
from database_connection import database_connection
from markdownify import markdownify as md

# Initialize logging
logging.basicConfig(level=logging.INFO)

# Initialize the Flask app with template_folder argument
app = Flask(__name__, template_folder='../app/templates', static_folder='../app/static')

@app.route('/')
def report():
    os_type = platform.system()
    try:
        with database_connection() as connection:
            latest_metrics = connection.retrieve_latest_metrics(os_type)
    except Exception as e:
        logging.error(f"Error retrieving metrics: {e}")
        return render_template('scripts/system_report.html', metrics=None)

    if latest_metrics is None:
        return render_template('scripts/system_report.html', metrics=None)

    return generate_report(os_type, latest_metrics)

def generate_report(os_type, metrics):
    if os_type == "Linux":
        return render_template('templates/linux_system_report.html', metrics=metrics)
    elif os_type == "Darwin":  # macOS
        return render_template('templates/macos_system_report.html', metrics=metrics)
    else:
        return render_template('unsupported_os.html', metrics=None)  # Handle unsupported OS

@app.route('/download_markdown')
def download_markdown():
    os_type = platform.system()
    try:
        with database_connection() as connection:
            latest_metrics = connection.retrieve_latest_metrics(os_type)
    except Exception as e:
        logging.error(f"Error retrieving metrics: {e}")
        return "Error retrieving metrics", 500

    if os_type == "Linux":
        html_content = render_template('linux_system_report.html', metrics=latest_metrics)
    elif os_type == "Darwin":
        html_content = render_template('macos_system_report.html', metrics=latest_metrics)
    else:
        return "Unsupported operating systems", 400

    # Convert HTML to Markdown
    markdown_content = md(html_content)

    # Save the Markdown content to a file
    markdown_file_path = os.path.join('reports', 'system_report.md')
    with open(markdown_file_path, 'w') as f:
        f.write(markdown_content)

    return send_file(markdown_file_path, as_attachment=True)

if __name__ == '__main__':
    logging.info(f"Template folder: {app.template_folder}")
    app.run(debug=True, port=5001)

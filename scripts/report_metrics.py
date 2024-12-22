import platform
from flask import Flask, render_template
from database_connection import database_connection

# Initialize the Flask app with template_folder argument
app = Flask(__name__, template_folder='../templates')

@app.route('/')
def report():
    os_type = platform.system()  # Get the current OS type
    with database_connection() as connection:
        latest_metrics = connection.retrieve_latest_metrics(os_type)
    
    if latest_metrics is None:
        # Handle no data case
        return render_template('system_report.html', metrics=None)

    # Generate the report based on OS type
    return generate_report(os_type, latest_metrics)

def generate_report(os_type, metrics):
    if os_type == "Linux":
        return render_template('linux_system_report.html', metrics=metrics)
    elif os_type == "Darwin":  # macOS
        return render_template('macos_system_report.html', metrics=metrics)

if __name__ == '__main__':
    print(f"Template folder: {app.template_folder}")
    app.run(debug=True)

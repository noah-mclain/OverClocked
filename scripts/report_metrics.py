import platform
from flask import Flask, render_template
from database_connection import database_connection

# Initialize the Flask app with template_folder argument
app = Flask(__name__, template_folder='../templates', static_folder='../static')

@app.route('/')
def report():
    os_type = platform.system()
    try:
        with database_connection() as connection:
            latest_metrics = connection.retrieve_latest_metrics(os_type)
    except Exception as e:
        print(f"Error retrieving metrics: {e}")
        return render_template('system_report.html', metrics=None)

    if latest_metrics is None:
        return render_template('system_report.html', metrics=None)

    return generate_report(os_type, latest_metrics)


def generate_report(os_type, metrics):
    if os_type == "Linux":
        return render_template('linux_system_report.html', metrics=metrics)
    elif os_type == "Darwin":  #macOS
        return render_template('macos_system_report.html', metrics=metrics)

if __name__ == '__main__':
    print(f"Template folder: {app.template_folder}")
    app.run(debug=True)

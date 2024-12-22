import platform
from flask import Flask, render_template
from database_connection import database_connection

app = Flask(__name__)

@app.route('/')
def report():
    os_type = platform.system()  # Get the current OS type
    with database_connection() as connection:
        latest_metrics = connection.retrieve_latest_metrics(os_type)
    
    if latest_metrics is None:
        return render_template('../templates/system_report.html', metrics=None)  # Handle no data case

    return render_template('../templates/system_report.html', metrics=latest_metrics)

if __name__ == '__main__':
    app.run(debug=True)

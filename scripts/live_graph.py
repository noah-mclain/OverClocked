import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from matplotlib.animation import FuncAnimation
from database_connection import database_connection


def plot_cpu_utilization(data, os_type):
    if os_type == "Darwin":
        timestamps = [entry['timestamp'] for entry in data]
        cpu_utilizations = [float(entry['average_cpu_utilization']) for entry in data]
    elif os_type == "Linux":
        timestamps = [entry['timestamp'] for entry in data]
        cpu_utilizations = [float(entry['cpu_utilization']) for entry in data]
    else:
        raise ValueError("Unsupported operating system")

    fig, ax = plt.subplots()
    ax.set_title('CPU Utilization Over Time')
    ax.set_xlabel('Timestamp')
    ax.set_ylabel('CPU Utilization (%)')
    ax.grid(True)
    
    line, = ax.plot(timestamps, cpu_utilizations, marker='o')

    def update(frame):
        # Fetch the latest data from the database
        with database_connection() as connection:
            results = connection.retrieve_metrics(os_type, 1)
            if os_type == "Darwin":
                timestamps = [entry['timestamp'] for entry in results]
                cpu_utilizations = [float(entry['average_cpu_utilization']) for entry in results]
            elif os_type == "Linux":
                timestamps = [entry['timestamp'] for entry in results]
                cpu_utilizations = [float(entry['cpu_utilization']) for entry in results]

            line.set_data(timestamps, cpu_utilizations)
            ax.relim()
            ax.autoscale_view()

    ani = FuncAnimation(fig, update, interval=5000)  # Update every 5 seconds
    plt.tight_layout()
    plt.show()


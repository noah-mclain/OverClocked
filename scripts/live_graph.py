import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from matplotlib.animation import FuncAnimation
from database_connection import database_connection


def plot_cpu_utilization(data):
    timestamps = [entry['timestamp'] for entry in data]
    cpu_utilizations = [float(entry['cpu_utilization']) for entry in data]

    fig, ax = plt.subplots()
    ax.set_title('CPU Utilization Over Time')
    ax.set_xlabel('Timestamp')
    ax.set_ylabel('CPU Utilization (%)')
    ax.grid(True)
    
    line, = ax.plot(timestamps, cpu_utilizations, marker='o')

    def update(frame):
        # Fetch the latest data from the database
        connection = database_connection()
        results = connection.retrieve_metrics(1)
        timestamps = [entry['timestamp'] for entry in results]
        cpu_utilizations = [float(entry['cpu_utilization']) for entry in results]
        line.set_data(timestamps, cpu_utilizations)
        ax.relim()
        ax.autoscale_view()

    ani = FuncAnimation(fig, update, interval=5000)  # Update every 10 seconds
    plt.tight_layout()
    plt.show()


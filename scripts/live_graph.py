import pandas as pd
from datetime import datetime
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from matplotlib.animation import FuncAnimation
from database_connection import database_connection


def plot_cpu_utilization(data, os_type):
    if os_type == "Darwin":
        timestamps = [pd.to_datetime(entry['timestamp']) for entry in data]
        cpu_utilizations = [float(entry['average_cpu_utilization'].rstrip('%')) for entry in data]
    elif os_type == "Linux":
        timestamps = [pd.to_datetime(entry['timestamp']) for entry in data]
        cpu_utilizations = [float(entry['cpu_utilization'].rstrip('%')) for entry in data]
    else:
        raise ValueError("Unsupported operating system")

    timestamps = [pd.to_datetime(ts) for ts in timestamps]
    
    fig, ax = plt.subplots()
    ax.set_title('CPU Utilization Over Time')
    ax.set_xlabel('Time')
    ax.set_ylabel('CPU Utilization (%)')
    ax.grid(True)

    line, = ax.plot(timestamps, cpu_utilizations, marker='o')

    # Format x-axis to show seconds only
    ax.xaxis.set_major_formatter(mdates.DateFormatter('%M%S'))
    fig.autofmt_xdate()  # Auto-rotate labels if necessary

    def update(frame):
        with database_connection() as connection:
            results = connection.retrieve_metrics(os_type, limit=5)
            if os_type == "Darwin":
                timestamps = [pd.to_datetime(entry['timestamp']) for entry in results]
                cpu_utilizations = [float(entry['average_cpu_utilization'].rstrip('%')) for entry in results]
            elif os_type == "Linux":
                timestamps = [pd.to_datetime(entry['timestamp']) for entry in results]
                cpu_utilizations = [float(entry['cpu_utilization'].rstrip('%')) for entry in results]

                line.set_data(timestamps, cpu_utilizations)
                ax.relim()
                ax.autoscale_view()
    ani = FuncAnimation(fig, update, interval=5000)  # Update every 5 seconds
    plt.tight_layout()
    plt.show()

def plot_ram_utilization(data, os_type):
    if os_type == "Darwin":
        timestamps = [pd.to_datetime(entry['timestamp']) for entry in data]
        ram_utilizations = [float(entry['utilized_ram'].rstrip('%')) for entry in data]
    elif os_type == "Linux":
        timestamps = [pd.to_datetime(entry['timestamp']) for entry in data]
        ram_utilizations = [float(entry['utilized_ram'].rstrip('%')) for entry in data]
    else:
        raise ValueError("Unsupported operating system")

    fig, ax = plt.subplots()
    ax.set_title('RAM Utilization Over Time')
    ax.set_xlabel('Time')
    ax.set_ylabel('RAM Utilization (%)')
    ax.grid(True)

    line, = ax.plot(timestamps, ram_utilizations, marker='o')

    # Format x-axis to show seconds only
    ax.xaxis.set_major_formatter(mdates.DateFormatter('%M%S'))
    fig.autofmt_xdate()  # Auto-rotate labels if necessary

    def update(frame):
        with database_connection() as connection:
            results = connection.retrieve_metrics(os_type, limit=5)
            if os_type == "Darwin":
                timestamps = [pd.to_datetime(entry['timestamp']) for entry in results]
                ram_utilizations = [float(entry['utilized_ram'].rstrip('%')) for entry in results]
            elif os_type == "Linux":
                timestamps = [pd.to_datetime(entry['timestamp']) for entry in results]
                ram_utilizations = [float(entry['utilized_ram'].rstrip('%')) for entry in results]

                line.set_data(timestamps, ram_utilizations)
                ax.relim()
                ax.autoscale_view()

    ani = FuncAnimation(fig, update, interval=5000)  # Update every 5 seconds
    plt.tight_layout()
    plt.show()

def plot_network_utilization(data, os_type):
    if os_type == "Darwin":
        timestamps = [pd.to_datetime(entry['timestamp']) for entry in data]
        sent_data = [float(entry['sent'].rstrip('%')) for entry in data]
        received_data = [float(entry['received'].rstrip('%')) for entry in data]
    elif os_type == "Linux":
        timestamps = [pd.to_datetime(entry['timestamp']) for entry in data]
        sent_data = [float(entry['sent'].rstrip('%')) for entry in data]
        received_data = [float(entry['received'].rstrip('%')) for entry in data]
    else:
        raise ValueError("Unsupported operating system")

    fig, ax = plt.subplots()
    ax.set_title('Network Utilization Over Time')
    ax.set_xlabel('Time')
    ax.set_ylabel('Utilization (kb/s)')
    ax.grid(True)

    ax.plot(timestamps, sent_data, marker='o', color='blue', label='Sent')
    ax.plot(timestamps, received_data, marker='o', color='orange', label='Received')

    # Format x-axis to show seconds only
    ax.xaxis.set_major_formatter(mdates.DateFormatter('%M%S'))
    fig.autofmt_xdate()  # Auto-rotate labels if necessary

    ax.legend()  # Show legend

    def update(frame):
        with database_connection() as connection:
            results = connection.retrieve_metrics(os_type,limit=5)
            if os_type == "Darwin":
                timestamps = [pd.to_datetime(entry['timestamp']) for entry in results]
                sent_data = [float(entry['sent'].rstrip('%')) for entry in results]
                received_data = [float(entry['received'].rstrip('%')) for entry in results]
            elif os_type == "Linux":
                timestamps = [pd.to_datetime(entry['timestamp']) for entry in results]
                sent_data = [float(entry['sent'].rstrip('%')) for entry in results]
                received_data = [float(entry['received'].rstrip('%')) for entry in results]

                ax.clear()
                ax.plot(timestamps, sent_data, marker='o', color='blue', label='Sent')
                ax.plot(timestamps, received_data, marker='o', color='orange', label='Received')
                ax.xaxis.set_major_formatter(mdates.DateFormatter('%M%S'))
                fig.autofmt_xdate()  # Auto-rotate labels if necessary
                ax.legend()  # Show legend again

    ani = FuncAnimation(fig, update, interval=5000)  # Update every 5 seconds
    plt.tight_layout()
    plt.show()


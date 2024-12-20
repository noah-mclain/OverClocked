import subprocess
from database_connection import database_connection
import re
import os
import csv
import time
from live_graph import plot_cpu_utilization


def run_script():
    #path = os.path.join("collect_linux_metrics.sh")
    try:
        result = subprocess.run(["bash", "./collect_linux_metrics.sh"],
                                capture_output = True,
                                text = True)
        if result.returncode != 0:
            raise RuntimeError("Bash script error")
        #print(result.stdout)
        return result.stdout
    except:
        raise FileNotFoundError("File not found")
    
def parse_metrics(data):
    metrics = {
        'cpu_utilization': None,
        'cpu_temperature': None,
        'total_ram': None,
        'free_ram': None,
        'utilized_ram': None,
        'total_disk_space': None,
        'used_disk_space': None,
        'available_disk_space': None,
        #'gpu_utilization': None,
        #'gpu_temperature': None,
        'ipv4_address': None,
        'ipv6_address': None,
        'sent': None,
        'received': None,
        'startup_time' : None,
        'average_process_waiting_time' : None
    }

    lines = data.splitlines()
    for line in lines:
        if ':' not in line:
            continue
        key, value = map(str.strip, line.split(':', 1))
        key = key.lower().replace(' ', '_').replace('(', '').replace(')', '')
        if key in metrics:
            if key == 'ipv6_address':
                match = re.search(r'[0-9a-fA-F:]+', value)
            # Extract the value using regex to handle units
            else:
                match = re.search(r'([\d.]+(?:Gi|%|°C)?)', value)
            if match:
                metrics[key] = match.group(0)

    return metrics


if __name__=="__main__":
    while True:
        data = run_script()
        metrics = parse_metrics(data)
        connection = database_connection()
        connection.create_table()
        connection.store_metrics(metrics)
        results = connection.retrieve_metrics(1)
        plot_cpu_utilization(results)
        time.sleep(5)
        #print(results)


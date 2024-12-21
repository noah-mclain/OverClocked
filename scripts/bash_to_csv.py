import subprocess
from database_connection import database_connection
import re
import os
import csv
import time
import platform
from live_graph import plot_cpu_utilization


def run_script(os_type):
    #path = os.path.join("collect_linux_metrics.sh")
    try:
        print("Entered try-catch!")
        if os_type == "Linux":
            result = subprocess.run(["bash", "./collect_linux_metrics.sh"],
                                    capture_output=True,
                                    text=True)
        elif os_type == "Darwin":
            result = subprocess.run(["bash", "./collect_macos_metrics.sh"],
                                    capture_output=True,
                                    text=True)

        if result.returncode != 0:
            raise RuntimeError("Bash script error")
        #print(result.stdout)
        return result.stdout
    except FileNotFoundError:
        raise FileNotFoundError("File not found")
    except Exception as e:
        raise RuntimeError(f"An error occurred: {e}")
    
def parse_load_average(line):
    match = re.search(r'Average Load:\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)', line)
    if match:
        return {
            '1_min': match.group(1),
            '5_min': match.group(2),
            '15_min': match.group(3),
        }
    return None
    
def parse_metrics(data, os_type):
    linux_metrics = {
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
    
    macos_metrics = {
        'total_ram': None,
        'used_ram': None,
        'free_ram': None,
        'average_cpu_utilization': None,
        'gpu_active_frequency': None,
        'gpu_active_residency': None,
        'gpu_power_consumption': None,
        'disk_usage': None,
        'temperature': None,
        'percentage_used': None,
        'ping': None,
        'download': None,
        'upload': None,
        'five_min': None,
    }
    
    metrics = linux_metrics if os_type == "Linux" else macos_metrics

    lines = data.splitlines()
    for line in lines:
        print(f"Processing line: {line}")
        if ':' not in line:
            continue
        key, value = map(str.strip, line.split(':', 1))
        key = key.lower().replace(' ', '_').replace('(', '').replace(')', '')
        if key in metrics:
            match = re.search(r'([\d.]+(?:Gi|%|°C)?)', value) if key != 'ipv6_address' else re.search(r'[0-9a-fA-F:]+', value)
            if match:
                metrics[key] = match.group(0)
                
    for key in metrics.keys():
        if metrics[key] is None:
            print(f"Warning: {key} is missing from the collected data.")

        # if key in metrics:
        #     if key == 'ipv6_address':
        #         match = re.search(r'[0-9a-fA-F:]+', value)
        #     # Extract the value using regex to handle units
        #     else:
        #         match = re.search(r'([\d.]+(?:Gi|%|°C)?)', value)
        #     if match:
        #         metrics[key] = match.group(0)

    return metrics

if __name__=="__main__":
    os_type = platform.system()
    print(os_type)
    try:
        while True:
            print("Entered loop!")
            data = run_script(os_type)
            print("Running!")
            metrics = parse_metrics(data, os_type)
            print(metrics)
            
            with database_connection() as connection:            
                if os_type == "Darwin":
                    connection.create_mac_table()
                    print("Created")
                    connection.store_mac_metrics(metrics)
                    print("Stored")
                    results = connection.retrieve_metrics(1)
                    print("Retrieved")
                elif os_type == "Linux":
                    connection.create_linux_table()
                    connection.store_linux_metrics(metrics)
                    results = connection.retrieve_metrics(1)
                
            # plot_cpu_utilization(results)
            time.sleep(5)
            #print(results)
    except KeyboardInterrupt:
        print("Process interrupted by user")
    except Exception as e:
        print(f"An error occurred: {e}")

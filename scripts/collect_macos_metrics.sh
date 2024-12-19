#!/bin/bash

# Initialize health variables
cpu_temp="N/A"
gpu_temp="N/A"
network_health="N/A"
memory_health="N/A"
cpu_health="N/A"
disk_health="N/A"

collect_memory() {
    echo "Collecting memory usage on macOS..."

    total_memory=$(sysctl -n hw.memsize)

    page_size=$(vm_stat | grep "Page size" | awk '{print $3}' | tr -d '.')

    if [ -z "$page_size" ]; then
        page_size=16384  # Set a default value (common page size for macOS)
    fi

    free_memory=$(vm_stat | grep "Pages free" | awk '{print $3}' | tr -d '.')
    inactive_memory=$(vm_stat | grep "Pages inactive" | awk '{print $3}' | tr -d '.')
    active_memory=$(vm_stat | grep "Pages active" | awk '{print $3}' | tr -d '.')

    # Debugging output for raw values
    echo "Raw Values - Free Pages: $free_memory, Inactive Pages: $inactive_memory, Active Pages: $active_memory"
    
    # Convert pages to MB
    free_memory_mb=$((free_memory * page_size / 1024 / 1024))
    inactive_memory_mb=$((inactive_memory * page_size / 1024 / 1024))
    active_memory_mb=$((active_memory * page_size / 1024 / 1024))
    
    total_memory_mb=$((total_memory / 1024 / 1024))

    used_memory_mb=$((active_memory_mb + inactive_memory_mb))

    echo "Total RAM: ${total_memory_mb} MB"
    echo "Used RAM: ${used_memory_mb} MB"
    echo "Free RAM: ${free_memory_mb} MB"

    if (( total_memory_mb > 0 )); then
        used_percentage=$((100 * used_memory_mb / total_memory_mb))
    else
        used_percentage=0
    fi

    # Memory Health Check
    if (( used_percentage > 90 )); then
        memory_health="Critical"
    elif (( used_percentage > 70 )); then
        memory_health="Warning"
    else
        memory_health="Good"
    fi

    echo "Memory Health: ${memory_health}"
    
    # Output for debugging purposes
    echo "Page Size: ${page_size} bytes"
}

collect_cpu() {
    echo "Collecting CPU utilization on macOS..."
    
    cpu_usage_sum=0
    readings=5
    
    for i in $(seq 1 $readings); do
        cpu_usage=$(top -l 1 | grep "CPU usage" | awk '{print $3}' | tr -d '%')
        cpu_usage_sum=$(echo "$cpu_usage_sum + $cpu_usage" | bc)
        sleep 1 
    done
    
    avg_cpu_usage=$(echo "scale=2; $cpu_usage_sum / $readings" | bc)
    echo "Average CPU Utilization: ${avg_cpu_usage}%"

    if (( $(echo "$avg_cpu_usage < 70" | bc -l) )); then
        cpu_health="Good"
    elif (( $(echo "$avg_cpu_usage < 90" | bc -l) )); then
        cpu_health="Warning"
    else
        cpu_health="Critical"
    fi

    echo "CPU Health Status: ${cpu_health}"
    echo
}

collect_cpu_details() {
    echo "Retrieving CPU details..."
    
    cpu_brand=$(sysctl -n machdep.cpu.brand_string)
    cpu_cores=$(sysctl -n hw.ncpu)
    cpu_logical_cores=$(sysctl -n hw.logicalcpu)

    echo "CPU Brand: ${cpu_brand}"
    echo "Number of Cores: ${cpu_cores}"
    echo "Logical Cores: ${cpu_logical_cores}"

   echo "Current CPU Power for each core:"
   sudo powermetrics -s cpu_power -n 1 | grep 'CPU Power' || echo "Could not retrieve CPU power."

   echo "Attempting to retrieve current CPU frequency..."
   sudo powermetrics -s cpu_power -n 1 | grep 'E-Cluster HW active frequency' || echo "Could not retrieve CPU frequency."
}

# Function to collect GPU metrics
collect_gpu() {
    echo "Collecting GPU utilization on macOS..."
    
    gpu_info=$(system_profiler SPDisplaysDataType)
    
    if [[ "$gpu_info" == *"Apple"* ]]; then
        gpu_usage=$(powermetrics -gpu | grep "GPU" | awk '{print $3}' | sed 's/%//')
        gpu_temp=$(powermetrics -thermal | grep "GPU die temperature" | awk '{print $5}' | sed 's/°C//')

        # GPU Health Check for Apple GPU
        if (( gpu_usage > 80 || gpu_temp > 85 )); then
            gpu_health="Critical"
        elif (( gpu_usage > 60 || gpu_temp > 75 )); then
            gpu_health="Warning"
        else
            gpu_health="Good"
        fi
        
        echo "Detected Apple GPU."
        
    elif [[ "$gpu_info" == *"NVIDIA"* ]]; then
        gpu_usage=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader)
        gpu_temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader)

        # Check NVIDIA health based on usage and temperature 
        if [[ "$gpu_usage" -gt 80 || "$gpu_temp" -gt 85 ]]; then
            gpu_health="Critical"
        elif [[ "$gpu_usage" -gt 60 || "$gpu_temp" -gt 75 ]]; then
            gpu_health="Warning"
        else
            gpu_health="Good"
        fi
        
        echo "Detected NVIDIA GPU."
        
    elif [[ "$gpu_info" == *"AMD"* ]]; then
        gpu_usage="N/A"
        gpu_temp="N/A"
        gpu_health="Good" # Placeholder
        
        echo "Detected AMD GPU."
        
    else
        echo "No supported GPU detected."
        return
    fi

    echo "GPU Utilization: ${gpu_usage}%"
    echo "GPU Temperature: ${gpu_temp}°C"
    echo "GPU Health: ${gpu_health}"
}

# Function to collect disk metrics and SMART status
collect_disk() {
    echo "Collecting disk usage and SMART status on macOS..."
    
    disk_usage=$(df -h / | tail -1 | awk '{print $5}' | tr -d '%')
    
    smart_status=$(diskutil info disk0 | grep "SMART Status" | awk '{print $3}')
    
    echo "Disk Usage: ${disk_usage}%"
    echo "SMART Status: ${smart_status}"

    # Updated Disk Health Logic
    if [[ "$smart_status" == "Verified" && "$disk_usage" -lt 90 ]]; then
        disk_health="Good"
    elif [[ "$smart_status" != "Verified" ]]; then
        disk_health="Critical"
    elif [[ "$disk_usage" -ge 90 ]]; then
        disk_health="Warning"
    else
        disk_health="Good"
    fi

    echo "Disk Health: ${disk_health}"
}

# # Function to check network health and statistics with multiple pings for accuracy.
# check_network() {
#     echo "Collecting network interface statistics on macOS..."

# 	# Get network statistics using netstat and check interface status using ifconfig.
# 	net_stats=$(netstat -i)
# 	echo "$net_stats"

# 	echo "Checking network interface statuses..."
# 	ifconfig_output=$(ifconfig)
# 	echo "$ifconfig_output"

# 	# Check for packet loss by pinging a known reliable address multiple times.
# 	echo "Pinging Google DNS to check connectivity..."
# 	ping_count=10 # Number of pings to send.
# 	ping_output=$(ping -c $ping_count 8.8.8.8) 
	
# 	# Extract packet loss percentage using regex with grep.
# 	packet_loss=$(echo "$ping_output" | grep -oP '\d+(?=% packet loss)' || echo '100') # Default to '100' if no output.

# 	# Calculate average latency from ping results.
# 	latency_avg=$(echo "$ping_output" | grep 'rtt' | awk -F'/' '{print $2}') 

# 	if [ "$packet_loss" -eq 0 ]; then
# 		network_health="Good (Avg Latency: ${latency_avg} ms)"
# 	else
# 		network_health="Poor - ${packet_loss}% packet loss (Avg Latency: ${latency_avg} ms)"
# 	fi

# 	echo "Network Health: ${network_health}"
# }

# # Function to collect system load metrics with adjustable thresholds based on CPU cores.
# collect_load() {
# 	echo "Collecting system load metrics on macOS..."
	
# 	load_average=$(uptime | awk -F'load averages:' '{ print $2 }' | cut -d',' -f1)
# 	num_cores=$(sysctl -n hw.physicalcpu)

# 	echo "System Load Average: ${load_average}"

# 	# Health Check for Load Average based on number of CPU cores.
# 	if (( $(echo "$load_average > $num_cores * 2" | bc -l) )); then 
# 		load_health="Critical"
# 	elif (( $(echo "$load_average > $num_cores * 1.5" | bc -l) )); then 
# 		load_health="Warning"
# 	else 
# 		load_health="Good"
# 	fi

# 	echo "Load Health: ${load_health}"
# }

# Main <3
collect_metrics() {
	# collect_memory || { echo "Memory collection failed."; exit 1; }
	# collect_cpu || { echo "CPU collection failed."; exit 1; }
	# collect_cpu_details || { echo "CPU details collection failed."; exit 1; }

	collect_gpu || { echo "GPU collection failed."; exit 1; }
	collect_disk || { echo "Disk collection failed."; exit 1; }
	# check_network || { echo "Network check failed."; exit 1; }
	# collect_load || { echo "Load collection failed."; exit 1; }
}

# Run the metrics collection
collect_metrics


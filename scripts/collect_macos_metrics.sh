#!/bin/bash

# Initialize health variables
memory_health="N/A"
cpu_temp="N/A"
cpu_health="N/A"
gpu_power="N/A"
pressure_reading="N/A"
gpu_health="Unknown"
gpu_frequency="N/A"
gpu_residency="N/A"
disk_health="N/A"
network_health="N/A"

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

collect_gpu() {
    echo "=============================="
    echo "   Collecting GPU Metrics     "
    echo "=============================="
    
    # Run powermetrics command to collect GPU data
    gpu_metrics=$(sudo powermetrics --samplers gpu_power --show-process-gpu -n 1 -i 1000)

    # Print raw metrics for debugging (optional)
    # echo "Raw GPU Metrics:"
    # echo "$gpu_metrics" | sed 's/^/    /'  # Indent raw metrics for better visibility

    # Initialize variables
    gpu_frequency="N/A"
    gpu_residency="N/A"
    gpu_power="N/A"
    gpu_health="Unknown"

    # Parse metrics from output
    echo "=============================="
    echo "         Parsed Metrics       "
    echo "=============================="

    # Extract relevant data using grep and awk
    while IFS= read -r line; do
        if [[ $line == *"GPU HW active frequency:"* ]]; then
            gpu_frequency=$(echo "$line" | awk '{print $5}')
            echo "GPU Active Frequency: $gpu_frequency MHz"
        elif [[ $line == *"GPU HW active residency:"* ]]; then
            gpu_residency=$(echo "$line" | awk '{print $5}' | sed 's/%//')  # Remove % sign for numeric comparison
            echo "GPU Active Residency: $gpu_residency%"
        elif [[ $line == *"GPU Power:"* ]]; then
            gpu_power=$(echo "$line" | awk '{print $3}')
            echo "GPU Power Consumption: $gpu_power mW"
        fi
    done <<< "$gpu_metrics"

    # Calculate GPU load based on residency
    gpu_load="$gpu_residency"  # Use residency as a proxy for load

    # Check if GPU power was found and determine health based on residency and power
    if [[ "$gpu_power" == "0" || "$gpu_power" == "N/A" ]]; then
        gpu_health="Idle (No activity detected)"
        gpu_residency="0.00"
        gpu_load="0.00"
    else
        if [[ "$gpu_residency" == "N/A" || "$gpu_residency" == "0.00" ]]; then
            gpu_health="Unknown (No activity)"
        elif (( $(echo "$gpu_residency > 80" | bc -l) )); then
            gpu_health="Critical"
        elif (( $(echo "$gpu_residency > 60" | bc -l) )); then
            gpu_health="Warning"
        else
            gpu_health="Good"
        fi
    fi
    #  Final formatted output for health status
    echo "=============================="
    echo "         GPU Health           "
    echo "=============================="
    echo "GPU Health: ${gpu_health:-Unknown}"
    
    # Output the load reading as pressure reading if available
    echo "GPU Load (Pressure): ${gpu_load:-N/A}%"

    echo "=============================="
}

collect_disk() {
    echo "Collecting disk usage and SMART status on macOS..."
    
    # Get disk usage percentage
    disk_usage=$(df -h / | tail -1 | awk '{print $5}' | tr -d '%')
    
    # Get SMART status
    smart_status=$(diskutil info disk0 | grep "SMART Status" | awk '{print $3}')
    
    # Initialize variables for additional SMART attributes
    smart_attributes=""

    # Try to get additional SMART attributes using smartctl
    if command -v smartctl &> /dev/null; then
        smart_attributes=$(sudo smartctl -A /dev/disk0 2>/dev/null)
    else
        echo "smartctl command not found. Please install smartmontools."
        return 1
    fi

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

    # Display all SMART attributes for debugging purposes
    echo "All SMART Attributes:"
    echo "$smart_attributes"

    echo "Disk Health: ${disk_health}"
}

check_network() {
    echo "Collecting network interface statistics on macOS..."

    # Collect network statistics
    echo "Network Statistics:"
    netstat -i | awk 'NR > 1 && $1 != "lo0" && $1 !~ /^utun/ {
        errors[$1] = ($5 > 0 || $6 > 0) ? "Packet Errors Detected" : "No Packet Errors"
    }
    END {
        for (iface in errors) {
            print iface ": " errors[iface]
        }
    }'
    echo

    # Check network interface statuses
    echo "Checking network interface statuses..."
    ifconfig_output=$(ifconfig) # Capture the output of ifconfig
    active_interfaces=$(echo "$ifconfig_output" | awk '/^[a-z]/ {iface=$1} /status: active/ {print iface}')

    # Check if any active interfaces were found
    if [[ -z "$active_interfaces" ]]; then
        echo "No active interfaces found."
        echo "Available interfaces:"
        echo "$ifconfig_output" | awk '/^[a-z]/ {print $1}'
    else
        echo "Active Interfaces:"
        echo "$active_interfaces"
    fi

    # Summary of network interfaces
    echo "Network Interfaces Summary:"
    error_free_interfaces=$(netstat -i | awk 'NR > 1 && $1 != "lo0" && $1 !~ /^utun/ && $5 == 0 && $6 == 0 {print $1}' | xargs)
    interfaces_with_errors=$(netstat -i | awk 'NR > 1 && $1 != "lo0" && $1 !~ /^utun/ && ($5 > 0 || $6 > 0) {print $1}' | xargs)

    echo "Error-Free Interfaces: ${error_free_interfaces:-None}"
    echo "Interfaces with Errors: ${interfaces_with_errors:-None}"

    # Check for speed test availability
    if command -v speedtest-cli &>/dev/null; then
        echo "Running speed test..."
        speedtest_output=$(speedtest-cli --simple 2>/dev/null)
        echo "$speedtest_output"
    else
        echo "speedtest-cli is not installed. You can install it with Homebrew:"
        echo "  brew install speedtest-cli"
    fi
    echo

    # Check packet loss and latency
    echo "Pinging Google DNS to check connectivity..."
    ping_count=10
    ping_output=$(ping -c $ping_count 8.8.8.8 2>&1)

    if [[ $? -ne 0 ]]; then
        echo "Ping command failed. Check your network connection."
        return 1
    fi

    # Extract packet loss and latency stats safely
    packet_loss=$(echo "$ping_output" | awk '/packet loss/{print $(NF-1)}' | tr -d '%')
    latency_avg=$(echo "$ping_output" | awk -F'/' '/round-trip/{print $(NF-2)}')

    # Determine network health
    if [[ "$packet_loss" == "" ]]; then
        network_health="Unknown (Ping failed)"
    elif [[ "$packet_loss" -eq 0 ]]; then
        network_health="Good (Avg Latency: ${latency_avg:-N/A} ms)"
    else
        network_health="Poor - ${packet_loss:-N/A}% packet loss (Avg Latency: ${latency_avg:-N/A} ms)"
    fi
    echo "Network Health: $network_health"
    echo

    # Optional traceroute
    echo "Running traceroute..."
    traceroute_output=$(traceroute -m 15 8.8.8.8)
    if [[ $? -ne 0 ]]; then
        echo "Traceroute command failed."
    else 
        if [[ -z "$traceroute_output" ]]; then 
            echo "Traceroute produced no output."
        else 
            echo "$traceroute_output"
        fi 
    fi 
}

collect_load() {
    echo "Collecting system load metrics on macOS..."

    # Get the load averages using uptime
    load_avg=$(uptime | awk -F'load averages:' '{ print $2 }' | tr -d ',')

    # Debugging output to see raw load average
    echo "Raw Load Avg Output: $load_avg"

    # Extract the individual load averages
    one_min=$(echo "$load_avg" | awk '{print $1}')
    five_min=$(echo "$load_avg" | awk '{print $2}')
    fifteen_min=$(echo "$load_avg" | awk '{print $3}')

    # Check if the values are empty or malformed
    if [[ -z "$one_min" || -z "$five_min" || -z "$fifteen_min" ]]; then
        echo "Error: Unable to parse load averages properly."
        return 1
    fi

    # Format the output for clarity
    echo "System Load Average: 1 Min: $one_min, 5 Min: $five_min, 15 Min: $fifteen_min"

    # Get the number of physical CPU cores
    num_cores=$(sysctl -n hw.physicalcpu)

    # Debugging output to verify number of cores
    echo "Number of CPU cores: $num_cores"

    # Analyze the load averages for health check
    load_health="Good"
    if (( $(echo "$one_min > $num_cores" | bc -l) )); then
        load_health="Warning"
    fi
    if (( $(echo "$five_min > $num_cores" | bc -l) )); then
        load_health="Critical"
    fi

    echo "Load Health: $load_health"
}

# Main <3
collect_metrics() {
	collect_memory || { echo "Memory collection failed."; exit 1; }
	collect_cpu || { echo "CPU collection failed."; exit 1; }
	collect_cpu_details || { echo "CPU details collection failed."; exit 1; }
	collect_gpu || { echo "GPU collection failed."; exit 1; }
	collect_disk || { echo "Disk collection failed."; exit 1; }
	check_network || { echo "Network check failed."; exit 1; }
	collect_load || { echo "Load collection failed."; exit 1; }
}

# Run the metrics collection
running=True
while running=True; do
    collect_metrics
done
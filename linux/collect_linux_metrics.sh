#!/bin/bash
#alert
# alert_call(){
#     cpu_temperature=$(get_cpu_test_temperature)
#     ram_percentage=$(get_free_ram_percentage)
#     temp_threshold=60
#     ram_threshold=10
#     if [[ $cpu_temperature =~ ^[0-9]+$ ]] && (( cpu_temperature > temp_threshold )); then
#         notify-send "High CPU Temperature" "Current temperature: $cpu_temperature°C"
#     fi
#     if (( $(echo "$ram_percentage < $ram_threshold" | bc -l) )); then
#         notify-send "Low Free RAM" "Current free RAM: $ram_percentage%"
#     fi
# }
#RAM functions
get_total_ram() {
    free -h | grep Mem | awk '{print $2}'
}
get_free_ram_percentage() {
    total_ram=$(free | grep Mem | awk '{print $2}')
    free_ram=$(free | grep Mem | awk '{print $7}')
    percentage=$(echo "scale=2; $free_ram / $total_ram * 100" |bc)
    echo "$percentage"
}
get_used_ram_percentage(){
    total_ram=$(free | grep Mem | awk '{print $2}')
    used_ram=$(free | grep Mem | awk '{print $3}')
    utilized_percentage=$(echo "scale=2; $used_ram / $total_ram *100" |bc)
    echo "$utilized_percentage"
}

#CPU functions
get_cpu_model_name(){
    lscpu | grep 'Model name' | sed -nr 's/.*:\s*(.*) @ .*/\1/p'
}
get_cpu_utilization() {
    mpstat | grep "all" | awk '{print 100 - $NF}' 
}
get_cpu_temperature() {
    if command -v sensors &> /dev/null; then
        sensors | grep 'Core 0:' | awk '{print $3}'
    else
        echo "sensors command not found, install lm-sensors if needed."
    fi
}
get_cpu_test_temperature() {
    cat /sys/class/thermal/thermal_zone0/temp | awk '{print $1/1000}'  # Get CPU temperature in °C
}
#GPU functions
get_gpu_model_name(){
    lspci | grep -i "vga\|3d\|2d" | awk -F ': ' '{print $2'}
}
get_gpu_info() {
    if command -v nvidia-smi &> /dev/null; then
        echo "nvidia"
    elif command -v amdgpu &> /dev/null; then
        echo "amd"
    elif lspci | grep -i "vga\|3d\|display" | grep -i "intel" &> /dev/null; then
        echo "intel"
    else
        echo "unknown"
    fi
}
get_gpu_utilization_nvidia() {
    nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits
}
get_gpu_temperature_nvidia() {
    nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits
}
get_gpu_utilization_amd() {
    if command -v amdgpu &> /dev/null; then
        amdgpu | grep "GPU Core Utilization" | awk '{print $3}'
    elif command -v radeontop &> /dev/null; then
        radeontop -i | grep "GPU" | awk '{print $2}'
    else
        echo "radeontop or amdgpu command not found, install AMD drivers."
    fi
}
get_gpu_temperature_amd() {
    if command -v sensors &> /dev/null; then
        sensors | grep 'temp1:' | awk '{print $2}'
    elif command -v radeontop &> /dev/null; then
        radeontop -i | grep "GPU" | awk '{print $3}'
    else
        echo "sensors or radeontop command not found, install AMD drivers."
    fi
}
get_gpu_utilization_intel() {
    if command -v intel_gpu_top &> /dev/null; then
        sudo timeout 5 intel_gpu_top > gpu_output.txt
        total=$(awk 'NR > 2 {rcs+=$9; bcs+=$12; vcs+=$15} END {print "RCS Sum: " rcs, "\nBCS Sum: " bcs, "\nVCS Sum: " vcs, "\nTotal: " rcs + bcs + vcs}' gpu_output.txt)
        echo "$total"
    else
        echo "intel_gpu_top is not installed."
    fi
}
get_gpu_temperature_intel() {
    if command -v sensors &> /dev/null; then
        sensors | grep 'i915:' | grep 'temp1' | awk '{print $2}'
    else
        echo "sensors command not found, install lm-sensors and Intel GPU drivers."
    fi
}
#Disk Space functions
get_total_disk_space(){
    df -h --total | grep total | awk '{print $2}'
}
get_used_disk_space(){
    df -h --total | grep total | awk '{print $3}'
}
get_available_disk_space(){
    df -h --total | grep total | awk '{print $4}'
}
#SMART status
check_smart_health() {
    all_disks=$(sudo smartctl --scan | awk '{print $1}')
    if [ -z "$all_disks" ]; then
        echo "No S.M.A.R.T.-capable disks found."
        return 1
    fi

    for device in $all_disks; do
        echo "Checking $device..."
        # Check S.M.A.R.T. health
        health=$(sudo smartctl -H "$device" | grep "SMART overall-health" | awk '{print $6}')
        if [ "$health" != "PASSED" ]; then
            echo "Disk $device: S.M.A.R.T. test FAILED or not healthy!"
            return 1
        fi
    done
    echo "All disks passed S.M.A.R.T. tests."
    return 0
}
#boot time
get_total_boot_time() {
    systemd-analyze | awk -F ' = ' '{print $2}' | awk '{print $1}'
}
#System load average
get_system_load(){
    uptime | awk '{print $11}' | tr -d ','
}
#Network Adapter Name
get_network_adapter_name(){
    lspci | grep -i network
}
#sending and receiving
get_sending_rate() {
    if ip link show wlp2s0 > /dev/null 2>&1; then
        send_kbps=$(ifstat -i wlp2s0 1 1 | tail -n 1 | awk '{print $1}')
    elif ip link show eth0 > /dev/null 2>&1; then
        send_kbps=$(ifstat -i eth0 1 1 | tail -n 1 | awk '{print $1}')
    else
        send_kbps=0.00
    fi
    echo $send_kbps
}

get_receiving_rate() {
    if ip link show wlp2s0 > /dev/null 2>&1; then
        recv_kbps=$(ifstat -i wlp2s0 1 1 | tail -n 1 | awk '{print $2}')
    elif ip link show eth0 > /dev/null 2>&1; then
        recv_kbps=$(ifstat -i eth0 1 1 | tail -n 1 | awk '{print $2}')
    else
        recv_kbps=0.00
    fi
    echo $recv_kbps
}

# IP addresses
get_ipv4_address() {
    if ip link show wlp2s0 > /dev/null 2>&1; then
        ip -4 addr show wlp2s0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1
    elif ip link show eth0 > /dev/null 2>&1; then
        ip -4 addr show eth0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1
    fi
}

get_ipv6_address() {
    if ip link show wlp2s0 > /dev/null 2>&1; then
        ip -6 addr show wlp2s0 | grep 'inet6 ' | awk '{print $2}' | cut -d/ -f1
    elif ip link show eth0 > /dev/null 2>&1; then
        ip -6 addr show eth0 | grep 'inet6 ' | awk '{print $2}' | cut -d/ -f1
    fi
}
#Report
check_smart_health
# alert_call
boot_time=$(get_total_boot_time)
ipv4=$(get_ipv4_address)
ipv6=$(get_ipv6_address)
echo "Startup time: $boot_time"
echo "IPV4 Address: $ipv4"
echo "IPV6 Address: $ipv6"
    ram_total=$(get_total_ram)
    ram_percentage=$(get_free_ram_percentage)
    utilized_ram=$(get_used_ram_percentage)
    cpu_model_name=$(get_cpu_model_name)
    cpu_utilization=$(get_cpu_utilization)
    cpu_temperature=$(get_cpu_temperature)
    gpu_model_name=$(get_gpu_model_name)
    total_disk_space=$(get_total_disk_space)
    available_disk_space=$(get_available_disk_space)
    used_disk_space=$(get_used_disk_space)
    process_wait_time=$(get_system_load)
    network_adapter_name=$(get_network_adapter_name)
    received_kilobytes=$(get_receiving_rate)
    sent_kilobytes=$(get_sending_rate)
    echo "Total RAM: $ram_total"
    echo "Free RAM: $ram_percentage%"
    echo "Utilized RAM: $utilized_ram%"
    echo "CPU Model: $cpu_model_name"
    echo "CPU Utilization: $cpu_utilization%"
    echo "CPU Temperature: $cpu_temperature"
    echo "GPU: $gpu_model_name"
    echo "Total Disk Space: $total_disk_space"
    echo "Used Disk Space: $used_disk_space"
    echo "Available Disk Space: $available_disk_space"
    echo "Average process waiting time: $process_wait_time"
    echo "Network Adapter Model: $network_adapter_name"
    echo "Sent: $sent_kilobytes"
    echo "Received: $received_kilobytes"
    gpu_type=$(get_gpu_info)
    case "$gpu_type" in
        "nvidia")
            echo "GPU Type: NVIDIA"
            gpu_utilization=$(get_gpu_utilization_nvidia)
            gpu_temperature=$(get_gpu_temperature_nvidia)
            ;;
        "amd")
            echo "GPU Type: AMD"
            gpu_utilization=$(get_gpu_utilization_amd)
            gpu_temperature=$(get_gpu_temperature_amd)
            ;;
        "intel")
            echo "GPU Type: Intel"
            gpu_utilization=$(get_gpu_utilization_intel)
            gpu_temperature=$cpu_temperature
            ;;
        "unknown")
            echo "GPU Type: Unknown"
            exit 1
            ;;
    esac
    echo "GPU Utilization: $gpu_utilization"
    echo "GPU Temperature: $gpu_temperature"
    sleep 1


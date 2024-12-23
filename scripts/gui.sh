#!/bin/bash
# detect_os() {
#     case "$(uname)" in
#         Darwin)
#             echo "macOS"
#             ;;
#         Linux)
#             echo "Linux"
#             ;;
#         *)
#             echo "Unsupported OS"
#             exit 1
#             ;;
#     esac
# }

# os=$(detect_os)
# echo "DETECTED: $os"

request_admin_privileges() {
    if command -v fprintd-verify > /dev/null; then
        if zenity --question --text="Biometric authentication available. Do you want to use it?" --ok-label="Use Biometrics" --cancel-label="Enter Password" --width=400 --height=200; then
            if fprintd-verify; then
                return 0  # Success
            else
                zenity --error --text="Biometric authentication failed." --width=400 --height=200
                return 1  # Failure
            fi
        fi
    fi

    while true; do
        PASSWORD=$(zenity --entry --title="Sudo Password" \
                          --text="Enter your sudo password:" \
                          --hide-text \
                          --width=400 --height=200)

        if [[ $? -ne 0 ]]; then
            zenity --error --text="Password entry canceled." --width=400 --height=200
            exit 1
        fi
        
        if [[ -z "$PASSWORD" ]]; then
            zenity --error --text="You must enter your sudo password to proceed." --width=400 --height=200
            continue  
        fi
        
        echo "$PASSWORD" | sudo -S -k true > /dev/null 2>&1
        
        if [[ $? -ne 0 ]]; then
            zenity --error --text="Invalid password. Please try again." --width=400 --height=200
            continue  
        fi
        
        break  
    done
    
    export SUDO_PASSWORD="$PASSWORD"
    return 0 
}

collect_metrics() {
    trap 'exit 0' SIGINT SIGTERM  # Ensure graceful termination on signals

    # Start a new shell with sudo privileges and call the appropriate metrics collection script based on OS detection.
    sudo bash -c "
        while \$collecting_metrics; do
            echo 'Running metrics collection for OS: $OS_NAME'  # Debugging line
            if [ '$OS_NAME' == 'Darwin' ]; then
                metrics_output=\$(./scripts/collect_macos_metrics.sh) || {
                    zenity --error --text='Error: Failed to collect macOS metrics.' --width=400 --height=200
                    exit 1
                }
            elif [ '$OS_NAME' == 'Linux' ]; then 
                metrics_output=\$(./scripts/collect_linux_metrics.sh) || {
                    zenity --error --text='Error: Failed to collect Linux metrics.' --width=400 --height=200
                    exit 1
                }
            else
                zenity --error --text='Unsupported OS detected. Exiting.' --width=400 --height=200
                exit 1
            fi
            
            echo \"\$metrics_output\" > system_metrics.txt
            python3 \"scripts/bash_to_csv.py\"
            sleep 1  # Add delay between collections
        done
    " <<< "$SUDO_PASSWORD"  # Pass the password to the sub-shell
}

start_collecting_metrics() {
    collecting_metrics=true
    collect_metrics &  # Start collecting metrics in the background.
    METRICS_PID=$!    # Capture the PID of the background process.
}

stop_collecting_metrics() {
    collecting_metrics=false  # Immediately stop collecting metrics.
    # If a metrics collection process is running, kill it.
    if [[ $METRICS_PID -gt 0 ]]; then 
        kill $METRICS_PID 2>/dev/null 
        wait $METRICS_PID 2>/dev/null || zenity --info --text="Metrics collection stopped successfully." --width=400 --height=200 
        METRICS_PID=0 
    fi 
}

# Trap SIGINT and SIGTERM at the beginning.
trap 'stop_collecting_metrics; exit' SIGINT SIGTERM

# Main <3
if ! request_admin_privileges; then
    zenity --error --text="Failed to obtain admin privileges. Exiting."
    exit 1
fi

start_gui() {
    ./scripts/gui.sh &
}

start_gui

start_collecting_metrics

INPUT_FILE="scripts/system_metrics.txt"
MARKDOWN_REPORT="scripts/system_report.md"
HTML_REPORT="scripts/systems_report.html"

generate_reports() {
    if [[ ! -f $INPUT_FILE ]]; then
        zenity --error --text="Error: Input file '$INPUT_FILE' not found! Please collect metrics first."
        return
    fi

    if scripts/gen_reports.sh; then
        zenity --info --text="Reports generated:\n- Markdown Report: ${MARKDOWN_REPORT}\n- HTML Report: ${HTML_REPORT}"

    else
        zenity --error --text="Error: Failed to generate reports."
    fi
}

show_metric_data() {
    local metric_type=$1
    case $metric_type in
        "Overall Metrics") zenity --info --title="$metric_type" --text="$(show_overall_metrics)" --width=500 --height=500 ;;
        "CPU Metrics") zenity --info --title="$metric_type" --text="$(show_cpu_metrics)" --width=500 --height=500 ;;
        "GPU Metrics") zenity --info --title="$metric_type" --text="$(show_gpu_metrics)" --width=500 --height=500 ;;
        "Memory/RAM Metrics") zenity --info --title="$metric_type" --text="$(show_memory_metrics)" --width=500 --height=500;;
        "Network Metrics") zenity --info --title="$metric_type" --text="$(show_network_metrics)" --width=500 --height=500;;
        "Load Metrics") zenity --info --title="$metric_type" --text="$(show_load_metrics)" --width=500 --height=500;;
        "Disk Metrics") zenity --info --title="$metric_type" --text="$(show_disk_metrics)" --width=500 --height=500;;
    esac
}
show_network_metrics(){
    network_adapter=$(cat 'scripts/system_metrics.txt' | grep 'Network Adapter Model')
    sent=$(cat 'scripts/system_metrics.txt' | grep 'Sent')
    received=$(cat 'scripts/system_metrics.txt' | grep 'Received')
    echo "$network_adapter"
    echo "$sent kb/s"
    echo "$received kb/s" 
    python3 scripts/grapher.py "network" & 
}
show_load_metrics(){
    startup_time=$(cat 'scripts/system_metrics.txt' | grep 'Startup time')
    average_process_wait_time=$(cat 'scripts/system_metrics.txt' | grep 'Average process waiting time')
    echo "$startup_time"
    echo "$average_process_wait_time"
}
show_overall_metrics(){
    startup_time=$(cat 'scripts/system_metrics.txt' | grep 'Startup time')
    average_process_wait_time=$(cat 'scripts/system_metrics.txt' | grep 'Average process waiting time')
    total_ram=$(cat 'scripts/system_metrics.txt' | grep 'Total RAM')
    cpu=$(cat 'scripts/system_metrics.txt' | grep 'CPU Model')
    gpu=$(cat 'scripts/system_metrics.txt' | grep 'GPU:')
    network_adapter=$(cat 'scripts/system_metrics.txt' | grep 'Network Adapter Model')
    echo "$cpu"
    echo "$total_ram"
    echo "$gpu"
    echo "$network_adapter"
    echo "$startup_time"
    echo "$average_process_wait_time"
}
show_disk_metrics(){
    total_disk_space=$(cat 'scripts/system_metrics.txt' | grep 'Total Disk Space')
    used_disk_space=$(cat 'scripts/system_metrics.txt' | grep 'Used Disk Space')
    available_disk_space=$(cat 'scripts/system_metrics.txt' | grep 'Available Disk Space')
    echo "$total_disk_space"
    echo "$used_disk_space"
    echo "$available_disk_space"
}
show_memory_metrics(){
    total_ram=$(cat 'scripts/system_metrics.txt' | grep -m 1 'Total RAM')
    free_ram=$(cat 'scripts/system_metrics.txt' | grep 'Free RAM')
    utilized_ram=$(cat 'scripts/system_metrics.txt' | grep 'Utilized RAM')
    echo "$total_ram"
    echo "$free_ram"
    echo "$utilized_ram"
    gnome-terminal -- python3 scripts/grapher.py "ram" & 
}
show_cpu_metrics(){
    cpu=$(cat 'scripts/system_metrics.txt' | grep 'CPU Model')
    #CPU Utilization: 31.08%
    #CPU Temperature: +51.0°C
    cpu_utilization=$(cat 'scripts/system_metrics.txt' | grep 'CPU Utilization')
    cpu_temperature=$(cat 'scripts/system_metrics.txt' | grep 'CPU Temperature')
    echo "$cpu"
    echo "$cpu_utilization"
    echo "$cpu_temperature"
    gnome-terminal -- python3 scripts/grapher.py "cpu" &   
}
show_gpu_metrics(){
    gpu=$(cat 'scripts/system_metrics.txt' | grep 'GPU:')
    rcs=$(cat 'scripts/system_metrics.txt' | grep 'RCS')
    bcs=$(cat 'scripts/system_metrics.txt' | grep 'BCS')
    vcs=$(cat 'scripts/system_metrics.txt' | grep 'VCS')
    temperature=$(cat 'scripts/system_metrics.txt' | grep 'GPU Temperature')
    echo "$gpu"
    echo "$rcs"
    echo "$bcs"
    echo "$vcs"
    echo "$temperature"
}
while true; do
    ACTION=$(zenity --list \
                    --title="System Monitoring Tool" \
                    --column="Actions" \
                    "Generate Reports" \
                    "View Overall Metrics" \
                    "View CPU Metrics" \
                    "View GPU Metrics" \
                    "View Memory/RAM Metrics" \
                    "View Network Metrics" \
                    "View Load Metrics" \
                    "View Disk Metrics" \
                    "Exit" \
                    --width=500 --height=500)

    case $? in
        0)
            case $ACTION in
                "Generate Reports") generate_reports ;;
                "View Overall Metrics") show_metric_data "Overall Metrics" ;;
                "View CPU Metrics") show_metric_data "CPU Metrics" ;;
                "View GPU Metrics") show_metric_data "GPU Metrics" ;;
                "View Memory/RAM Metrics") show_metric_data "Memory/RAM Metrics" ;;
                "View Network Metrics") show_metric_data "Network Metrics" ;;
                "View Load Metrics") show_metric_data "Load Metrics" ;;
                "View Disk Metrics") show_metric_data "Disk Metrics" ;;
                "Exit") stop_collecting_metrics; break ;;
            esac ;;
        *) 
            stop_collecting_metrics 
            break ;;
    esac
done

exit 0 

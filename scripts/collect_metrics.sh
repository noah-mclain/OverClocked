#!/bin/bash

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
get_cpu_model_name(){
    lscpu | grep 'Model name' | sed -nr 's/.*:\s*(.*) @ .*/\1/p'
}
get_cpu_utilization() {
    mpstat 1 1 | grep "all" | awk '{print 100 - $NF}' 
}
while true; do
    ram_total=$(get_total_ram)
    ram_percentage=$(get_free_ram_percentage)
    utilized_ram=$(get_used_ram_percentage)
    cpu_model_name=$(get_cpu_model_name)
    cpu_utilization=$(get_cpu_utilization)
    echo "Total RAM: $ram_total"
    echo "Free RAM: $ram_percentage%"
    echo "Utilized RAM: $utilized_ram%"
    echo "$cpu_model_name"
    echo "CPU Utilization: $cpu_utilization%"
    sleep 1
done

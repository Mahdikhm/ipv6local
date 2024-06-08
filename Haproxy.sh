#!/bin/bash

config_file="/etc/haproxy/haproxy.cfg"

install_haproxy() {
    echo "Installing HAProxy..."
    sudo apt-get update
    sudo apt-get install -y haproxy
    echo "HAProxy installed."
}

generate_haproxy_config() {
    local ports=($1)
    local target_ip=$2

    for port in "${ports[@]}"; do
        cat <<EOL >> $config_file

frontend frontend_$port
    bind *:$port
    default_backend backend_$port

backend backend_$port
    server server1 $target_ip:$port
EOL
    done

    echo "HAProxy configuration updated at $config_file"
}

add_ip_and_ports() {
    read -p "Enter the IP to forward to: " target_ip
    read -p "Enter the ports (use comma , to separate): " user_ports

    IFS=',' read -r -a ports_array <<< "$user_ports"
    generate_haproxy_config "${ports_array[*]}" "$target_ip"

    if haproxy -c -f $config_file; then
        echo "Restarting HAProxy service..."
        service haproxy restart
        echo "HAProxy configuration updated and service restarted."
    else
        echo "HAProxy configuration is invalid. Please check the configuration file."
    fi
}

clear_configs() {
    echo "Clearing IP and port configurations from HAProxy configuration..."

    # Remove IP and port configurations
    sed -i '/frontend frontend_/d' $config_file
    sed -i '/backend backend_/d' $config_file

    echo "Clearing IP and port configurations from $config_file."
    echo "Stoping HAProxy service..."
    service haproxy stop
    echo "Done !"
}

remove_haproxy() {
    echo "Removing HAProxy..."
    sudo apt-get remove --purge -y haproxy
    sudo apt-get autoremove -y
    echo "HAProxy removed."
}

while true; do
    sleep 1.5
    echo "Select an option:"
    echo "1) Install HAProxy"
    echo "2) Add IP and Ports to Forward"
    echo "3) Clear Configurations"
    echo "4) Remove HAProxy Completely"
    echo "9) Exit"
    read -p "Select a Number [1-5]: " choice

    case $choice in
        1)
            install_haproxy
            ;;
        2)
            add_ip_and_ports
            ;;
        3)
            clear_configs
            ;;
        4)
            remove_haproxy
            ;;
        9)
            echo "Exiting..."
            break
            ;;
        *)
            echo "Invalid option. Please try again."
            ;;
    esac
done

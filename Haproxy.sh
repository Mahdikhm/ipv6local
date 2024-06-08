#!/bin/bash

config_file="/etc/haproxy/haproxy.cfg"
backup_file="/etc/haproxy/haproxy.cfg.bak"
install_haproxy() {
    echo "Installing HAProxy..."
    sudo apt-get update
    sudo apt-get install -y haproxy
    echo "HAProxy installed."
    defalut_config
}
defalut_config() {
cat <<EOL > $config_file
global
    log /dev/log    local0
    log /dev/log    local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

    # Default SSL material locations
    ca-base /etc/ssl/certs
    crt-base /etc/ssl/private

    # Default ciphers to use on SSL-enabled listening sockets.
    # For more information, see ciphers(1SSL). This list is from:
    #  https://hynek.me/articles/hardening-your-web-servers-ssl-ciphers/
    ssl-default-bind-ciphers ECDH+AESGCM:ECDH+CHACHA20:ECDH+AES256:ECDH+AES128:ECDH+3DES:RSA+AESGCM:RSA+AES:RSA+3DES:!aNULL:!MD5:!DSS
    ssl-default-bind-options no-sslv3

defaults
    log     global
    mode    tcp
    option  tcplog
    option  dontlognull
    timeout connect 5000
    timeout client  50000
    timeout server  50000
    errorfile 400 /etc/haproxy/errors/400.http
    errorfile 403 /etc/haproxy/errors/403.http
    errorfile 408 /etc/haproxy/errors/408.http
    errorfile 500 /etc/haproxy/errors/500.http
    errorfile 502 /etc/haproxy/errors/502.http
    errorfile 503 /etc/haproxy/errors/503.http
    errorfile 504 /etc/haproxy/errors/504.http
EOL
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
        service haproxy start
        echo "Restarting HAProxy service..."
        service haproxy restart
        echo "HAProxy configuration updated and service restarted."
    else
        echo "HAProxy configuration is invalid. Please check the configuration file."
    fi
}

clear_configs() {
    echo "Creating a backup of the HAProxy configuration..."
    cp $config_file $backup_file

    if [ $? -ne 0 ]; then
        echo "Failed to create a backup. Aborting."
        return
    fi

    echo "Clearing IP and port configurations from HAProxy configuration..."

    # Use awk to remove the frontend and backend configurations
    awk '
    /^frontend frontend_/ {skip = 1}
    /^backend backend_/ {skip = 1}
    skip {if (/^$/) {skip = 0}; next}
    {print}
    ' $backup_file > $config_file

    echo "Clearing IP and port configurations from $config_file."
    
    echo "Stopping HAProxy service..."
    service haproxy stop
    
    if [ $? -eq 0 ]; then
        echo "HAProxy service stopped."
    else
        echo "Failed to stop HAProxy service."
    fi

    echo "Done!"
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
    echo "9) Back"
    read -p "Select a Number : " choice

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

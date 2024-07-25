#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Function to display the menu
show_menu() {
  echo "1) Iran"
  echo "2) Kharej"
  echo "3) Uninstall"
  echo "4) custome ips"
  echo "9) Back"
}

while true; do
  show_menu
  read -p "Select number : " choices

  case $choices in
    1)
      cp /etc/rc.local /root/rc.local.old
      ipv4_address=$(curl -s https://api.ipify.org)
      echo "Iran IPv4 is : $ipv4_address"
      read -p "Enter Kharej Ipv4 : " ip_remote
      rctext='#!/bin/bash

ip tunnel add 6to4tun_IR mode sit remote '"$ip_remote"' local '"$ipv4_address"'
ip -6 addr add 2001:418:1401:1e::1/64 dev 6to4tun_IR
ip link set 6to4tun_IR mtu 1480
ip link set 6to4tun_IR up
# configure tunnel GRE6 or IPIPv6 IR
ip -6 tunnel add GRE6Tun_IR mode ip6gre remote 2001:418:1401:1e::2 local 2001:418:1401:1e::1
ip addr add 172.16.1.1/30 dev GRE6Tun_IR
ip link set GRE6Tun_IR mtu 1436
ip link set GRE6Tun_IR up

iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD  -j ACCEPT
echo "net.ipv4.ip_forward=1" > /etc/sysctl.conf
sysctl -p
'
      sleep 0.5
      echo "$rctext" > /etc/rc.local
      chmod +x /etc/rc.local
      /etc/rc.local
      echo
      ;;
    2)
      cp /etc/rc.local /root/rc.local.old
      ipv4_address=$(curl -s https://api.ipify.org)
      echo "Kharej IPv4 is : $ipv4_address"
      read -p "Enter Iran Ip : " ip_remote
      rctext='#!/bin/bash
ip tunnel add 6to4tun_KH mode sit remote '"$ip_remote"' local '"$ipv4_address"'
ip -6 addr add 2001:418:1401:1e::2/64 dev 6to4tun_KH
ip link set 6to4tun_KH mtu 1480
ip link set 6to4tun_KH up

ip -6 tunnel add GRE6Tun_KH mode ip6gre remote 2001:418:1401:1e::1 local 2001:418:1401:1e::2
ip addr add 172.16.1.2/30 dev GRE6Tun_KH
ip link set GRE6Tun_KH mtu 1436
ip link set GRE6Tun_KH up

iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD  -j ACCEPT
echo "net.ipv4.ip_forward=1" > /etc/sysctl.conf
sysctl -p
'
      sleep 0.5
      echo "$rctext" > /etc/rc.local
      chmod +x /etc/rc.local
      /etc/rc.local
      echo
      echo "Local IPv6 Kharej: 2001:418:1401:1e::2"
      echo "Local Ipv6 Iran: 2001:418:1401:1e::1"
      echo "Local IPv4 Kharej 172.16.1.2"
      echo "Local IPv4 Iran 172.16.1.1"
      ;;
    3)
      rm -rf /etc/rc.local
      ip link show | awk '/6to4tun/ {split($2,a,"@"); print a[1]}' | xargs -I {} ip link set {} down
      ip link show | awk '/6to4tun/ {split($2,a,"@"); print a[1]}' | xargs -I {} ip tunnel del {}
      ip link show | awk '/GRE6Tun/ {split($2,a,"@"); print a[1]}' | xargs -I {} ip link set {} down
      ip link show | awk '/GRE6Tun/ {split($2,a,"@"); print a[1]}' | xargs -I {} ip tunnel del {}
      echo "Uninstalled successfully"
      read -p "Do you want to reboot? (recommended) [y/n] : " yes_no
      if [[ $yes_no =~ ^[Yy]$ ]] || [[ $yes_no =~ ^[Yy]es$ ]]; then
        reboot
      fi
      ;;
    4)
      read -p "Interface name: " interface
      ipv4_address=$(curl -s https://api.ipify.org)
      echo "Server IPv4 is: $ipv4_address"
      read -p "Enter Remote IP: " ip_remote
      read -p "Private IPv4 (e.g., 172.16.1.1): " pipv4

# Create a separate script
      script_path="/usr/local/bin/setup_gre_tunnel.sh"

      cat << EOF > $script_path
#!/bin/bash
ip tunnel add GRE_$interface mode gre remote $ip_remote local $ipv4_address ttl 255
ip addr add $pipv4/30 dev GRE_$interface
ip link set GRE_$interface mtu 1436
ip link set GRE_$interface up
EOF

      chmod +x $script_path
      sudo $script_path
      
      # Optionally, to make it persistent across reboots, add it to rc.local
      if ! grep -Fxq "$script_path" /etc/rc.local; then
          sudo sed -i -e '$i \'"$script_path" /etc/rc.local
      fi
        ;;
    9)
      echo "Exiting..."
      exit 0
      ;;
    *)
      echo "Wrong input, please try again."
      ;;
  esac

  # Pause before showing the menu again
  sleep 1
done

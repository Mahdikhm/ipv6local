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
ip -6 addr add 2001:470:1f10:e1f::1/64 dev 6to4tun_IR
ip link set 6to4tun_IR mtu 1480
ip link set 6to4tun_IR up
# configure tunnel GRE6 or IPIPv6 IR
ip -6 tunnel add GRE6Tun_IR mode ip6gre remote 2001:470:1f10:e1f::2 local 2001:470:1f10:e1f::1
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
ip -6 addr add 2001:470:1f10:e1f::2/64 dev 6to4tun_KH
ip link set 6to4tun_KH mtu 1480
ip link set 6to4tun_KH up

ip -6 tunnel add GRE6Tun_KH mode ip6gre remote 2001:470:1f10:e1f::1 local 2001:470:1f10:e1f::2
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
      echo "Local IPv6 Kharej: 2001:470:1f10:e1f::2"
      echo "Local Ipv6 Iran: 2001:470:1f10:e1f::1"
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
        read -p "interface name: " interface
        rctext='#!/bin/bash
        ipv4_address=$(curl -s https://api.ipify.org)
        echo "Server IPv4 is : $ipv4_address"
        read -p "Enter Remote Ip : " ip_remote
        read -p "Private ipv6 (eg 2001:470:1f10:e1f::1 ): " pipv6
        read -p "Private ipv4 (eg 172.16.1.1 )" pipv4
ip tunnel add '"$interface"' mode sit remote '"$ip_remote"' local '"$ipv4_address"'
ip -6 addr add '"$pipv6"'/64 dev '"$interface"'
ip link set '"$interface"' mtu 1480
ip link set '"$interface"' up

ip -6 tunnel add GRE_'"$interface"' mode ip6gre remote 2001:470:1f10:e1f::2 local 2001:470:1f10:e1f::1
ip addr add '"$pipv4"'/30 dev GRE_'"$interface"'
ip link set GRE_'"$interface"' mtu 1436
ip link set GRE_'"$interface"' up
'
        echo "$rctext" > /etc/rc.local
        chmod +x /etc/rc.local
        bash /etc/rc.local
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

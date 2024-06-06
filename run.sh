#!/bin/bash
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Continue with the rest of the script if running as root
apt update
apt install iptables -y

echo "1. Iran"
echo "2. Kharej"
echo "3. uninstall"
echo "4. hawshemi Linux Optimizer"
echo "5. X-UI Sanai"
# Prompt user for IP addresses
read -p "Select number : " choices
if [ "$choices" -eq 1 ]; then
  cp /etc/rc.local /root/rc.local.old
  ipv4_address=$(curl -s https://api.ipify.org)
  echo "Iran IPv4 is : $ipv4_address"
  read -p "enter Kharej Ipv4 :" ip_remote
  rctext='#!/bin/bash

ip tunnel add 6to4tun_IR mode sit remote '"$ip_remote"' local '"$ipv4_address"'
ip -6 addr add 2001:470:1f10:e1f::1/64 dev 6to4tun_IR
ip link set 6to4tun_IR mtu 1480
ip link set 6to4tun_IR up
# confige tunnele GRE6 ya IPIPv6 IR
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
elif [ "$choices" -eq 2 ]; then
  cp /etc/rc.local /root/rc.local.old
  ipv4_address=$(curl -s https://api.ipify.org)
  echo "Kharej IPv4 is : $ipv4_address"
  read -p "enter Iran Ip : " ip_remote
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
elif [ "$choices" -eq 3 ]; then
  rm -rf /etc/rc.local
  ip link show | awk '/6to4tun/ {split($2,a,"@"); print a[1]}' | xargs -I {} ip link set {} down
  ip link show | awk '/6to4tun/ {split($2,a,"@"); print a[1]}' | xargs -I {} ip tunnel del {}
  ip link show | awk '/GRE6Tun/ {split($2,a,"@"); print a[1]}' | xargs -I {} ip link set {} down
  ip link show | awk '/GRE6Tun/ {split($2,a,"@"); print a[1]}' | xargs -I {} ip tunnel del {}
  echo "uninstalled successfully"
  read -p "do you want to reboot?(recommended)[y/n] :" yes_no
  if [[ $yes_no =~ ^[Yy]$ ]] || [[ $yes_no =~ ^[Yy]es$ ]]; then
    reboot
  fi
elif [ "$choices" -eq 4 ]; then
  sudo apt install -y sudo wget
  wget "https://raw.githubusercontent.com/hawshemi/Linux-Optimizer/main/linux-optimizer.sh" -O linux-optimizer.sh && chmod +x linux-optimizer.sh && bash linux-optimizer.sh 
elif [ "$choices" -eq 5 ]; then
  bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
else
  echo "wrong input"
  exit 1
fi
if [[ "$choices" -eq 1 || "$choices" -eq 2 ]]; then
  chmod +x /etc/rc.local
  sleep 0.5
  /etc/rc.local
  echo    # move to a new line

  if [ "$choices" -eq 2 ]; then
  echo "Local IPv6 Kharej: 2001:470:1f10:e1f::2"
  echo "Local Ipv6 Iran: 2001:470:1f10:e1f::1"
  echo "Local IPv4 Kharej 172.16.1.2"
  echo "Local IPv4 Iran 172.16.1.1"
  fi
fi

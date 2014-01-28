#!/bin/bash

SSID=$1
SSID_PWD=$2
SSID_PWD_CRYPT=`wpa_passphrase test password | grep psk | sed "/#/d" | cut -d'=' -f2`
RPI_HOSTNAME=wallboard

# setup the RPi’s hostname
echo $RPI_HOSTNAME > /etc/hostname

# set up the WiFi card settings

# comment the lines we want to override
sudo sed -i "s/^allow-hotplug wlan0.*$/#&/g" /etc/network/interfaces
sudo sed -i "s/^iface wlan0 inet manual.*$/#&/g" /etc/network/interfaces
sudo sed -i "s/^wpa-roam.*$/#&/g" /etc/network/interfaces
sudo sed -i "s/^iface default inet dhcp.*$/#&/g" /etc/network/interfaces

# append the new settings to /etc/network/interfaces
sudo cat <<'EOF' >> /etc/network/interfaces
auto wlan0
allow-hotplug wlan0
iface wlan0 inet dhcp
     wpa-ssid "put_here_the_ssid"
     wpa-psk put_here_the_crypted_ssid_password
EOF

sed -i “s/put_here_the_ssid/$SSID/g” /etc/network/interfaces
sed -i “s/put_here_the_crypted_ssid_password/$SSID_PWD_CRYPT/g” /etc/network/interfaces

# try to bring up the wlan0 device
ifdown wlan0 && sleep 5 && ifup wlan0

# install the avahi-daemon to be able to access the RPi as wallboard.local
apt-get -q update && apt-get -q upgrade
apt-get -q install avahi-daemon x11vnc chromium vim


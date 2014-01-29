#!/bin/bash
# run this script as 'root' or with 'sudo'
SSID=$1
SSID_PWD=$2
SSID_PWD_CRYPT=`wpa_passphrase test password | grep psk | sed "/#/d" | cut -d'=' -f2`
RPI_HOSTNAME=wallboard
WIFI_CHECK_URL="https://raw.github.com/marcomc/rpi_wifi_check/master/WiFi_Check"
WIFI_CHECK_PATH="/usr/local/bin/WiFi_Check"
WIFI_CHECK_CRONJOB="/etc/cron.d/WiFi_Check"

# setup the RPi’s hostname
echo "Changing the hostname to RPI_HOSTNAME"
echo $RPI_HOSTNAME > /etc/hostname

# set up the WiFi card settings

echo "Configuring wlan0 on /etc/network/interfaces"
# comment the lines we want to override
sed -i "s/^allow-hotplug wlan0.*$/#&/g" /etc/network/interfaces
sed -i "s/^iface wlan0 inet manual.*$/#&/g" /etc/network/interfaces
sed -i "s/^wpa-roam.*$/#&/g" /etc/network/interfaces
sed -i "s/^iface default inet dhcp.*$/#&/g" /etc/network/interfaces

# append the new settings to /etc/network/interfaces
cat <<'EOF' >> /etc/network/interfaces
auto wlan0
allow-hotplug wlan0
iface wlan0 inet dhcp
     wpa-ssid "put_here_the_ssid"
     wpa-psk put_here_the_crypted_ssid_password
EOF

sed -i “s/put_here_the_ssid/$SSID/g” /etc/network/interfaces
sed -i “s/put_here_the_crypted_ssid_password/$SSID_PWD_CRYPT/g” /etc/network/interfaces

echo "Activating wlan0"
# try to bring up the wlan0 device
ifdown wlan0 && sleep 5 && ifup wlan0

echo "Updating the system"
# install the avahi-daemon to be able to access the RPi as wallboard.local
apt-get -q update && apt-get -q upgrade
echo "Installing Avahi Daemon, VNC and Chromium"
apt-get -q install avahi-daemon x11vnc chromium vim chkconfig
chkconfig -a avahi-daemon --level 2345 --deps rc.local 2> /dev/null
#makes sure that avahi-daemon is started when the internet connection is up and running (after the rc.local script is run)
mv /etc/rc2.d/S03avahi-daemon /etc/rc2.d/S06avahi-daemon

# the WiFi on the RPi is quite bad, but with the right workarounds it will do the job,
# as a backup (or preferred solution) you can make use of a Ethernet connection.
echo "Installing WiFi_Check"
curl -# -o $WIFI_CHECK_PATH $WIFI_CHECK_URL
chmod 755 $WIFI_CHECK_PATH

echo "Setup a CRON job for WiFi_Check"

cat <<'EOF' > $WIFI_CHECK_CRONJOB
# Run Every 3 mins - Seems like ever min is over kill unless
# this is a very common problem.
# If once a min change */5 to *
# once every 2 mins */5 to */2 ...
#
*/2 * * * *     root    /usr/local/bin/WiFi_Check 2>&1 > /var/log/wifi_check.log
EOF




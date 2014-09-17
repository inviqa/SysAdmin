#!/bin/bash
# run this script as 'root' or with 'sudo'

# requires the paramaeter ssid= to be set in config.txt
SSID=`cat config.txt |grep ssid= | sed "/#/d" | cut -d = -f2`
# requires the paramaeter ssid_password= (clear password) to be set in config.txt
SSID_PWD=`cat config.txt |grep ssid_password= | sed "/#/d" | cut -d = -f2`
# comverts the clear password in a cripted password
SSID_PWD_CRYPT=`wpa_passphrase $SSID $SSID_PWD | grep psk | sed "/#/d" | cut -d'=' -f2`
NEW_RPI_HOSTNAME=`cat config.txt |grep hostname= | sed "/#/d" | cut -d = -f2`
WIFI_CHECK_URL="https://raw.github.com/marcomc/rpi_wifi_check/master/WiFi_Check"
RC_LOCAL_PATCH_URL="https://raw.github.com/inviqa/SysAdmin/master/rpi_wallboard/rc_local.patch"
XINITRC_URL="https://raw.github.com/inviqa/SysAdmin/master/rpi_wallboard/xinitrc"
WIFI_CHECK_PATH="/usr/local/bin/WiFi_Check"
WIFI_CHECK_CRONJOB="/etc/cron.d/WiFi_Check"
SCHEDULED_SHUTDOWN_CRONJOB="/etc/cron.d/ScheduledShutdown"

# setup the RPi’s hostname
if [ "$HOSTNAME" != "$NEW_RPI_HOSTNAME" ]; then
	echo "Changing the hostname to $RPI_HOSTNAME"
	echo $NEW_RPI_HOSTNAME > /etc/hostname
fi

# set up the WiFi card settings

echo "Configuring wlan0 on /etc/network/interfaces"
# comment the lines we want to override
sed -i "s/^allow-hotplug wlan0.*$/#&/g" /etc/network/interfaces
sed -i "s/^iface wlan0 inet manual.*$/#&/g" /etc/network/interfaces
sed -i "s/^wpa-roam.*$/#&/g" /etc/network/interfaces
sed -i "s/^iface default inet dhcp.*$/#&/g" /etc/network/interfaces

if cat /etc/network/interfaces | grep "wallboard_setup_ok";then
  echo "wlan0 is already configured"
else
  echo "Configuring wlan0"
  # append the new settings to /etc/network/interfaces
  cat <<'EOF' >> /etc/network/interfaces
## wallboard_setup_ok ## if this line is present the wallboard_setup script will not work again
auto wlan0
allow-hotplug wlan0
iface wlan0 inet dhcp
     wpa-ssid "put_here_the_ssid"
     wpa-psk put_here_the_crypted_ssid_password
## remove this wall block if 	you want wallboard_setup to work properly ##
EOF
fi

# test if it's been specified a ne compbination SSID and password
if [[ ! -z "$SSID" && ! -z "$SSID_PWD_CRYPT"  ]];then
  echo "Updating the WiFi connection credentials"
  sed -i "s/put_here_the_ssid/$SSID/g" /etc/network/interfaces
  sed -i "s/put_here_the_crypted_ssid_password/$SSID_PWD_CRYPT/g" /etc/network/interfaces
  
  #for security reasons the clear copy of the password and ssid are removed from the config.txt after been used in the network interface configuration file
  sed -i "s/^ssid=.*$/ssid_=/g" /etc/network/interfaces
  sed -i "s/^ssid_password=.*$/ssid_password=/g" /etc/network/interfaces
fi

# try to bring up the wlan0 device
echo "Activating wlan0"
ifdown wlan0 && sleep 5 && ifup wlan0

echo "Removing lightdm-gtk-greater"
apt-get -qy remove lightdm-gtk-greeter

echo "Updating the system"
apt-get -qy update && apt-get -qy upgrade && apt-get -qy autoremove

# install the avahi-daemon to be able to access the RPi as wallboard.local
echo "Installing Lightdm, Avahi Daemon, VNC and Chromium"
apt-get -qy install avahi-daemon x11vnc chromium vim chkconfig matchbox-window-manager ntpdate

# makes sure that the time is correct
service ntp stop
ntpdate-debian
service ntp start

#chkconfig lightdm off
chkconfig -a avahi-daemon --level 2345 --deps rc.local 2> /dev/null
#makes sure that avahi-daemon is started when the internet connection is up and running (after the rc.local script is run)
mv /etc/rc2.d/S03avahi-daemon /etc/rc2.d/S06avahi-daemon

echo "VNC is accessible at $HOSTNAME.local in ViewOnly mode with NO password"
# the WiFi on the RPi is quite bad, but with the right workarounds it will do the job,
# as a backup (or preferred solution) you can make use of a Ethernet connection.
echo "Installing WiFi_Check"
curl -# -o $WIFI_CHECK_PATH $WIFI_CHECK_URL
chmod 755 $WIFI_CHECK_PATH

echo "Setup a CRON job for WiFi_Check"
cat <<'EOF' > $WIFI_CHECK_CRONJOB
# Run Every 3 mins - Seems like ever min is over kill unless
# this is a very common problem.
#
*/3 * * * *     root    /usr/local/bin/WiFi_Check 2>&1 > /var/log/wifi_check.log
EOF

echo "Setup a CRON job for Scheduled Shutdown at 8pm"
cat <<'EOF' > $SCHEDULED_SHUTDOWN_CRONJOB
# Shuts the system down everyday at 8pm
00 20 * * *	root	/sbin/shutdown -h now 2>&1 >> /var/log/syslog
EOF

if [ ! -f /boot/xinitrc ];then
  echo "Installing /boot/xinitrc"
  curl -# -o /boot/xinitrc $XINITRC_URL
else
  echo "/boot/xinitrc was already installed"
fi

if cat /etc/rc.local | grep "rc.local_is_patched"; then
  echo "/etc/rc.local is alredy patched"
else
  echo "Patching /etc/rc.local to load the new xinitrc file" 
  # removed the 'exit 0' to allow to append the rc.local patch (which will reintroduce the 'exit 0')
  sed -i "/^exit 0/d" /etc/rc.local
  # download the patch
  curl -# -o /tmp/rc_local.patch $RC_LOCAL_PATCH_URL
  # apply the patch
  echo "## rc.local_is_patched ## if this line is present rc.local has already been patched" >> /etc/rc.local
  cat /tmp/rc_local.patch >>  /etc/rc.local
  echo "## remove this wall block if you want rc_local.patch to be re-applied#" >> /etc/rc.local
  # clean up
  rm /tmp/rc_local.patch
fi
echo "The RPi Wallboard setup is compleated"
echo "restart the RPi using 'sudo shutdown -r now'"
# now

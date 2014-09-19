#!/usr/bin/env bash
# run this script as 'root' or with 'sudo'
RPI_CONFIG='/boot/config.txt'

RC_LOCAL_PATCH_PATH='/boot/rc_local.patch'
RC_LOCAL_PATCH_URL='https://raw.github.com/inviqa/SysAdmin/master/rpi_wallboard/rc_local.patch'

XINITRC_URL='https://raw.github.com/inviqa/SysAdmin/master/rpi_wallboard/xinitrc'

#if you want don't want to use the onlince copy of WiFi_Check
WIFI_CHECK_SCRIPT="/boot/WiFi_Check"
WIFI_CHECK_PATH='/usr/local/bin/WiFi_Check'
WIFI_CHECK_URL='https://raw.github.com/marcomc/rpi_wifi_check/master/WiFi_Check'
WIFI_CHECK_CRONJOB='/etc/cron.d/WiFi_Check'

SCHEDULED_SHUTDOWN_CRONJOB='/etc/cron.d/ScheduledShutdown'

function _update_hostname(){
	#retieves the new hostname from the $RPI_CONFIG file
	NEW_RPI_HOSTNAME=$(cat $RPI_CONFIG |grep hostname= | sed "/#/d" | cut -d = -f2)
	if [[ "$HOSTNAME" != "$NEW_RPI_HOSTNAME" && ! -z "$NEW_RPI_HOSTNAME" ]]; then
		echo "Changing the hostname to $NEW_RPI_HOSTNAME"
		echo $NEW_RPI_HOSTNAME > /etc/hostname
	  	sed -i "s/127.0.1.1.*$/127.0.1.1 $NEW_RPI_HOSTNAME/g" /etc/hosts
		hostname $NEW_RPI_HOSTNAME
	fi
}

function _update_interfaces(){
	# set up the WiFi card settings
	if cat /etc/network/interfaces | grep "wallboard_setup_ok";then
	  echo "wlan0 is already configured"
	else

	 echo "Configuring wlan0 on /etc/network/interfaces"
	 # comment the lines we want to override
	sed -i "s/^allow-hotplug wlan0.*$/#&/g" /etc/network/interfaces
	sed -i "s/^iface wlan0 inet manual.*$/#&/g" /etc/network/interfaces
	sed -i "s/^wpa-roam.*$/#&/g" /etc/network/interfaces
	sed -i "s/^iface default inet dhcp.*$/#&/g" /etc/network/interfaces

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

}
function _update_wifi_credentials() {
	# requires the paramaeter ssid= to be set in $RPI_CONFIG
	SSID=`cat $RPI_CONFIG |grep ssid= | sed "/#/d" | cut -d = -f2`
	# requires the paramaeter ssid_password= (clear password) to be set in $RPI_CONFIG
	SSID_PWD=`cat $RPI_CONFIG |grep ssid_password= | sed "/#/d" | cut -d = -f2`
	# comverts the clear password in a cripted password

	# test if it's been specified a new compbination SSID and password
	# if SSID and/or the SSID password have been changed then updates the interfaces file with the new values
	if [[ ! -z "$SSID" ]];then
	  echo "Updating the WiFi SSID name"
	  sed -i "s/wpa-ssid.*$/wpa-ssid \"$SSID\"/g" /etc/network/interfaces
	fi
	SSID_PWD_CRYPT=$(wpa_passphrase $SSID $SSID_PWD | grep psk | sed "/#/d" | cut -d'=' -f2)
	if [[ ! -z "$SSID_PWD_CRYPT" ]];then
	  echo "Updating the WiFi connection credentials"
	  sed -i "s/wpa-psk.*$/wpa-psk $SSID_PWD_CRYPT/g" /etc/network/interfaces
	  
	  #for security reasons the clear copy of the password is removed from the $RPI_CONFIG after been used in the network interface configuration file
	  sed -i "s/ssid_password=.*$/ssid_password=/g" $RPI_CONFIG
	fi

}

function _activate_wifi(){
	# try to bring up the wlan0 device
	echo "Activating wlan0"
	ifdown wlan0 && sleep 5 && ifup wlan0
}

function _install_wifi_check(){
	
	# the WiFi on the RPi is quite bad, but with the right workarounds it will do the job,
	# as a backup (or preferred solution) you can make use of a Ethernet connection.
	if [ -f $WIFI_CHECK_SCRIPT ];then
		echo "Using the WiFi_Check script located in /boot"
		cp $WIFI_CHECK_SCRIPT $WIFI_CHECK_PATH
	else
		echo "Installing WiFi_Check"
		curl -# -o $WIFI_CHECK_PATH $WIFI_CHECK_URL
	fi
	chmod 755 $WIFI_CHECK_PATH
	echo "Setup a CRON job for WiFi_Check"
	cat <<'EOF' > $WIFI_CHECK_CRONJOB
# Run Every 3 mins - Seems like ever min is over kill unless
# this is a very common problem.
#
*/3 * * * *     root    /usr/local/bin/WiFi_Check 2>&1 > /var/log/wifi_check.log
EOF

}

function _setup_wifi() {
	_update_interfaces
	_update_wifi_credentials
	_activate_wifi
	_install_wifi_check
}

function _update_packages(){
	echo "Updating the system"
	apt-get -qy update && apt-get -qy upgrade	
	echo "Removing lightdm-gtk-greater"
	apt-get -qy remove lightdm-gtk-greeter
	# install the avahi-daemon to be able to access the RPi as wallboard.local
	echo "Installing Lightdm, Avahi Daemon, VNC and Chromium"
	apt-get -qy install avahi-daemon x11vnc chromium vim chkconfig matchbox-window-manager ntpdate xwit sqlite3 x11-xserver-utils
	echo "Cleaning up with auto-remove"
	apt-get -qy autoremove
}

function _sinc_clock(){
	# makes sure that the time is correct
	echo "Setting the time with ntp"
	service ntp stop
	ntpdate-debian
	service ntp start
}

function _setup_avahi(){
	echo "Configuring ZerConf serverice with avahi-daemon"
	#chkconfig lightdm off
	chkconfig -a avahi-daemon --level 2345 --deps rc.local 2> /dev/null
	#makes sure that avahi-daemon is started when the internet connection is up and running (after the rc.local script is run)
	mv /etc/rc2.d/S03avahi-daemon /etc/rc2.d/S06avahi-daemon

	echo "VNC will accessible accessible at $HOSTNAME.local in ViewOnly mode with NO password"
}

function _setup_scheduled_shutdown(){
	echo "Setup a CRON job for Scheduled Shutdown at 8pm"
	cat <<'EOF' > $SCHEDULED_SHUTDOWN_CRONJOB
# Shuts the system down everyday at 8pm
00 20 * * *	root	/sbin/shutdown -h now 2>&1 >> /var/log/syslog
EOF
}

function _get_xinitrc(){
	if [ ! -f /boot/xinitrc ];then
	  echo "Installing /boot/xinitrc"
	  curl -# -o /boot/xinitrc $XINITRC_URL
	else
	  echo "/boot/xinitrc was already installed"
	fi
}

function _get_rc_local_patch(){
	if [ -f $RC_LOCAL_PATCH_PATH  ];then
		echo "$RC_LOCAL_PATCH_PATH already existing"
	else
		echo "Downloading $RC_LOCAL_PATCH_URL"
	  	# download the patch
	  	curl -# -o $RC_LOCAL_PATCH_PATH $RC_LOCAL_PATCH_URL
	fi
}
function _patch_rc_local(){
	if cat /etc/rc.local | grep "rc.local_is_patched"; then
	  echo "/etc/rc.local is alredy patched"
	else
	  echo "Backup of /etc/rc.local as /etc/rc.local.bk"
	  cp -a /etc/rc.local /etc/rc.local.bk
	  echo "Patching /etc/rc.local to load the new xinitrc file" 
	  # removed the 'exit 0' to allow to append the rc.local patch (which will reintroduce the 'exit 0')
	  sed -i "/^exit 0/d" /etc/rc.local
	  _get_rc_local_patch
	  echo "## rc.local_is_patched ## if this line is present rc.local has already been patched" >> /etc/rc.local
	  cat $RC_LOCAL_PATCH_PATH >>  /etc/rc.local
	  mv /etc/rc.local /boot/rc.local
	  ln -s /boot/rc.local /etc/rc.local
	fi
}

function _configure_system() {	
	_update_packages
	_sync_clock
	_setup_avahi
	_setup_scheduled_shutdown
	_get_xinitrc
	_patch_rc_local
	echo "The RPi Wallboard setup is compleated"
}

function rpi_setup(){	
	if [[ "$1" == "firstrun" ]]; then
		#if no parameter is pass
		_update_hostname
		_setup_wifi
		_configure_system
		echo "restart the RPi using 'sudo shutdown -r now'"
	elif [[ "$1" == "hostnameupdate" ]]; then
		_update_hostname
	elif [[ "$1" == "wifiupdate" ]]; then
		_update_wifi_credentials
		_activate_wifi
	else
	#if an empty or invalid parameter is passed then it prints the usage
		cat <<'EOF' 
Usage: wallboard_setup.sh firstrun (only for very first run)
       wallboard_setup.sh wifiupdate (when you want to update the wifi SSID and secret)
       wallboard_setup.sh hostnameupdate (when you want to change the hostname)
EOF
	fi
}

rpi_setup $1

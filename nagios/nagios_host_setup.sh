#!/bin/sh

RSA_PUB_KEY_URL="https://raw.github.com/inviqa/SysAdmin/master/nagios/inviqa_nagios_user_rsa_public_key.pub"
THIRD_PARTY_UNPACKAGED_SCRIPTS_URL="https://raw.github.com/inviqa/SysAdmin/master/nagios/third-party"
NAGIOS_USER_HOME="/home/nagios" #please don't change this
BIN_DIR="$NAGIOS_USER_HOME/bin"

### for Centos 5.x
# adding the remi and epel repos to have the nagios packages available
NAGIOS_SCRIPTS_SYSTEM_DIR="/usr/lib64/nagios/plugins"
curl -o pel-release-5-4.noarch.rpm http://dl.fedoraproject.org/pub/epel/5/x86_64/epel-release-5-4.noarch.rpm
curl -o remi-release-5.rpm http://rpms.famillecollet.com/enterprise/remi-release-5.rpm
sudo rpm -Uvh pel-release-5-4.noarch.rpm remi-release-5.rpm 
rm pel-release-5-4.noarch.rpm remi-release-5.rpm 

# Installation of nagios checks scripts and necassary libraries
yum install nagios-plugins nagios-common  nagios-plugins-http nagios-plugins-load nagios-plugins-disk nagios-plugins-swap

# creation of a nagios user on each server
adduser nagios --disabled-password --home $NAGIOS_USER_HOME
mkdir $NAGIOS_USER_HOME/.ssh
touch $NAGIOS_USER_HOME/.ssh/authorized_keys
chown -R nagios:nagios $NAGIOS_USER_HOME/.ssh
chmod -R go-rwx $NAGIOS_USER_HOME/.ssh

# install the SSH2 RSA Public key of the nagios user of the nagios/icinga server
curl -o nagios_rsa_key.pub $RSA_PUB_KEY_URL
cat nagios_rsa_key.pub >> $NAGIOS_USER_HOME/.ssh/authorized_keys
rm nagios_rsa_key.pub

# Creation of the bin dir where the nagios server iexpeting to find the check scripts
mkdir $BIN_DIR
chown nagios:nagios $BIN_DIR

# Installation of the System Memory check script
curl -o $BIN_DIR/check_mem.pl $THIRD_PARTY_UNPACKAGED_SCRIPTS_URL/check_mem.pl
chown nagios:nagios $BIN_DIR/check_mem.pl
chmod 755  $BIN_DIR/check_mem.pl

# linking the installed check scripts to the nagios's home/bin folder as expected by the nagios server
ln -f -s $NAGIOS_SCRIPTS_SYSTEM_DIR/check_disk $BIN_DIR/check_disk
ln -f -s $NAGIOS_SCRIPTS_SYSTEM_DIR/check_load $BIN_DIR/check_load
ln -f -s $NAGIOS_SCRIPTS_SYSTEM_DIR/check_swap $BIN_DIR/check_swap 
ln -f -s $NAGIOS_SCRIPTS_SYSTEM_DIR/check_http $BIN_DIR/check_http

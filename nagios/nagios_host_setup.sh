#!/bin/sh

RSA_PUB_KEY_URL=""
THIRD_PARTY_UNPACKAGED_SCRIPTS_URL=""
# creation of a nagios user on each server
adduser nagios --disabled-password
mkdir /home/nagios/.ssh
touch /home/nagios/.ssh/authorized_keys
chown -R nagios:nagios /home/nagios/.ssh
chmod -R go-rwx /home/nagios/.ssh

# install the SSH2 RSA Public key of the nagios user of the nagios/icinga server
curl -o rsa_kye.pub $RSA_PUB_KEY_URL
cat rsa_kye.pub >> /home/nagios/.ssh/authorized_keys

# for Centos 5.x
# adding the remi and epel repos to have the nagios packages available
curl -o pel-release-5-4.noarch.rpm http://dl.fedoraproject.org/pub/epel/5/x86_64/epel-release-5-4.noarch.rpm
curl -o remi-release-5.rpm http://rpms.famillecollet.com/enterprise/remi-release-5.rpm
sudo rpm -Uvh pel-release-5-4.noarch.rpm remi-release-5.rpm 

# Installation of nagios checks scripts and necassary libraries
yum install nagios-plugins nagios-common  nagios-plugins-http nagios-plugins-load nagios-plugins-disk nagios-plugins-swap

# Creation of the bin dir where the nagios server iexpeting to find the check scripts
mkdir /home/nagios/bin
chown nagios:nagios /home/nagios/bin

# Installation of the System Memory check script
curl -o /home/nagios/bin/check_mem.pl $THIRD_PARTY_UNPACKAGED_SCRIPTS_URL/check_mem.pl
chown nagios:nagios /home/nagios/bin/check_mem.pl
chmod 750  /home/nagios/bin/check_mem.pl

# linking the installed check scripts to the nagios's home/bin folder as expected by the nagios server
ln -f -s /usr/lib64/nagios/plugins/check_disk /home/nagios/bin/check_disk
ln -f -s /usr/lib64/nagios/plugins/check_load /home/nagios/bin/check_load
ln -f -s /usr/lib64/nagios/plugins/check_swap /home/nagios/bin/check_swap 
ln -f -s /usr/lib64/nagios/plugins/check_http /home/nagios/bin/check_http

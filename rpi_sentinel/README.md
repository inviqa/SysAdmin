#Description
rpi_sentinel is a collection of script and instructions intended to build an Icinga server on a RaspberryPi micro computer.

Potentially it could be run as a wallboard running a full-screen browser in kiosk-mode that will automatically load a webpage showing the desired content via NagVis, without any user interatction after turning on the RPi.
#Features
- Icinga server
- Chromium in full screenmode (allowing the automatic login via Google federated login). 
- NagVis Wallboard
- The RPi is reacheable via Bonjour (ZeroConf) protocol naming (.local)
- Remote SSH connection
- Multi (shared) VNC screen sharing
- Automatic Shutdown (best accompanied by a mains timer socket to turn it on periodically)

#VNC connection
By defaul the RPi is accessible via VNC in Multi/Shared ViewOnly mode, with NO PASSWORD at the address 'sentinel.local' or 'vnc://sentinel.local' (for Safari)

#SSH connection
By defaul the RPi is accessible via SSH on the local network using the address 'sentinel.local'
user: pi
password: raspberry (which must be personalised)

#How-To build a Raspberry Pi Sentinel
This instructions are for Mac OSX but can be easily adapted to be run on a Linux host.

##Install the latest Raspbian

```bash
# Download the official installation image
curl --progress-bar -o 2014-01-07-wheezy-raspbian.zip http://director.downloads.raspberrypi.org/raspbian/images/raspbian-2014-01-09/2014-01-07-wheezy-raspbian.zip

# unzip the raspbian image in your working directory
unzip  2014-01-07-wheezy-raspbian.zip
```
Insert the SD card in the SD read of your computer.
```bash
# Run ‘diskutil’ from command-line to learn what is the device name of the SD card (which we assume is ‘/dev/disk1’) and it’s partitions.
diskutil list

# Unmount all the possibly mounted partitions of /dev/disk# (mind that the disk won’t be ejected)
diskutil unmountDisk /dev/disk1

# Dump the raspbian image into the SD card which for which we will use the RAW interface ‘/dev/rdisk1’ so that the dump will be quite fast

sudo dd if=2014-01-07-wheezy-raspbian.img of=/dev/rdisk1 bs=1m
```

```
You can monitor the dumping progress via Activity Monitor (on a Mac), filtering for the dd process.
```
* Copy the config.txt in the SD card BOOT partition.
* Copy the xinitrc in the SD card BOOT partition.
* Copy the wallboard_setup.sh script in the SD card BOOT partition.

Gacefully unmount the SD card, then plug it into the RPi and turn the RPi on with a keyboard, mouse and screen connected (we need the keyboard & mouse just for the first run).


##First Run: Log into the RPi
Log into the RPi with the user ‘pi' and the password ‘raspberry’ and run the /boot/sentinel_setup.sh script 'root' or with sudo.

After running the /sentinel_setup.sh you need to restart the RPi.
Use a USB mouse and a keyboard connected to the RPI to operate it.
When restarted, if all went through without issues, it will appear the Federated Login page, at this stage:
1. Press the 'F1' stroke in the keyboard to show a fully framed window of Chromium.
2. Click on the menu button (top right of the screen)
3. Click the 'Sign in to Chromium...' option
4. Enter the 'robot' user credentials (DON'T USE YOUR PERSONAL CREDENTIALS)
5. 

#Backup: Create a restorable image
##Deduce the total size of backupimage
Mount the the SD card on the computer (in our case a Mac)

Get the size of the boot partiotn in bytes
```
# get Gthe size of the boot partiotn in bytes
diskutil info /dev/disk1s1|grep "Total Size"|cut -f2 -d'(' |cut -f1 -d")"
# i.e. 58720256 Bytes

# get Gthe size of the root partiotn in bytes
diskutil info /dev/disk1s2|grep "Total Size"|cut -f2 -d'(' |cut -f1 -d")"
# i.e. 2899312640 Bytes
```
Sum these two value and divide it by 1048576 (1024 * 1024) to know how many MB of space they are using:
```
**58720256 + 2899312640 = 2958032896 Bytes / 1024 / 1024 = 2821 MB**
```

##Create the backup image
Unmount the all the SD partition without ejecting the device
```
diskutil unmountDisk /dev/disk1
```
Start the dumping with 'dd'
```
# bs=1m define the blocksize of 1MB
# count=2900 defines the number of blocks to copy
# to avoid corrupting the filesystem it's better to round up the count so 2821MB is rounded to 2900 blocks

sudo dd of=rpi_wallboard.img if=/dev/rdisk1 bs=1m count=2900
```

#Restore from a backup image
```
sudo dd if=rpi_wallboard.img of=/dev/rdisk1 bs=1m
```

#TODO
* automate installation of config.txt
* move rc_local.patch to /boot
* before downloading the files from git make sure that they are not already in the current directory (or in boot)

#License and Author
Copyright (C) 2012 - 2013 Inviqa UK Ltd

Author: Marco Massari Calderone (mmassari@inviqa.com)
Other author may be collaborating at the development of the various scripsts and tools.

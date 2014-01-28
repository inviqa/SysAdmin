#Description
rpi_wallboard is a collection of script and instructions intended to build a wallboard on a RaspberryPi micro computer.
The Wallboard is nothing else than a full-screen browser in kiosk-mode that will automatically load a webpage showing the desired content, withut any user interatction after turning on the RPi.

In this specific case, for Inviqa, the Wallboard is preconfigured to login and show the Builds Wallboard provided by Jenkins Wall Display plugin.

#Features
- Chromium in full screenmode (allowing the automatic login via Google federated login). 
- Jenkings Builds wallboard.
- The RPi is reacheable via Bonjour (ZeroConf) protocol naming (.local)
- Remote SSH connection
- Multi (shared) VNC screen sharing
- Automatic Shutdown (best accompanied by a mains timer socket to turn it on periodically)

#Setup from a Mac
This instructions can be easily adapted to be run on a Linux host.


Install the latest Raspbian
Download the official installation image
~$ curl --progress-bar -o 2014-01-07-wheezy-raspbian.zip http://director.downloads.raspberrypi.org/raspbian/images/raspbian-2014-01-09/2014-01-07-wheezy-raspbian.zip

unzip the raspbian image in your working directory
unzip  2014-01-07-wheezy-raspbian.zip

Insert the SD card in the SD read of your computer.
Run ‘diskutil’ from command-line to learn what is the device name of the SD card (which we assume is ‘/dev/disk1’) and it’s partitions.
~$ diskutil —list

Unmount all the possibly mounted partitions of /dev/disk# (mind that the disk won’t be ejected)
~$ diskutil unmountDisk /dev/disk1

Dump the raspbian image into the SD card which for which we will use the RAW interface ‘/dev/rdisk1’ so that the dump will be quite fast

~$ sudo dd if=2014-01-07-wheezy-raspbian.img of=/dev/rdisk1 bs=2048k
You can monitor the dumping progress via Activity Monitor (on a Mac), filtering for the dd process.

When the copying process is finished, before plugging the SD card into the RPi, open the ‘config.txt’ file that is placed in the BOOT partition of the newly imaged SD card, and make sure that it contains the following settings:

disable_overscan=1
framebuffer_depth=32
framebuffer_ignore_alpha=1
hdmi_pixel_encoding=1
hdmi_force_hotplug=1
config_hdmi_boost=4
disable_overscan=1
arm_freq=900

core_freq=250
sdram_freq=450
over_voltage=2
gpu_mem=32

 #for more options see http://elinux.org/RPi_config.txt

save the file, and gracefully unmount the SD card, then plug it into the RPi and turn the RPi on with a keyboard and screen connected.

#Usage
After following the Setup instructins, turn on the RPi, log into it, then run the wallboard_setup.sh script as 'root' or with sudo.
The rester the RPi.

#License and Author
Copyright (C) 2012 - 2013 Inviqa UK Ltd

Author: Marco Massari Calderone (mmassari@inviqa.com)
Other author may be collaborating at the development of the various scripsts and tools.

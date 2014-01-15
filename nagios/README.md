#Description
nagios_host_setup.sh is a bash script that will set up the basic requirements for nagios montiron on a host server that we want to monitor.
IT IS NOT A SCRIPT FOR A NAGIOS SERVER SETUP
- it creates the user
- upload the nagios server user RESA Public Key
- Installs the basic nagios plugins and dependant libraries

#Requirements
The script is ment to run on Centos 5.x
requires curl for the download of some script

#Usage
It's advised to place the script in the /tmp folder

#TODO
- add the autodetection of the Centos version or Debian based distributiions

#License and Author
The scripts contained in third-party directory belong to the author cited in the script themselves.

All the other scripts are copyrighted as follows
Author: Marco Massari Calderone (mmassari@inviqa.com)

Copyright (C) 2013 Inviqa UK Ltd

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see http://www.gnu.org/licenses/.


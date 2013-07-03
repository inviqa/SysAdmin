#Description
gh_keys_importer is a bash script that given a list of OpenLDAP users list that have a matching account in GitHub, fetches and imports in the LDAP database the Public RSA keys stored in GitHub for each matching user.

#Requirements
The 'openldap-cli' and 'curl' tools need to be installed in order for the script to work.

#Usage
It's advised to place the script in a common path i.e. /usr/bin.
When executed the script do not need any command-line parameter as it sources them from and the .ghkiinfo

#TODO
- Add the possibility to define command-line parameters to override/ignore the informatiddon in the .ghkiinfo file
- Add the '-v' (--version) parameter
- Add the '-h' (--help) parameter that shows the list of parameters and the usage examples

#License and Author
Author: Marco Massari Calderone (mmassari@inviqa.com)

Copyright (C) 2013 Inviqa UK Ltd

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see http://www.gnu.org/licenses/.


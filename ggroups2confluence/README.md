#Description
ggroups2confluence is a bash script that fetch the full list of the Google Groups and their memebers from your Google Apps account and publish it to a JIRA Confluence page of your JIRA server via the 'webdav' protocol.

#Requirements
##Permissions
Use an admin user which has at least
`G Suite system role (built-in role): _"Groups Admin"_`

when runing the `install-gam` script and creating the oauth credentials make sure to select at least (or just)

`> gam oauth create`

```
Select the authorized scopes by entering a number.
Append an 'r' to grant read-only access or an 'a' to grant action-only access.
....
[*]  6)  Directory API - Groups (supports readonly)
...
...
[*] 16)  Group Settings API
...
```

##GAM
Instal gam version 4.x.

This script requires GAM (Google Apps Manager - https://github.com/jay0lee/GAM/tree/master)

make sure that the `config files` are present at `/root/bn/gam
/root/bin/gam/nobrowser.txt
/root/bin/gam/noupdatecheck.txt
/root/bin/gam/oauth2.txt
/root/bin/gam/oauth2service.json
/root/bin/gam/client_secrets.json

```
# download the GAM installer
curl -s -S -L https://git.io/install-gam > install-gam
# make sure that the file executable
chmod 750 install-gam
# run the GAM installer to only update the current installation of GAM
install-gam -p false -d /root/bin/gam -l
# As last run the script to regenerate this page
/usr/bin/ggroups2confluence.sh
```
The 'cadaver' tool needs to be installed in order for the script to work.
'cadaver' needs a .netrc file with WebDav's authentication information to be placed on the user's home folder.

ggroups2confluence requires a .gginfo file to be placed in path reachable by the user that will execute the script i.e. the homefolder, and its path need to defined in the ggroups2confluence script (~/.gginfo by default)

#Usage
It's advised to place the script in a common path i.e. /usr/bin.
The best use of the script is to execute it periodically via a 'cron' script
When executed the script do not need any command-line parameter as it sources them from the .netrc and the .gginfo

#TODO
- Add the possibility to define command-line parameters to override/ignore the information in the .gginfo file
- Add the possibility to define command-line parameters to override/ignore the information in the .netrc file
- Add the '-v' (--version) parameter
- Add the '-h' (--help) parameter that shows the list of parameters and the usage examples

#License and Author
Author: Marco Massari Calderone (mmassari@inviqa.com)

Copyright (C) 2012 Inviqa UK Ltd

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see http://www.gnu.org/licenses/.

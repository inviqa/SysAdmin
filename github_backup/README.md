#Description
'github_repos_list' is a BASH script that retrieves the list of Git repositories present at a give github.com account.

'github_backup' is a BASH script that performs a check-out of all the Git repositories present at a give github.com account.

It etrives the list of all the repositories present on the github.com account and then is able to perform the backu
p of all the new repositories created since the last backup, with no need to update the script when repositories are added or removed. 

The checked-out directories are then compressed in tar.gz archives and stored in a designated backup folder.
 
Only one copy of the archive is kept for each repository because the nature of the git repository, already provides means to retrived older versions of the files managed on the git repository (via the use of standard git commands).

#Installation
Place the scripts in a common path i.e. "/usr/bin" or any bin path available to the user that will execute them.

#Requirements
'github_backup' requires a .github_info file to be placed in path reachable by the user that will execute the script i.e. the homefolder, and its path need to defined in the github_backup script (~/.github_info by default)

'.github_info' must contain the following information:
- USERNAME="<username>"
- PASSWORD="<password>"
- ORGANIZATION="<organisation>"
 
Protect the GitHub login information:
- storing the file in the home folder of the user(s) that will execute the script
- defining the ownershit of '.github_info' to <user>:<user>
- defining the permissions of '.github_info' to 600

#Usage
The best use of the script is to execute it periodically via a 'cron' script

'github_backup' requires one command-line parameter that defines the path where to store the backup
i.e. "/path/to/the/github/backup/folder/"

#Example
github_backup "/path/to/the/github/backup/folder/"


#License and Author
Authors:
Marco De Bortoli (mdebortoli@inviqa.com)
Marco Massari Calderone (mmassari@inviqa.com)

Copyright (C) 2012 Inviqa UK Ltd

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see http://www.gnu.org/licenses/.


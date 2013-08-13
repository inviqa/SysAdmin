#!/bin/bash
#
###############################################################################
# gh2confluence is a bash script that, given a list of usernames picked from 
# a LDAP database, retrieves the Full Name from LDAP and the RSA Public Keys 
# and publish it to a JIRA Confluence page of your JIRA server via the 'webdav' protocol.
# it also may show the team membership of each user
###############################################################################
#
###############################################################################
# Author: Marco Massari Calderone <mmassari@inviqa.com>
#
# Copyright (C) 2013 Inviqa UK Ltd
#
# This program is free software: you can redistribute it and/or modify it under the terms
# of the GNU General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with this program.
# If not, see http://www.gnu.org/licenses/.
#
###############################################################################

CADAVER=`which cadaver 2>/dev/null`

WEBDAV_INFO=~/.ghinfo


if [ -f $WEBDAV_INFO ]; then
  source $WEBDAV_INFO
# '.webdav_info' must contain the following information
# WEBDAVHOST="https://xxx.webdavserver.com/wiki/plugins/servlet/confluence/default"
# PAGENAME="name_of_the_page"
# PAGEPATH="_pat_to_the_page_/$PAGENAME"
# FILENAME="$PAGENAME.txt"
# in webdav the page shows the content of a txt/html file that has the same name as the page
else
  WEBDAVHOST="" #"https://xxx.webdavserver.com/wiki/plugins/servlet/confluence/default"
  PAGENAME="name_of_the_page"
  PAGEPATH="_pat_to_the_page_/$PAGENAME"
  FILENAME="$PAGENAME.txt"
fi

#LIST_OF_GROUPS=/tmp/.raw_groups_info # must be a plain text list of Google Groups in the form group@doma.OUTPUT=$FILENAME$1 # the second paramenter must be the name of a file where the script will dump the output

OUTPUT=/tmp/$FILENAME # we will generate the txt/html file that will be uploaded to the webdav server that will be named as the webdav page
touch "$OUTPUT"
# Check to see if the 'cadaver' command is available.
if [ ! -f "${CADAVER}" ]; then
	echo "$0 - ERROR: The 'cadaver' command does not appear to be installed."
	exit
fi

# Connection to the LDAP server
# Fetch the List of Employes with a 'gecos' attribute
# (the 'gecos' attribute contains the GitHub username of each developer)
# and the 'cn' and 'sn' attributes to print the 'Full Name'


# start populating the 'page' with generic information
echo "" > "$OUTPUT" # clear the 'page'
echo "<p>This is the full list of developers employees members of the Inviqa GitHub Organisation.</p>" >> "$OUTPUT"
echo "<p><strong>For security reasons, this page is editable by the Support Team members only</strong></p>" >> "$OUTPUT"
echo "<p>For each developer is shown the GitHub account name, team membership and Public RSA Key associated to the gitHub account (reusable for other services).</p>" >> "$OUTPUT"
echo "<p>This list is generated using the script $0 on the host `hostname`</p>" >> "$OUTPUT"
echo "<p>last update on <strong><i>"`eval date`"</i></strong></p>" >> "$OUTPUT"


# Parse the array of users
# Sort the array in alphabetical order
# for each user:
# print the 'Full Name'
# print the GitHub username
# connects to Github.com
# print the list of teams the user is member of
# print all the Public RSA Keys

#while read groupname name
#do
#	echo $'\n'"<strong>$name</strong>" >> "$OUTPUT"
#        echo '<ul><li>' >> "$OUTPUT"
#	echo "<a href=\"mailto:$groupname\">$groupname</a>" >> "$OUTPUT"
#	eval $PYTHON $GAM info group $groupname | grep Member | cut -f1,2 -d" " | sed -e 's/^/<\/li><li>/g' >> "$OUTPUT"
#	echo '</li></ul>' >> "$OUTPUT"

#done < $LIST_OF_GROUPS
echo "<p>last update on <strong><i>"`eval date`"</i></strong></p>" >> "$OUTPUT"

# close the popluation of the 'page'
IFS=$OLDIFS


if [ -f "${OUTPUT}" ]; then
	# Run the 'cadaver' command, upload files from the tmp file
	${CADAVER} >/dev/null << EOF
        open $WEBDAVHOST
        cd "$PAGEPATH"   
        put "$OUTPUT"
EOF

	# remove the tmp files
	rm "${OUTPUT}"
        #rm "$LIST_OF_GROUPS"
else
	echo "$0 - ERROR: Unable to find the file \'${OUTPUT}\'"
fi

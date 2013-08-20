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

CURL=$(which curl);
SED=$(which sed);
TR=$(which tr);
LDAPMODIFY=$(which ldapmodify);
CADAVER=$(which cadaver);
WEBDAV_INFO=~/.ghinfo
LDAP_INFO=~/.ghki_info

LOG_FILE=/var/log/gh2confluence.log
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

if [ -f $LDAP_INFO ]; then
    source $LDAP_INFO
    # '.ghki_info' must contain the following information
    # protect the login information:
    # - storing the file in the home folder of the user(s) that will execute the script
    # - defining the ownershit of '.ghki_info' to <user>:<user>
    # - defining the permissions of '.ghki_info' to 600
    #
    # URI="ldap://some.thing.com"
    # BASE="dc=thing,dc=com"
    # BINDDN="cn=admin,dc=thing,dc=com"
    # BINDPW="P4$$w0rd"
    # OBJECT_CLASS="inetOrgPerson"
    #
    # USERNAME="<username>"
    # PASSWORD="<password>"
    # ORGANIZATION="<organisation>"
    # 
else
    URI=""
    BASE=""
    BINDDN=""
    BINDPW=""
    OBJECT_CLASS=""
    USERNAME=""
    PASSWORD=""
    ORGANIZATION=""
fi

OUTPUT=/tmp/$FILENAME # we will generate the txt/html file that will be uploaded to the webdav server that will be named as the webdav page
touch "$OUTPUT"

# Check to see if the 'cadaver' command is available.
if [ ! -f "${CADAVER}" ]; then
	echo "$0 - ERROR: The 'cadaver' command does not appear to be installed."
	exit
fi

function ldap_users_list(){
OPTIONS=""
# 'ldapsearch' will return only the users with a 'gecos' attribute set (which is containing the github username)

#case "$SSL" in
#    start_tls)
#       case "$tls_checkpeer" in
#           no) OPTIONS+="-Z";;
#           *) OPTIONS+="-ZZ";;
#       esac;;
#esac

# '$SED' will group 3 lines at a time and make a single line for each account returned by 'ldapsearch' and will strip it from the attribute name
ldapsearch $OPTIONS -L -L -L -H ${URI} -w ${BINDPW} -D ${BINDDN} \
            -b ${BASE} \
            '(&(objectClass='${OBJECT_CLASS}')(!(gecos=''))(gecos=*))' \
            'sn' 'uid' 'gecos' 'cn' -S 'uid' \
            | $SED -n '/^$/d;{N;N;N;N;N;s/\n/;/g};p;'
            #| $SED -n '/^$/d;{N;N;N;N;N;s/\n/;/g};s/dn: //g;s/uid: //g;s/sn: //g;s/cn: //g;s/gecos: //gp;'
}

function is_a_org_member(){
# given a 'username' the function verify if the user exists in  the Company's Organisation in GitHub.
# This is a security mesure to avoid to update the Public Keys for developers that do NOT work anymore for the company
  MEMBER_LOGIN="$1"
  MEMBERSHIP_CODE=`eval $CURL -o /dev/null -I -s -w "%{http_code}" -u \"$USERNAME:$PASSWORD\" https://api.github.com/orgs/$ORGANIZATION/members/$MEMBER_LOGIN 2>> "$LOG_FILE"`
  if [ "$MEMBERSHIP_CODE" = "204" ]; then
    # is a member
    return 0;
  else
    # is not a member
    return 1; 
  fi
}

function get_public_keys(){
# Returns a string of elements separated by a 'new line' 
# When reading the output of this function you need to set "IFS=$'\x0a'" 
# to allow elements to contain 'white spaces' like 'ssh-rsa 987asdawsd....'

# Given a GitHub login id the functions retrieves the public keys stored in GH for that account
  MEMBER_LOGIN="$1"
  GITHUB_URL="$CURL -s -u \"$USERNAME:$PASSWORD\" https://api.github.com/users/$MEMBER_LOGIN/keys 2>> $LOG_FILE"
  
  # Creates an array of public key retrieved from the GitHub user's public profile
  eval $GITHUB_URL | grep "\"key\""| cut -f4 -d'"'
}

# start populating the 'page' with generic information
echo "" > "$OUTPUT" # clear the 'page'
echo "<p>This is the full list of developers employees members of the Inviqa GitHub Organisation.</p>" >> "$OUTPUT"
echo "<p><strong>For security reasons, this page is editable by the Support Team members only</strong></p>" >> "$OUTPUT"
echo "<p>For each developer is shown the GitHub account name, team membership and Public RSA Key associated to the gitHub account (reusable for other services).</p>" >> "$OUTPUT"
echo "<p>This list is generated using the script $0 on the host `hostname`</p>" >> "$OUTPUT"
echo "<p>last update on <strong><i>"`eval date`"</i></strong></p>" >> "$OUTPUT"

 # set the LIST SEPARATOR to the HEX code for a 'new line' to allow the
 # correct handeling of the 'white space' that could be present in the 'sn' ldap attribute (or any other attribute
IFS=$'\x0a'

# Fetch from the LDAP dabatase the List of Employes (in alphabetical order)
# with a 'gecos' attribute
# (the 'gecos' attribute contains the GitHub username of each developer)
# and the 'cn' and 'sn' attributes to print the 'Full Name'
# Sort the array in alphabetical order
for LDAP_ACCOUNT in `ldap_users_list`
# For each username:
do
   # reset the LIST SEPARATOR to the system default value (usually a 'white space')
  # 1 - fetch the dn,uid and gecos
  # create an array from each element of 'LDAP_ACCOUNT'
  echo $LDAP_ACCOUNT >> "$LOG_FILE"
  #USER_DN=`echo $LDAP_ACCOUNT | cut -d\; -f1`
  USER_ID=`echo $LDAP_ACCOUNT | sed -n 's/.*uid: //g;s/\;.*//gp'`
  USER_CN=`echo $LDAP_ACCOUNT | sed -n 's/.*cn: //g;s/\;.*//gp'`
  USER_SN=`echo $LDAP_ACCOUNT | sed -n 's/.*sn: //g;s/\;.*//gp'`
  USER_GECOS=`echo $LDAP_ACCOUNT | sed -n 's/.*gecos: //g;s/\;.*//gp'`
  
  echo $USER_ID" - "$USER_GECOS >> "$LOG_FILE"
  # 2 - look for a match with the gecos attribute in the GitHub Organisation members
  if is_a_org_member $USER_GECOS; then
    # # If a match is found
    # connects to Github.com and retrives the pub keys
    USER_PUB_KEYS=`get_public_keys $USER_GECOS ` 
    echo $'\n'"<p>" >> "$OUTPUT"
    # print the 'Full Name' and the GitHub username
    echo "<i>$USER_CN $USER_SN</i> - <strong>$USER_GECOS</strong>" >> "$OUTPUT"
# print the list of teams the user is member of
    # print all the Public RSA Keys
    echo '<div>' >> "$OUTPUT"
    for KEY in ${USER_PUB_KEYS[@]}
    do
      # 3 - Save the Public RSA Keyin LDAP
      echo '<div>'$KEY'</div>'  >> "$OUTPUT"
    done
#	echo "<a href=\"mailto:$groupname\">$groupname</a>" >> "$OUTPUT"
    echo '</div>' >> "$OUTPUT"
    echo "</p>" >> "$OUTPUT"
  else
    echo "Is not member of the Organisation" >> "$LOG_FILE"
  fi
done
# reset the LIST SEPARATOR to the system default value (usually a 'white space')
unset IFS

echo "<p>last update on <strong><i>"`eval date`"</i></strong></p>" >> "$OUTPUT"
# close the popluation of the 'page'

if [ -f "${OUTPUT}" ]; then
	# Run the 'cadaver' command, upload files from the tmp file
	${CADAVER} >/dev/null << EOF
        open $WEBDAVHOST
        cd "$PAGEPATH"   
        put "$OUTPUT"
EOF

	# remove the tmp files
	#rm "${OUTPUT}"
else
	echo "$0 - ERROR: Unable to find the file \'${OUTPUT}\'"
fi

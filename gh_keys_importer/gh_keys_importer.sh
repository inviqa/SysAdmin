#!/bin/bash

# Source the GitHub connection details from .github_info file
#
CURL=$(which curl);
SED=$(which sed);
TR=$(which tr);
LDAPMODIFY=$(which ldapmodify);

ME=gh_keys_importer
LOG_FILE=/var/log/$ME.log
PARAMETERS_INFO=~/.ghki_info

if [ -f $PARAMETERS_INFO ]; then
    source $PARAMETERS_INFO
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

ORG_MEMBERS_LIST="$CURL -u \"$USERNAME:$PASSWORD\" https://api.github.com/orgs/$ORGANIZATION/members 2>> $LOG_FILE"

function ldap_users_list(){
# output
# ..
# uid=cjhamilton,ou=employees,dc=inviqa,dc=com;cjhamilton;cjhamilton-inviqa
# uid=mmassari,ou=employees,dc=inviqa,dc=com;mmassari;marcomc
# ...
#
#OPTIONS=
#case "$SSL" in
#    start_tls)
#       case "$tls_checkpeer" in
#           no) OPTIONS+="-Z";;
#           *) OPTIONS+="-ZZ";;
#       esac;;
#esac

# 'ldapsearch' will return only the users with a 'gecos' attribute set (which is containing the github username)
# '$SED' will group 3 lines at a time and make a single line for each account returned by 'ldapsearch' and will strip it from the attribute name
ldapsearch $OPTIONS -L -L -L -H ${URI} -w ${BINDPW} -D ${BINDDN} \
            -b ${BASE} \
            '(&(objectClass='${OBJECT_CLASS}')(gecos=*))' \
            'uid' 'gecos' \
            | $SED -n '/^$/d;{N;N;N;s/\n//g};s/dn: //g;s/uid: /;/g;s/gecos: /;/gp;'
}


function get_public_keys(){
# Returns a string of elements separated by a 'new line' 
# When reading the output of this function you need to set "IFS=$'\x0a'" 
# to allow elements to contain 'white spaces' like 'ssh-rsa 987asdawsd....'

# Given a GitHub login id the functions retrieves the public keys stored in GH for that account
  MEMBER_LOGIN="$1"
  GITHUB_URL="$CURL  https://api.github.com/users/$MEMBER_LOGIN/keys 2>> $LOG_FILE"
  
  # Creates an array of public key retrieved from the GitHub user's public profile
  eval $GITHUB_URL | grep "\"key\""| cut -f4 -d'"'
}

function reset_public_keys(){
  return 0
}

function upload_public_key(){
local DN=$1
local KEY=$2

# This is the actual command that upload the key in the LDAP user's profile
ldapmodify -H $URI -c -x -D $BINDDN -w $BINDPW 2>&1 >> $LOG_FILE << EOF
dn: $DN
changetype: modify
add: sshPublicKey
sshPublicKey: $KEY
EOF

  return 0
}


function is_a_org_member(){
# given a 'username' the function verify if the user exists in  the Company's Organisation in GitHub.
# This is a security mesure to avoid to update the Public Keys for developers that do NOT work anymore for the company
  MEMBER_LOGIN="$1"
  MEMBERSHIP_CODE=`eval $CURL -o $LOG_FILE -I -s -w "%{http_code}" -u \"$USERNAME:$PASSWORD\" https://api.github.com/orgs/$ORGANIZATION/members/$MEMBER_LOGIN`
  if [ "$MEMBERSHIP_CODE" = "204" ]; then
    # is a member
    return 0;
  else
    # is not a member
    return 1; 
  fi
}

# reset the log file
echo ""> $LOG_FILE

for LDAP_ACCOUNT in `ldap_users_list`
# For each username:
do
  # 1 - fetch the dn,uid and gecos
  # create an array from each element of 'LDAP_ACCOUNT'
  USER_ATTRIBUTE=( $( echo $LDAP_ACCOUNT| $TR ";" " ") )
  USER_DN=${USER_ATTRIBUTE[0]}
  USER_ID=${USER_ATTRIBUTE[1]}
  USER_GECOS=${USER_ATTRIBUTE[2]}
  
  # 2 - look for a match with the gecos attribute in the GitHub Organisation members
  if is_a_org_member $USER_GECOS; then
    # # If a match is found
    # # 1 - delete the current RSA keys from the LDAP database
    reset_public_keys $USER_ID;

    # # 2 - then fetches all the Public RSA Keys stored in GitHub for the user
    # this will be treated as an array which elements are separated by 'new lines'
    
    IFS=$'\x0a'
    
    USER_PUB_KEYS=`get_public_keys $USER_GECOS` 
    # set the LIST SEPARATOR to the HEX code for a 'new line'
    for KEY in ${USER_PUB_KEYS[@]}
    do
      # 3 - Save the Public RSA Keyin LDAP
      upload_public_key $USER_DN $KEY  2&>1 >> $LOG_FILE
    done

    # reset the LIST SEPARATOR to the system default value (usually a 'white space')
    unset IFS
  fi    
done

#!/bin/bash

# Source the GitHub connection details from .github_info file
#
ME=gh_keys_importer
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
# 'sed' will make a single line for each account returned by 'ldapsearch' and will strip it from the attribute name
ldapsearch $OPTIONS -L -L -L -H ${URI} -w ${BINDPW} -D ${BINDDN} \
            -b ${BASE} \
            '(&(objectClass='${OBJECT_CLASS}')(gecos=*))' \
            'uid' 'gecos' \
            | sed -n '/^$/d;{N;N;N;s/\n//g};s/dn: //g;s/uid: /;/g;s/gecos: /;/gp;'
}

for LDAP_ACCOUNT in `ldap_users_list`
do
echo $LDAP_ACCOUNT;
# For each username:
# 1 - fetch the gecos
# 2 - look for a match with the gecos attribute in the GitHub Organisation members
# # If a match is found
# # 1 - delete the current RSA keys
# # 2 - then fetches all the Public RSA Keys stored in GitHub for the user
# # 3 - Save the Public RSA Key in LDAP





#    if [ -f $FOLDER/$i  ]; then
#      USERNAME=`echo "$i" | cut -d'.' -f1`
#      PUBLIC_KEY=`cat $FOLDER/$i`
#    fi
done

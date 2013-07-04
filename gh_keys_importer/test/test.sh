#!/bin/sh
USERNAME="inviqa-session"
PASSWORD="sHzL1D8X"
ORGANIZATION="INVIQA"

USER_NAME=$1
USER_PUB_KEYS=""

function get_public_keys(){
# Returns a string of elements separated by a 'new line' 
# When reading the output of this function you need to set "IFS=$'\x0a'" 
# to allow elements to contain 'white spaces' like 'ssh-rsa 987asdawsd....'

# Given a GitHub login id the functions retrieves the public keys stored in GH for that account
  MEMBER_LOGIN="$1"
  GITHUB_URL="curl  https://api.github.com/users/$MEMBER_LOGIN/keys 2> /dev/null"
  
  # Creates an array of public key retrieved from the GitHub user's public profile
  eval $GITHUB_URL | grep "\"key\""| cut -f4 -d'"'
}

function is_a_org_member(){
# given a 'username' the function verify if the user exists in  the Company's Organisation in GitHub.
# This is a security mesure to avoid to update the Public Keys for developers that do NOT work anymore for the company
  MEMBER_LOGIN="$1"
  MEMBERSHIP_CODE=`eval curl -o /dev/null -I -s -w "%{http_code}" -u \"$USERNAME:$PASSWORD\" https://api.github.com/orgs/$ORGANIZATION/members/$MEMBER_LOGIN`
  if [ "$MEMBERSHIP_CODE" = "204" ]; then
    # is a member
    return 0;
  else
    # is not a member
    return 1; 
  fi
}
#is_a_org_member $USER_NAME

if is_a_org_member $USER_NAME; then
  USER_PUB_KEYS=`get_public_keys $USER_NAME`
  
  # set the LIST SEPARATOR to the HEX code for a 'new line'
  IFS=$'\x0a'
  for i in ${USER_PUB_KEYS[@]}
  do
    echo $i
  done
  # reset the LIST SEPARATOR to the system default value (usually a 'white space')
  unset IFS
else
  echo no;
fi

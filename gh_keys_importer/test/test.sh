#!/bin/sh
USERNAME="inviqa-session"
PASSWORD="sHzL1D8X"
ORGANIZATION="INVIQA"

function get_public_keys () {
  MEMBER_LOGIN="$1"
  MEMBER_KEYS="curl  https://api.github.com/users/$MEMBER_LOGIN/keys 2> /dev/null"
  KEYS_FOUND=($(eval $MEMBER_KEYS | grep "\"key\"" | sed 's/\"key\":/ /g'))
  echo ${KEYS_FOUND[0]}
}

function search_for_member () {
  MEMBER_LOGIN="$1"
ORG_MEMBERS_LIST="curl -u \"$USERNAME:$PASSWORD\" https://api.github.com/orgs/$ORGANIZATION/members 2> /dev/null"
  MEMBER_FOUND=($(eval $ORG_MEMBERS_LIST | grep "\"$MEMBER_LOGIN\"" | grep "\"login\""| cut -f4 -d '"'))
  if [ "$MEMBER_FOUND" = "$MEMBER_LOGIN" ]; then
    echo $MEMBER_FOUND
  else
    return 0; 
  fi
}

MEMBER=`search_for_member $1`
echo $MEMBER
KEYS=`get_public_keys $MEMBER`
echo $KEYS

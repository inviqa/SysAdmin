#!/bin/bash

# get configuration from /etc/ldap/ldap.conf
#for x in $(sed -n 's/^\([a-zA-Z_]*\) \(.*\)$/\1="\2"/p' /etc/ldap/ldap.conf); do
#    eval $x;
#done

PARAMETERS_INFO=~/.ldul_info


if [ -f $PARAMETERS_INFO ]; then
    source $PARAMETERS_INFO
    # '.ghkiinfo' must contain the following information
    # URI="ldap://some.thing.com"
    # BASE="dc=thing,dc=com"
    # BINDDN="cn=admin,dc=thing,dc=com"
    # BINDPW="P4$$w0rd"
    # OBJECT_CLASS="inetOrgPerson"
  else
      URI=""
        BASE=""
          BINDDN=""
            BINDPW=""
              OBJECT_CLASS=""
            fi


            #OPTIONS=
            #case "$SSL" in
            #    start_tls)
            #       case "$tls_checkpeer" in
            #           no) OPTIONS+="-Z";;
          #           *) OPTIONS+="-ZZ";;
          #       esac;;
          #esac

          ldapsearch $OPTIONS -H ${URI} -w ${BINDPW} -D ${BINDDN} \
                -b ${BASE} \
                    '(&(objectClass='${OBJECT_CLASS}'))' \
                    'uid' \
                    | sed -n '/^ /{H;d};/sshPublicKey:/x;$g;s/\n *//g;s/uid: //gp'

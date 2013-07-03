#!/bin/bash

# Source the GitHub connection details from .info file
# Get the list of OpenLDAP users using ldap_users_list.sh
# For each username look for a match with the gecos attribute, in the GitHub Organisation members
# If a match is found
# 1 - delete the current RSA keys
# 2 - then fetches all the Public RSA Keys stored in GitHub for the user
# 3 - Save the Public RSA Key in LDAP
# 
#
#
#
#

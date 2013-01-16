#!/usr/bin/python
# We require the srvrmgrdIO module to prepare the request and talk to servermgrd
# Command Requires 4 Arguments in this order: SERVER PORT USERID PASSWORD
# Felim Whiteley August 2008
# felimwhiteley@gmail.com
# http://www.linkedin.com/in/felimwhiteley
# Version: 0.02

import srvrmgrdIO, sys

server = sys.argv[1]
port = sys.argv[2]
webuser = sys.argv[3]
webpass = sys.argv[4]

# AFP LogFiles
# This is what the query would look like when built 
# within https://yourserver:311/
# but missing the XML header structure

#      <key>command</key>
#       <string>tailFile</string>
#       <key>identifier</key>
#       <string>errorLog</string>
#       <key>offset</key>
#       <integer>0</integer>
#       <key>amount</key>
#       <integer>10000</integer>

request = srvrmgrdIO.buildXML('tailFile', identifier='errorLog', offset='0', amount='10000')
servermgrdModule = 'servermgr_afp'

ServerDataFile = srvrmgrdIO.sendXML(servermgrdModule, request, server, port, webuser, webpass)

print ServerDataFile['tailContents']


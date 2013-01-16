#!/usr/bin/python
#
# Copyright 2008 Integral Arm - http://www.integralarm.com/
# by Felim Whiteley - http://www.linkedin.com/in/felimwhiteley
# felimwhiteley -AT- gmail [DOT] com
# Original code developed by Andre LaBranche from http://www.dreness.com/
# Version 0.6.2 - Works With Panther, Tiger and Leopard
# (Other Version may also work but have not been tested)
#
# -------------------------------------------------------------------------
#
# This is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 2.1 of
# the License, or (at your option) any later version.
#
# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this software; if not, write to the Free
# Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
# 02110-1301 USA, or see the FSF site: http://www.fsf.org.
#
# --------------------------------------------------------------------------
#
# This module provides functions for interacting with the Mac OS X Server
# 'servermgrd' backend. This is the same backend that Server Admin utilizes.
# Requires plistlib available from http://svn.python.org/projects/python/trunk/Lib/plistlib.py
# Also available in Ubuntu Hardy: http://packages.ubuntu.com/hardy/python/python-plistlib
# Or Debian: http://packages.debian.org/sid/python/python-plistlib
# Current opperation uses temp fiels stored in /tmp to allow multiple tools to use
# a status output without requerying the server unless the file is older than 5mins (299secs
# to be exact).
# You will need to use a username and password of a local admin user on the server to gain access.
# --------------------------------------------------------------------------

import os
import time
import sys
import re
import plistlib
import StringIO
import urllib
import urllib2
import base64
import pickle

# buildXML creates an xml request for a servermgrd module.
# ** command is the name of the command to put in the request
# e.g. getHistory
# ** variant is an optional parameter for that command.
# e.g. "v1+v2" Use the servermgrd web interface to
# discover these; https://your.server:311
# ** timescale defines how many data samples to return (when applicable)

def buildXML ( command, variant=None, timescale=None, identifier=None, offset=None, amount=None, state=None, name=None ) :
    request = """<?xml version="1.0" encoding="UTF-8"?>
<plist version="0.9">
<dict>
    <key>command</key>
    <string>"""
    request = request + command
    request = request + '</string>'

    if name :
        request = request + """
    <key>name</key>
    <string>"""
        request = request + name
        request = request + '</string>'

    if identifier :
        request = request + """
    <key>identifier</key>
    <string>"""
        request = request + identifier
        request = request + '</string>'

    if offset :
        request = request + """
    <key>offset</key>
    <integer>"""
        request = request + offset
        request = request + '</integer>'

    if amount :
        request = request + """
    <key>amount</key>
    <integer>"""
        request = request + amount
        request = request + '</integer>'

    if timescale not in (None, ''):
        request = request + """
    <key>timeScale</key>
    <integer>"""
        request = request + timescale
        request = request + '</integer>'

    if variant not in (None, ''):
        request = request + """
    <key>variant</key>
    <string>"""
        request = request + variant
        request = request + '</string>'

    if state not in (None, ''):
        request = request + """
    <key>state</key>
    <string>"""
        request = request + state
        request = request + '</string>'

    request = request + """
</dict>
</plist>"""
    return request

# This code enables a connection to the server via BASIC AUTH over https
# The user must be an admin on the Mac Server

def requestServerData(url, webuser = None, webpass = None):
    from urllib2 import (HTTPPasswordMgr, HTTPBasicAuthHandler, build_opener, install_opener, urlopen, HTTPError)
    password_mgr = HTTPPasswordMgr()	#WithDefaultRealm()
    password_mgr.add_password("Server Admin", url, webuser, webpass)
    handler = HTTPBasicAuthHandler(password_mgr)
    opener = build_opener(handler)
    install_opener(opener)
    request =  urllib2.Request(url)
    if webuser:
            base64string = base64.encodestring('%s:%s' % (webuser, webpass))[:-1]
            request.add_header("Authorization", "Basic %s" % base64string)
            request.add_header('WWW-Authenticate', 'Basic realm="Server Admin"')
    try:
        htmlFile = urllib2.urlopen(request) #, timeout=30)
        htmlData = htmlFile.read()
        htmlFile.close()
        # This bit identifies if it's leopard which adds extra unneeded info as a header
        if re.match("SupportsBinaryPlist", htmlData):
            xmlDump = re.split("\r\n\r\n", htmlData, 1)
            return 0, xmlDump[1]
        else:
            return 0, htmlData
    except:
        return 1, sys.exc_info()[1]

def sendXML(servermgrdModule, request, server, port, webuser, webpass):
    url = 'https://'+server+':'+port+'/commands/'+servermgrdModule+'?input='+urllib.quote(request)
    httpError, xmlresult = requestServerData(url, webuser, webpass)
    if httpError:
        logMessage(xmlresult, server, port)
        print "ERROR: Problem Contacting Server:%s" % (xmlresult)
        sys.exit(2)
    xmlFauxFile = StringIO.StringIO(xmlresult)
    return plistlib.Plist.fromFile(xmlFauxFile)

def getServerDataFilename(server, port, servermgrdModule, command):
    serverDataFile = "/tmp/%s_%s_%s_%s.dat" % (server, port, servermgrdModule, command)
    return serverDataFile

def logMessage(serverMessage, serverAddress, serverPort):
    logFileLocation = "/tmp/%s_%s.debug" % (serverAddress, serverPort)
    logFile = open( logFileLocation, "a" )
    #print "%s: %s" % (time.strftime("%Y-%m-%d %H:%M:%S"), serverMessage)
    logFile.write("%s: %s\n" % (time.strftime("%Y-%m-%d %H:%M:%S"), serverMessage))
    logFile.flush()
    logFile.close()

def buildDataFile(servermgrdModule, request, server, port, webuser, webpass, debugMode):
    now = time.time()
    request_strip = plistlib.Plist.fromFile(StringIO.StringIO(request))
    command = ""
    for item in request_strip['command'] :
            command = command + item
    ServerDataFile = getServerDataFilename(server, port, servermgrdModule, command)
    if os.path.exists(ServerDataFile) :
        if debugMode:
            serverMessage = " DEBUG: DataFile Already Exists"
            logMessage(serverMessage, server, port)
        filemodtime = os.path.getmtime(ServerDataFile)
        differance = now - filemodtime
        if differance > 300 :
            if debugMode:
                serverMessage = " DEBUG: DataFile Over 300 Seconds Old -> Getting Fresh Data"
                logMessage(serverMessage, server, port)
            createNewDataFile(ServerDataFile, servermgrdModule, request, server, port, webuser, webpass)
    else :
        if debugMode:
            serverMessage = " DEBUG: DataFile Does Not Exist -> Getting Data"
            logMessage(serverMessage, server, port)
        createNewDataFile(ServerDataFile, servermgrdModule, request, server, port, webuser, webpass)
    return ServerDataFile

def createNewDataFile ( ServerDataFile, servermgrdModule, request, server, port, webuser, webpass ) :
    DataPList = sendXML(servermgrdModule, request, server, port, webuser, webpass)
    fout = open(ServerDataFile, "wb")
    pickle.dump(DataPList, fout, 2)
    fout.close()

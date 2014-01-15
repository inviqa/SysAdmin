#!/bin/bash

# ========================================================================================
# NFS health monitor plugin for Nagios
# 
# Written by         	: Steve Bosek (steve.bosek@gmail.com)
# Release               : 1.0rc3
# Creation date		: 8 May 2009
# Revision date         : 18 May 2009
# Package               : BU Plugins
# Description           : Nagios plugin (script) to NFS health monitor (NFS server and/or client side).
#			  With this plugin you can define client or server NFS side, RPC services which must be checked,
#			  add or exclude NFS mountpoints and add or ignore file which contain the information on filesystems
#			  on Linux and AIX plateforms
#			 
#			  
#			  This script has been designed and written on Linux plateform. 
#						
# Usage                 : ./check_nfs_health.sh -i <server|client> -s <list rpc services> -a <add nfs mountpoint> -x <exclude nfs mountpoints> -f <add|ignore>
#		
#			Check NFS client-side :
#			check_nfs_health.sh -i client -s default -a none -x none -f add 
#			check_nfs_health.sh -i client -s portmapper,nlockmgr -a /backup,/nfs_share -x /mouth_share -f add
#
#			Check NFS basic client-side :
#			check_nfs_health.sh -i client -s default -a /backup,/nfs_share -x none -f ignore
#
# -----------------------------------------------------------------------------------------
#
# TODO :  		- Performance Data (client-side and server-side) : nfsd_cpu, nfsd_used_threads, io_read, io_write, ...
#			- Solaris, HP-UX, MAC OSX support
#			- My atrocious English. Help Me ! ;-D  		
#		 
#
# =========================================================================================
#
# HISTORY :
#     Release	|     Date	|    Authors		| 	Description
# --------------+---------------+-----------------------+----------------------------------
# 1.0rc1	| 12.05.2009	| Steve Bosek		| Previous version  
# 1.0rc2	| 15.05.2009	| Steve Bosek		| Add AIX Support (bash shell)
#							  Add parameter [-f <add|ignore>] to ignore the file which 
#							  contains the information on filesystems: /etc/fstab,..	 
#1.0rc3   | 19.05.2009   | Steve Bosek		| Add Solaris support (bash shell)
# =========================================================================================

# Paths to commands used in this script
PATH=$PATH:/usr/sbin:/usr/bin

# Nagios return codes
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

# Plugin variable description
PROGNAME=$(basename $0)
PROGPATH=$(echo $0 | sed -e 's,[\\/][^\\/][^\\/]*$,,')
REVISION="Revision 1.0rc3"
AUTHOR="(c) 2009 Steve Bosek (steve.bosek@gmail.com)"

# Functions plugin usage
print_revision() {
    echo "$PROGNAME $REVISION $AUTHOR"
}

print_usage() {
	echo "Usage: $PROGNAME -s <default|list NFS services> -i <client|server> -a <add nfs mountpoints> -x <exclude nfs mountpoints> -f <add|ignore>"
	echo ""
	echo "-h Show this page"
	echo "-v Script version"
	echo "-s List separate with comma of NFS dependent services. Look rpcinfo -p"
	echo "		Default NFS server-side : nfs,mountd,portmapper,nlockmgr"
	echo "		Default NFS client-side : portmapper"
	echo "-a List NFS mounts separate with comma not in /etc/fstab to add in monitoring (default : none)"
	echo "		Default : none"
	echo "-x List NFS mounts separate with comma to exclude from monitoring (default : none)"  
	echo "          Default : none"
	echo "-i NFS server or client side"
	echo "  	Default : server" 
	echo "-f add or ignore file which contains the information on filesystems (default : add"
	echo "		Default : add" 
}

print_help() {
	print_revision
	echo ""
	print_usage
        echo ""
	exit 0
}

# -----------------------------------------------------------------------------------------
# Default variable if not define in script command parameter
# -----------------------------------------------------------------------------------------
NFS_SERVER_SERVICES=${NFS_SERVER_SERVICES:="nfs mountd portmapper nlockmgr"}
NFS_CLIENT_SERVICES=${NFS_CLIENT_SERVICES:="portmapper"}
NFS_SERVICES="default"
NFS_SIDE="server"
NFS_ADD_MOUNTS="none"
NFS_EXCLUDE_MOUNTS="none"
FILESYSTEMS_FILE="add"
NFS_MOUNTS=""

# -------------------------------------------------------------------------------------
# Grab the command line arguments
# --------------------------------------------------------------------------------------
while [ $# -gt 0 ]; do
	case "$1" in
		-h | --help)
            	print_help
            	exit $STATE_OK
            	;;
        	-v | --version)
                print_revision
                exit $STATE_OK
                ;;
        	-s | --services)
                shift
                NFS_SERVICES=$1
                ;;
        	-a | --addlist)
              	shift
              	NFS_ADD_MOUNTS=$1
                ;;
		-x | --exclude)
		shift
		NFS_EXCLUDE_MOUNTS=$1
		;;
		-i | --side )
		shift
		NFS_SIDE=$1
		;;
		-f | --filesystem )
		shift
                FILESYSTEMS_FILE=$1
                ;;
		*)  echo "Unknown argument: $1"
            	print_usage
            	exit $STATE_UNKNOWN
            	;;
		esac
	shift
done


# -----------------------------------------------------------------------------------------
# Check NFS services for client-side or server-side, default mode or user define services list 
# -----------------------------------------------------------------------------------------

if [ "$NFS_SIDE" = "client" ]; then
        if [ "$NFS_SERVICES" = "default" ]; then
                NFS_SERVICES=$NFS_CLIENT_SERVICES
        else
                NFS_SERVICES=$(echo $NFS_SERVICES | sed 's/,/ /g')
        fi
else
        if [ "$NFS_SERVICES" = "default" ]; then
                NFS_SERVICES=$NFS_SERVER_SERVICES
        else
                NFS_SERVICES=$(echo $NFS_SERVICES | sed 's/,/ /g')
        fi
fi

# -----------------------------------------------------------------------------------------
# Check if NFS services are running
# -----------------------------------------------------------------------------------------

for i in ${NFS_SERVICES}; do
	NFS_SERVICES_STATUS=$(rpcinfo -p | grep -w ${i} | wc -l)
	if [ $NFS_SERVICES_STATUS -eq 0 ]; then
		FAULT_SERVICES_STATUS=($FAULT_SERVICES_STATUS $i)  
	fi 
done

if [ ${#FAULT_SERVICES_STATUS[@]} != 0 ]; then
	echo  "NFS CRITICAL : NFS services ${FAULT_SERVICES_STATUS[@]} not running (${NFS_SIDE}-side)"
 	exit $STATE_CRITICAL
fi


# -----------------------------------------------------------------------------------------
# NFS Server CPU Performance
# -----------------------------------------------------------------------------------------
#if [ "$NFS_SIDE" = "server" ]; then
#NFSD_CPU=`ps --no-heading -C nfsd -o %cpu | sed 's/.*$/v+=&;print v;print "\n"/' | bc -l | tail -n1`
#if [ $NFSD_CPU -eq 100 ]; then
#echo "NFS WARNING : Percentage of CPU consumed by nfsd exeded 100% | Nfsd_Cpu=$NFSD_CPU% "
#fi
#fi 


# -----------------------------------------------------------------------------------------
# Look NFS exports if server-side
# -----------------------------------------------------------------------------------------
if [ "$NFS_SIDE" = "server" ]; then
	NFS_EXPORTS=`showmount -e | awk '{ print $1 }' | sed "1,1d" | tr -s "\n" " "` 
	if [ -z "$NFS_EXPORTS" ]; then
		echo "NFS UNKNOWN : NFS server no export Filesystem"
		exit $STATE_UNKNOWN
	fi
	# Check exportfs
	for i in ${NFS_EXPORTS[@]}; do
        	if [ ! -d $i ]; then 
                FAULT_ARRAY=( ${FAULT_ARRAY[@]} $i )
        	fi
	done
	if [ ${#FAULT_ARRAY[@]} != 0 ]; then
        echo "NFS CRITICAL : Export ${FAULT_ARRAY[@]} directory not exist."
        exit $STATE_CRITICAL
	fi
fi

# -----------------------------------------------------------------------------------------
# Explore file which contains the information on filesystems: ${NFS_MOUNT[@]} table construction 
# -----------------------------------------------------------------------------------------
# Initial Parsing to /etc/fstab
if [ ${FILESYSTEMS_FILE} = "add" ]; then
case `uname` in
        Linux ) NFS_MOUNTS=`egrep -v '(^#)' /etc/fstab | grep nfs | awk '{print $2}'`;;
        AIX ) NFS_MOUNTS=`lsfs | grep -w nfs | awk '{print $3}'`;;
 		SunOS) NFS_MOUNTS=`cat /etc/vfstab | grep -w nfs | awk '{print $3}'`;;
	* ) echo "NFS UNKNOWN : OS `uname` not yet supported"
        exit $STATE_UNKNOWN
esac
fi

	

# Convert $NFS_ADD_MOUNTS to array and add to $NFS_FSTAB_MOUNTS list

if [ "${NFS_ADD_MOUNTS}" != "none" ];then
	TAB_ADDLIST=(`echo $NFS_ADD_MOUNTS| sed 's/,/ /g'`)
	NBR_INDEX=${#TAB_ADDLIST[@]}
  	i=0
  	ARRAY=${NFS_MOUNTS[@]}
  	while [ $i -lt ${NBR_INDEX} ]; do
    		BL_ITEM="${TAB_ADDLIST[$i]}"
    		ARRAY=`echo ${ARRAY[@]} "${BL_ITEM} "`
    		let "i += 1"
  	done
	NFS_MOUNTS=(`echo ${ARRAY[@]}`)
fi

# Convert $NFS_EXCLUDE_MOUNTS to array and exclude to array to $NFS_MOUNTS list

if [ "${NFS_EXCLUDE_MOUNTS}" != "none" ]; then
  	TAB_BLACKLIST=(`echo $NFS_EXCLUDE_MOUNTS | sed 's/,/ /g'`)
  	NBR_INDEX=${#TAB_BLACKLIST[@]}
  	i=0
   	ARRAY=${NFS_MOUNTS[@]}
  	while [ $i -lt ${NBR_INDEX} ]; do
    		BL_ITEM="${TAB_BLACKLIST[$i]}"
    		ARRAY=(`echo ${ARRAY[@]/"$BL_ITEM"/}`)
		let "i += 1"
  	done
	NFS_MOUNTS=(`echo ${ARRAY[@]}`)
fi

#NFS_MOUNTS=`mount | egrep '( nfs | nfs3 | type nfs )'  | awk '{print $3}'`

# -----------------------------------------------------------------------------------------
# Script to test NFS mountpoint 
# -----------------------------------------------------------------------------------------
cat > "/tmp/nfs_health_monitor" << EOF
#!/bin/sh
cd \$1 || { exit 2; }
exit 0;
EOF

chmod +x /tmp/nfs_health_monitor

# -----------------------------------------------------------------------------------------
# Check $NFS_MOUNTS
# -----------------------------------------------------------------------------------------

# case server-side with no NFS mountpoints
if [ -z "$NFS_MOUNTS" ] && [ "$NFS_SIDE" = "server" ]; then
        echo "NFS OK : NFS server services ${NFS_SERVICES[@]} running. No NFS mountpoint found. NFS exports ${NFS_EXPORTS[@]}are healthy | NFS Perfdata "
        exit $STATE_OK
elif [ -z "$NFS_MOUNTS" ] && [ "$NFS_SIDE" = "client" ]; then
        echo "NFS WARNING : NFS client services ${NFS_SERVICES[@]} running. No NFS mountpoint define | NFS Perfdata "
        exit $STATE_WARNING

fi  

# case server-side and client-side with existing NFS mountpoints 
for i in ${NFS_MOUNTS[@]}; do
		if [ `uname` = "SunOS" ]; then
		mount | grep "$i " > /dev/null
		else
        mount | grep " $i " > /dev/null
        fi
        if [ $? != "0" ]; then
                FAULT_ARRAY=( ${FAULT_ARRAY[@]} $i )
        fi
done

if [ ${#FAULT_ARRAY[@]} != 0 ]; then
	case $NFS_SIDE in
	server) echo "NFS CRITICAL : NFS server services ${NFS_SERVICES[@]} running. NFS mountpoint ${FAULT_ARRAY[@]} not mounted. NFS exports ${NFS_EXPORTS[@]}are healthy | NFS perfdata"
       		exit $STATE_CRITICAL;;
	client) echo "NFS CRITICAL : NFS client services ${NFS_SERVICES[@]} running. NFS mountpoint ${FAULT_ARRAY[@]} not mounted | NFS perfdata"
                exit $STATE_CRITICAL;;
	esac
fi


for i in ${NFS_MOUNTS[@]}; do
	PROC_BG_NFSCHECK=`ps -ef | grep "/tmp/nfs_health_monitor $i" | grep -v grep | wc -l`
        if [ $PROC_BG_NFSCHECK -gt 0 ]; then
		case $NFS_SIDE in
        		server) echo "NFS CRITICAL : NFS server services ${NFS_SERVICES[@]} running. Stale NFS mountpoint $i. NFS exports ${NFS_EXPORTS[@]} are healthy | NFS Perfdata"
                	exit $STATE_CRITICAL;;
        		client) echo "NFS CRITICAL : NFS client services ${NFS_SERVICES[@]} running. Stale NFS mountpoint $i | NFS Perfdata"
                	exit $STATE_CRITICAL;;
        		esac
        #elif [ ! -d $i ]; then
        #	echo "NFS WARNING : Stale NFS mount point - $i directory not exist"
        #	exit $STATE_WARNING
        else
        	sh /tmp/nfs_health_monitor $i &
        fi
done

sleep 1

PROC_NFSCHECK=`ps -ef | grep "/tmp/nfs_health_monitor $i" | grep -v grep | awk '{print $2}'`
if [ -n "$PROC_NFSCHECK" ]; then
	case $NFS_SIDE in
            	server) echo "NFS CRITICAL : NFS server services ${NFS_SERVICES[@]} running. Stale NFS mountpoint $i. NFS exports ${NFS_EXPORTS[@]} healthy | NFS Perfdata"
                        kill -9 $PROC_NFSCHECK
			exit $STATE_CRITICAL;;
                client) echo "NFS CRITICAL : NFS client services ${NFS_SERVICES[@]} running. Stale NFS mountpoint $i | NFS perfdata"
                        kill -9 $PROC_NFSCHECK
			exit $STATE_CRITICAL;;
        esac

else
	case $NFS_SIDE in
                server) echo "NFS OK : NFS server services ${NFS_SERVICES[@]} running. NFS mountpoint "${NFS_MOUNTS[@]}" healthy. NFS exports ${NFS_EXPORTS[@]} healthy | NFS perfdata"
                        exit $STATE_OK;;
                client) echo "NFS OK : NFS client services ${NFS_SERVICES[@]} running. NFS mountpoint "${NFS_MOUNTS[@]}" healthy | NFS perfdata"
                        exit $STATE_OK;;
        esac
fi

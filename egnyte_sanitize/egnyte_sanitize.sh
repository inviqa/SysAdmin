#!/bin/bash
#
# The script will parse all the Egnyte Local repository looking for files and folder
# with names that contain symbols and spacing that would make the synchronisation with the Cloud server to fail
#
# Egnyte diurectory to sanitize
ELC_DIR=$1
# Initialise the logfile
LOG_FILE=/var/log/egnyte_sanitize.log
echo '----- BEGIN OF SANITATION @' `eval date` ' ----' > $LOG_FILE

# set the File Separator to 'hyphen' to create an array with the list of EXCEPTIONS from the EXPTS variable
IFS="-"
# list of file naming defects that create exceptions tha ELC is not able to handle
# like names with multiple spaces, trailing spaces, trailing dots, leading spaces or semi-colon symbols
EXPTS=" *-* -*.-*  *-*:*-*|*"


# For each exception
for EXPT in $EXPTS
do
  # set the File Separator to 'new line' so to create an array with the list of files and directory that have names unsupported by ELC
  IFS=$'\x0a'
  DIRTY_NAMES=`find $ELC_DIR -name "$EXPT" -print`
  
  for DIRTY_NAME in $DIRTY_NAMES
  do
    if [ $EXPT == " *" ]; then
      # removes leading white sopaces
      CLEAN_NAME=`eval basename '$DIRTY_NAME' | sed -e 's/^[ ]*//'`
    elif [ $EXPT == "* " ];then
      # removes trailing white sopaces
      CLEAN_NAME=`eval basename '$DIRTY_NAME'  | sed 's/[ ]*$//'`
    elif [ $EXPT == "*." ];then
      # removes trailing dots
      CLEAN_NAME=`eval basename '$DIRTY_NAME'  | sed 's/[.]*$//'`
    elif [ $EXPT == "*  *" ];then
      CLEAN_NAME=`eval basename '$DIRTY_NAME'  | sed 's/  */ /g'`
    elif [ $EXPT == "*:*" ];then
      CLEAN_NAME=`eval basename '$DIRTY_NAME'  | sed 's/:/_/g'`
    elif [ $EXPT == "*|*" ];then
      CLEAN_NAME=`eval basename '$DIRTY_NAME'  | sed 's/\|/_/g'`
    fi
    NEW_NAME=`eval dirname '$DIRTY_NAME'`/"$CLEAN_NAME"
    echo DIRTY: $DIRTY_NAME >> $LOG_FILE
    echo __NEW: $NEW_NAME >> $LOG_FILE
    mv "$DIRTY_NAME" "$NEW_NAME"
  done
done

# restore the File Separator to the system's default
unset IFS
echo '----- END OF SANITATION @' `eval date` ' ----' > $LOG_FILE

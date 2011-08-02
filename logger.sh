#!/bin/bash

version()
{
  sed -e 's/^//' <<EndVersion
Logger.txt
Version 1.1
Author:  Grant Lucas (www.grantlucas.com)
Last updated:  31/01/2011
Release date:  26/07/2010
EndVersion
  exit 1
}

usage()
{
  sed -e 's/^//' <<EndUsage
Usage: logger.sh [-hV] [-t type] [-p project] [-d count] [-s] text
Try 'logger.sh -h' for more information.
EndUsage
  exit 1
}

help()
{
  sed -e 's/^//' <<EndHelp
Usage: logger.sh [-hV] [-t type] [-p project] [-d count] [-s] text

With no options or input, logger.sh outputs the last 10 lines of the log.

Options:
  -t TYPE
    The type classification that the log event belongs to. example: work, school etc.
  -p PROJECT
    The project that the log event belongs to. This helps group log events together which might belong to the same type or which my not belong to a type at all.
  -d COUNT
    The number of lines to show when output the tail of the log. Defaults to 10.
  -s text
    Searches the log file for the given text and displays those entries
  -h
    Help Text.
  -V
    Show version information and credits.
  -x
    Deletes the last line from the log file. This allows for quick corrections of messed up log items which were just entered.
EndHelp
  exit 1
}

deleteLast()
{
  #only act if the log file exists
  if [ -e $LOG_PATH ]; then
    echo ""
    echo "Deleted last line from file";
    `sed '$d' < $LOG_PATH > $dir"/log.txt.backup"`
    `mv $dir"/log.txt.backup" $LOG_PATH`
  fi

}

confirmDeleteLast()
{
  #delete the last line from the file. mainly used for quick fixes of mistakes

  #get the last line for confirmation
  LAST_LINE=`tail -n 1 $LOG_PATH`
  echo ""
  echo "Warning: You are removing the line below which appears at the end of the log file."
  echo ""
  echo "-------------------"
  echo $LAST_LINE
  echo "-------------------"
  echo ""
  echo "Do you wish to continue? (Y/n)"

  read CONFIRM

  case $CONFIRM in
    Y) deleteLast;;
    n|*)
      echo ""
      echo "No line deleted"
      ;;
  esac
  exit 1
}

check_log_file()
{
  if [ -e $LOG_PATH ]; then
    if [ ! -w $LOG_PATH ]; then
      echo "$app: Log file not writeable"
      exit 1
    fi
  else
    # create log file if it does not exist
    echo "$app: Creating log file"
    `touch $LOG_PATH`
    `chmod +w $LOG_PATH`
    if [ -e $LOG_PATH ]; then
      echo "$app: Log file successfully created"
    else
      echo "$app: Log file couldn't be created"
      exit 1
    fi
  fi

  if [ ! -r $LOG_PATH ]; then
    echo "$app: Log file is not readable"
    exit 1
  fi
}

search_log()
{
  #search the log for the serach term
  check_log_file
  #grep through file looking for the lines which have this
  results=`sed = "$LOG_PATH" | grep -i $SEARCH`
  echo -e "$results"
  exit 0
}

# defaults if not yet defined
dir=`dirname $0`

#set the log path to the environment variable if it is set
if [ ! -z $LOGGERTXT_PATH ]; then
  LOG_PATH=$LOGGERTXT_PATH
else
  LOG_PATH=$dir"/log.txt"
fi

LOG_TYPE=${LOG_TYPE:-''}
LOG_DISPLAY_COUNT=${LOG_DISPLAY_COUNT:-10}
LOG_PROJ=${LOG_PROJ:-''}

now=`date '+%F %T'`
app="Log"

# process options
while getopts xt:d:p:s:Vh o
do  case "$o" in
  x) confirmDeleteLast;;
  s) SEARCH=$OPTARG;;
  t) LOG_TYPE=`echo "$OPTARG" | tr "[:lower:]" "[:upper:]"`;;
  d) LOG_DISPLAY_COUNT=$OPTARG;;
  p) LOG_PROJ=`echo "$OPTARG" | tr "[:lower:]" "[:upper:]"`;;
  h) help;;
  V) version;;
  [?]) usage;;
  esac
done
# shift the option values out
shift $(($OPTIND - 1))

#The remaining text is the log text.
#FIXME: Escape log text of special characters which will mess up the insert. Mainly $'s
#log_text=`echo "$*" | sed -e 's/\$/\\\$/g'`
#echo $log_text

#exit 1


#take the input and add to file
if [ ! -z "$1" ]; then
  #add to log file
  check_log_file

  if [ ! -z $LOG_TYPE ]; then
    sep=" - "
    ltype=" under the type $LOG_TYPE"
    LOG_TYPE="$LOG_TYPE"
  fi

  if [ ! -z $LOG_PROJ ]; then
    sep=" - "
    proj=" in the project $LOG_PROJ"
    LOG_PROJ="($LOG_PROJ)"
  fi

  #there is a proj but no type
  if [ -z $LOG_TYPE ] && [ ! -z $LOG_PROJ ]; then
    category="$LOG_PROJ$sep"
  fi

  #there is a type but no proj
  if [ ! -z $LOG_TYPE ] && [ -z $LOG_PROJ ]; then
    category="$LOG_TYPE$sep"
  fi

  #there is both
  if [ ! -z $LOG_TYPE ] && [ ! -z $LOG_PROJ ]; then
    category="$LOG_TYPE $LOG_PROJ$sep"
  fi

  #add text to file
  echo "$now - $category$*" >> "$LOG_PATH"
  #output that the event was logged
  echo "$app: $* logged$ltype$proj"
else
  check_log_file
  if [ ! -z $SEARCH ]; then
    #if there is a search term defined, search for it
    if [ ! -z $LOG_DISPLAY_COUNT ]; then
      #limit results if a limit is set
      results=`cat $LOG_PATH | grep -i $SEARCH | tail -n $LOG_DISPLAY_COUNT`
      echo -e "$results"
    else
      results=`sed = "$LOG_PATH" | grep -i $SEARCH`
      echo -e "$results"
    fi
  else
    #else print out entire log line by line
    tail -n $LOG_DISPLAY_COUNT $LOG_PATH
  fi
fi


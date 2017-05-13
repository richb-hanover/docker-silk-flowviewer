#!/bin/sh

# Startup script for flowviewer-silk Docker container
# From https://docs.docker.com/engine/admin/multi-service_container/

# Start apache2
# /usr/sbin/apache2ctl -D FOREGROUND &
./start_apache2.sh -D
status=$?
echo "Status: $?"
if [ $status -ne 0 ]; then
  echo "Failed to start apache2: $status"
  exit $status
fi

echo `ps ax | grep apache`

# Start rwflowpack
# ./start_rwflowpack.sh -D
# status=$?
# if [ $status -ne 0 ]; then
#   echo "Failed to start rwflowpack: $status"
#   exit $status
# fi# 

# # Start yaf
# ./start_yaf.sh -D
# status=$?
# if [ $status -ne 0 ]; then
#   echo "Failed to start yaf: $status"
#   exit $status
# fi

# while /bin/true; do
#   PROCESS_1_STATUS=$(ps aux |grep -q apache2     | grep -v grep)
#   PROCESS_2_STATUS=$(ps aux |grep -q rwflowpack  | grep -v grep)
#   PROCESS_3_STATUS=$(ps aux |grep -q yaf         | grep -v grep)
#   # If the greps above find anything, they will exit with 0 status
#   # If they are not both 0, then something is wrong
#   if [ $PROCESS_1_STATUS -ne 0 -o $PROCESS_2_STATUS -ne 0 -o $PROCESS_3_STATUS ]; then
#     echo "One of the processes has already exited. ($PROCESS_1_STATUS:$PROCESS_2_STATUS:$PROCESS_3_STATUS)"
#     exit -1
#   fi
#   sleep 60
# done


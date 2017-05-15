#!/bin/bash

# Startup script for flowviewer-silk Docker container
# From https://docs.docker.com/engine/admin/multi-service_container/

# Start apache2
echo `whoami`
# sudo /usr/sbin/apache2ctl -D FOREGROUND &
./start_apache2.sh -D
status=$?
echo "Status: $?"
# if [ $status -ne 0 ]; then
#   echo "Failed to start apache2: $status"
#   exit $status
# fi

echo `ps ax | grep apache`

# Start rwflowpack
./start_rwflowpack.sh -D
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start rwflowpack: $status"
  exit $status
fi

# # Start yaf
./start_yaf.sh -D
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start yaf: $status"
  exit $status
fi

while /bin/true; do
  $(ps aux |grep -q apache2     | grep -v grep)
  PROCESS_1_STATUS=$?
  $(ps aux |grep -q rwflowpack  | grep -v grep)
  PROCESS_2_STATUS=$?
  $(ps aux |grep -q yaf         | grep -v grep)
  PROCESS_3_STATUS=$?
  status = $PROCESS_1_STATUS+$PROCESS_2_STATUS+$PROCESS_2_STATUS
  echo "Status: '$status', '$PROCESS_1_STATUS' '$PROCESS_2_STATUS' '$PROCESS_3_STATUS' "
  # If the greps above find anything, they will exit with 0 status
  # If they are not both 0, then something is wrong
  if [ $status -ne 0 ]; then
    echo "One of the processes has already exited. ($status)"
    exit -1
  fi
  sleep 60
done


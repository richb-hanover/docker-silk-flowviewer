#!/bin/bash

# Startup rwflowpack

sudo /usr/local/sbin/rwflowpack \
  --compression-method=best \
  --sensor-configuration=/data/sensors.conf \
  --site-config-file=/data/silk.conf \
  --output-mode=local-storage \
  --root-directory=/data/ \
  --pidfile=/var/log/rwflowpack.pid \
  --log-level=info \
  --log-directory=/var/log \
  --log-basename=rwflowpack &

#   sudo /usr/local/sbin/rwflowpack 
#   --compression-method=best 
#   --sensor-configuration=/data/sensors.conf 
#   --site-config-file=/data/silk.conf 
#   --output-mode=local-storage 
#   --root-directory=/data/ 
#   --pidfile=/var/log/rwflowpack.pid 
#   --log-level=info 
#   --log-directory=/var/log 
#   --log-basename=rwflowpack

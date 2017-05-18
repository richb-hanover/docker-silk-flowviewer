#!/bin/bash

# Start up the FlowViewer programs

cd /var/www/cgi-bin/FlowViewer_4.6
./FlowMonitor_Collector &
collector=$?
./FlowMonitor_Grapher &
grapher=$?

echo "Collector: $collector; Grapher: $grapher"

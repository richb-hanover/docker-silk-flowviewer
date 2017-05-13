#!/bin/sh

# Start up yaf
# docker listens on eth0

nohup /usr/local/bin/yaf \
--silk --ipfix=tcp \
--live=pcap  \
--out=127.0.0.1 \
--ipfix-port=18001 \
--in=eth0 \
--applabel \
--max-payload=384 &


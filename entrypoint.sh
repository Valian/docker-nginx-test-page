#!/bin/sh

mkdir -p /www/data
env | grep HOSTNAME >> /www/data/index.html
export IP_ADDRESS=$(curl 'https://api.ipify.org' 2> /dev/null)
printf '<br>IP=%s' $IP_ADDRESS >> /www/data/index.html

exec "$@"

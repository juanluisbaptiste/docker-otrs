#!/bin/bash
# Helper script to cleanup the build environment, rebuild and relaunch. For the
# desktop notification to work the script assumes the user belongs to docker group
set -x

docker-compose rm -f -v
sudo rm -fr volumes/config
sudo rm -fr volumes/mysql/*
docker-compose build
notify-send 'App rebuild ready' 'Docker container rebuild finished, starting up container.' -t 5000 -i dialog-information
sleep 1
docker-compose up

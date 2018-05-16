#!/bin/bash
# Helper script to cleanup the build environment, rebuild and relaunch. For the
# desktop notification to work the script assumes the user belongs to docker group
set -x
NOTIFY_TIMEOUT=10000
params=${1}

docker-compose rm -f -v
if [ "${params}" == "clean" ]; then
  sudo rm -fr volumes/config
  sudo rm -fr volumes/mysql/*
  params="--no-cache"
fi
#docker-compose build ${params}
if [ $? -gt 0 ]; then
  out=$(echo ${out}|tail -n 10)
  notify-send 'App rebuild failure' "There was an error building the container, see console for build output" -t ${NOTIFY_TIMEOUT} -i dialog-error && \
  paplay /usr/share/sounds/freedesktop/stereo/suspend-error.oga && exit 1
  #echo ${out}
else
  notify-send 'App rebuild ready' 'Docker container rebuild finished, starting up container.' -t ${NOTIFY_TIMEOUT} -i dialog-information && \
  paplay /usr/share/sounds/freedesktop/stereo/complete.oga
  docker-compose up
fi

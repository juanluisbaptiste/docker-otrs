#!/bin/bash
# Helper script to cleanup the build environment, rebuild and relaunch. For the
# desktop notification to work the script assumes the user belongs to docker group
NOTIFY_TIMEOUT=10000
BUILD_IMAGE=0
BUILD_NOCACHE=""
CLEAN=0
DEBUG=0
RUN=0
params=""
COMPOSE_FILE="docker-compose.yml"

usage()
{
cat << EOF
OTRS development launch script.

Usage: $0 OPTIONS


OPTIONS:
-b    Build image.
-B    Build image (--no-cache).
-c    Clean volumes.
-f    compsoe file to use (default is docker-compose.yml)
-r    Run container.
-h    Print help.
-V    Debug mode.

EOF
}

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT
function ctrl_c() {
        echo "Ctrl C pressed."
        exit 0
}

while getopts bBcf:rhV option
do
  case "${option}"
  in
    b) BUILD_IMAGE=1
       ;;
    B) BUILD_IMAGE=1
       BUILD_NOCACHE="--no-cache"
       ;;
    c) CLEAN=1
       ;;
    f) COMPOSE_FILE="${OPTARG}"
       ;;
    r) RUN=1
       ;;
    h) usage
       exit
       ;;
    V)  DEBUG=1
       ;;
  esac
done

if [ ${DEBUG} -eq 1 ]; then
  set -x
fi

docker-compose rm -f -v

if [ ${CLEAN} -eq 1 ]; then
  sudo rm -fr volumes/config
  sudo rm -fr volumes/mysql/*
  sudo chown -R 27 volumes/mysql
  sudo rm -fr volumes/skins
  params="--no-cache"
fi

if [ ${BUILD_IMAGE} -eq 1 ]; then
  docker-compose -f ${COMPOSE_FILE} build ${BUILD_NOCACHE}
  if [ $? -gt 0 ]; then
    out=$(echo ${out}|tail -n 10)
    notify-send 'App rebuild failure' "There was an error building the container, see console for build output" -t ${NOTIFY_TIMEOUT} -i dialog-error && \
    paplay /usr/share/sounds/freedesktop/stereo/suspend-error.oga && exit 1
    #echo ${out}
  else
    notify-send 'App rebuild ready' 'Docker container rebuild finished, starting up container.' -t ${NOTIFY_TIMEOUT} -i dialog-information && \
    paplay /usr/share/sounds/freedesktop/stereo/complete.oga
  fi
fi
[ ${RUN} -eq 1  ] && docker-compose -f ${COMPOSE_FILE} up

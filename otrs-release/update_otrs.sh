#!/bin/bash
# Script to update the Dockerfile with the new version, test that the image 
# builds and commit/push the new version so the automatic docker image build starts.

. ../otrs/util_functions.sh
. ./release_functions.sh

VERBOSE=1
OTRS_GIT_URL="git@github.com:juanluisbaptiste/docker-otrs.git"
OTRS_UPDATE_LOG="./check_otrs_version.log"
BUILD_IMAGE=0
GIT_PUSH=0
#Supported OTRS versions to avoid breaking the image if the major version upgrade
#breaks the image
declare -A OTRS_SUPPORTED_VERSIONS=(
 [4]=0  [5]=0 [6]=1
)

trap 'control_c' SIGINT
# return 0 if program version is equal or greater than check version
function check_version() {
  test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1";
}

function verbose(){
  message="$1"
  code="$2"
  date="$(date '+[%x %r]' )"
  out="${date} ${message}"
  if [ "${code}" != "" ] && [ ${code} == ${ERROR_CODE} ]; then
    >&2 print_error "${out}"
  elif [ ${VERBOSE} -eq 1 ];then
    print_info "${out}"
  fi
  echo -e ${out} >> ${OTRS_UPDATE_LOG}

}

#Work inside a temp directory
cd "${tempdir}"

echo "[*] Starting image update process"
otrs_version="$(cat ./current_version)"
echo "  - Querying RPM packages version"  
rpm_version="$(get_otrs_rpm_version)"
echo "  - RPM package version: ${rpm_version}"

#Clone git repo to update OTRS version
if [ ${BUILD_IMAGE} -eq 1 ]; then
  echo "[*] Building new image"
  build_image
fi
cd ..

#Cleanup
cleanup

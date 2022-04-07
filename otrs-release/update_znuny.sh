#!/bin/bash
# Script to check for new Znuny versions 

# shellcheck source=../release_functions.sh
. ./release_functions.sh

OTRS_VERSION="${OTRS_VERSION:-""}"
UPDATE_IMAGE="${UPDATE_IMAGE:-1}"
BUILD_IMAGE="${BUILD_IMAGE:-0}"
PUSH_IMAGE="${PUSH_IMAGE:-0}"
NEW_VERSION_FILE="$(pwd)/new_version"
# Supported OTRS versions to avoid breaking the image if the major version upgrade
#breaks the image
declare -A OTRS_SUPPORTED_VERSIONS=(
 [4]=0  [5]=0 [6]=1
)

# Work inside a temp directory
cd "${tempdir}" || exit

echo "[*] Starting Znuny image update"
if [ "${OTRS_VERSION}" == "" ]; then
  echo "  - Checking for Znuny latest version..."
  otrs_version="$(get_current_otrs_version)"
else
  otrs_version="${OTRS_VERSION}"
  echo "  - Updating to Znuny version: ${otrs_version}"
fi
#Check if Znuny version is supported by this script
major_version=$(echo ${otrs_version}|cut -d'.' -f1)
[[ ! -n "${OTRS_SUPPORTED_VERSIONS[${major_version}]}" ]] && echo "ERROR!! Current Znuny version is not supported: ${otrs_version}" ${ERROR_CODE} && exit 1

#Get version in Dockerfile
docker_otrs_version=$(wget -q -O - https://raw.githubusercontent.com/juanluisbaptiste/docker-otrs/${OTRS_GIT_BRANCH}/otrs/Dockerfile|grep OTRS_VERSION|grep ENV|cut -d'=' -f2|cut -d'-' -f1)
echo "  - Version in Dockerfile is: ${docker_otrs_version}"

#Compare versions and there's a newer one, update the Dockerfile, commit
#and push
echo "  - Checking versions..."
check_version ${otrs_version} ${docker_otrs_version}
if [ $? -eq 0 ]; then
  echo "  - New Znuny version available: ${otrs_version}"
  echo "${otrs_version}" > ${NEW_VERSION_FILE}
else
  echo "  - No new version available."
  exit
fi

#Clone git repo to update Znuny version
if [ ${UPDATE_IMAGE} -eq 1 ]; then
  echo "[*] Updating image in git repository"
  update_image
  if [ ${BUILD_IMAGE} -eq 1 ]; then
    echo "[*] Building new image"
    build_image
  fi
  if [ ${PUSH_IMAGE} -eq 1 ]; then
    echo "[*] Pushing changes"
    push_changes
  fi  
fi

cd ..

# Cleanup
cleanup

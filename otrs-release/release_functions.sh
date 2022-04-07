#!/bin/bash

OTRS_DOWNLOAD_PREFIX="https://download.znuny.org/releases/"
OTRS_LATEST="${OTRS_DOWNLOAD_PREFIX}/znuny-latest.tar.gz"
OTRS_GIT_URL="git@github.com:juanluisbaptiste/docker-otrs.git"
OTRS_GIT_BRANCH="${OTRS_GIT_BRANCH:-master}"
BUILD_LOG="../build.out"
_image_updated=0

# Create a temp dir
tempdir="$(mktemp -d --suffix -docker-otrs)"

trap 'control_c' SIGINT
# return 0 if program version is equal or greater than check version
function check_version() {
  test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1";
}

# Run if user hits control-c
function control_c() {
  echo -e "\n***Cleaning up ***\n"
  cleanup
  exit $?
}

# Cleanup tasks
function cleanup(){
  # Remove temp directory
  echo "Removing temp directory..."
  rm -fr "${tempdir}"
  return $?
}

# Download latest version and get the version from the RELEASE file inside the
#tarball.
function get_current_otrs_version(){
  local otrs_version=""

  wget -q ${OTRS_LATEST}
  filename=$(basename ${OTRS_LATEST})
  dirname=$(tar tf ${filename} | head -1 | cut -f1 -d"/")
  releasefile=$(tar zxvf ${filename} ${dirname}/RELEASE)
  otrs_version=$(cat ${releasefile}|grep VERSION|cut -d'=' -f2|tr -d ' ')
  echo "${otrs_version}"
}


# Get rpm file version to replace on Dockerfile
function get_otrs_rpm_version(){
  for i in "01" "02" "03"; do
    rpm_version="${otrs_version}-${i}"
    OTRS_LATEST_RPM="${OTRS_DOWNLOAD_PREFIX}/RPMS/rhel/7/znuny-${rpm_version}.noarch.rpm"

    wget -q ${OTRS_LATEST_RPM}
    if [ $? -eq 0 ];then
      echo "${rpm_version}"
      break
    fi
    echo "ERROR: Could not find rpm version !" && exit 1
  done
}

function update_image(){
  echo "  - Querying RPM packages version"  
  rpm_version="$(get_otrs_rpm_version)"
  echo "  - RPM package version: ${rpm_version}"

  echo "  - Cloning git repository"
  out="$(git clone ${OTRS_GIT_URL} 2>&1)"
  [ $? -gt 0 ] && echo "ERROR: Could not clone git repository:" && echo "${out}" && exit 1

  cd docker-otrs/ || exit
  git config --global user.email "juan@juanbaptiste.tech"
  git config --global user.name "Znuny Update Bot"
  
  if [ "${OTRS_GIT_BRANCH}" != "master" ]; then 
    echo "  - Switching to branch ${OTRS_GIT_BRANCH}"
    out="$(git checkout "${OTRS_GIT_BRANCH}" 2>&1)"
    [ $? -gt 0 ] && echo "ERROR: Branch [${OTRS_GIT_BRANCH}] does not exist:" && echo "${out}" && exit 1
  fi
  echo "  - Update Dockerfile..."
  # TODO: Replace with a dockerfile build parameter
  sed -i -r "s/(ENV OTRS_VERSION *= *).*/\1${rpm_version}/" otrs/Dockerfile

  echo "  - Committing changes on branch: ${OTRS_GIT_BRANCH}"
  out="$(git commit -a -m "Automatic Znuny version update: ${docker_otrs_version} -> ${otrs_version}")"
  if [ $? -gt 0 ];then
    echo "ERROR: Could not commit changes !: ${out}" ${ERROR_CODE} && exit 1
  fi
  _image_updated=1
}

function build_image(){    
    # Build image to test it builds ok with the new version
    echo "  - Building image..."
    if ! docker build --rm otrs/ > "${BUILD_LOG}" 2>&1 
    then
        echo "******************** BUILD FAILED ********************"
        tail -n10 "${BUILD_LOG}"
        echo "******************************************************"
        echo "You can find the full log here: ${BUILD_LOG}"
        exit 1
    fi
}

function push_changes(){
  # If the image builds ok, commit and push
  if [ ${_image_updated} -eq 1 ]; then
    echo "  - Push changes..."
    out="$(git push origin ${OTRS_GIT_BRANCH} 2>&1)"
    if [ $? -gt 0 ];then
      echo "ERROR: Could not push changes !: ${out}" && exit 1
    fi
    echo "[*] SUCESS !! docker image updated."
  fi
}
#!/bin/bash
# Script to periodically check for new OTRS versions and automatically update
# the Dockerfile with the new version, test that the image builds and
# commit/push the new version so the automatic docker image build starts.
. ./util_functions.sh

VERBOSE=1
OTRS_LATEST="http://ftp.otrs.org/pub/otrs/otrs-latest.tar.gz"
OTRS_GIT_URL="git@github.com:juanluisbaptiste/docker-otrs.git"
OTRS_UPDATE_LOG="./check_otrs_version.log"
GIT_PUSH=0
#Supported OTRS versions to avoid breaking the image if the major version upgrade
#breaks the image
declare -A OTRS_SUPPORTED_VERSIONS=(
 [4]=0  [5]=0 [6]=1
)
ERROR_CODE="ERROR"

trap 'control_c' SIGINT
# return 0 if program version is equal or greater than check version
function check_version() {
  test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1";
}

#Run if user hits control-c
function control_c() {
  print_info "\n***Cleaning up ***\n"
  cleanup
  exit $?
}

function cleanup(){
  #Remove temp directory
  print_info "Removing temp directory..."
  cat ${tempdir}/docker-otrs/.drone.yml
  rm -fr ${tempdir}
  return $?
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
tempdir="$(mktemp -d --suffix -docker-otrs)"
cd ${tempdir}

verbose "********** Checking latest OTRS version **********"
verbose "Downloading OTRS source tarball..."
#Download latest version and get the version from the RELEASE file inside the
#tarball.
wget -q ${OTRS_LATEST}
filename=$(basename ${OTRS_LATEST})
dirname=$(tar tf ${filename} | head -1 | cut -f1 -d"/")
releasefile=$(tar zxvf ${filename} ${dirname}/RELEASE)
otrs_version=$(cat ${releasefile}|grep VERSION|cut -d'=' -f2|tr -d ' ')

#Check if OTRS version is supported by this script
major_version=$(echo ${otrs_version}|cut -d'.' -f1)
[[ ! -n "${OTRS_SUPPORTED_VERSIONS[${major_version}]}" ]] && verbose "ERROR!! Current OTRS version is not supported: ${otrs_version}" && exit 1

#Get version in Dockerfile
docker_otrs_version=$(wget -q -O - https://raw.githubusercontent.com/juanluisbaptiste/docker-otrs/master/otrs/Dockerfile|grep OTRS_VERSION|grep ENV|cut -d'=' -f2|cut -d'-' -f1)

#Compare versions and there's a newer one, update the Dockerfile, commit
#and push
verbose "Checking versions..."
#check_version ${otrs_version} ${docker_otrs_version}
if [ $? -eq 0 ]; then
  verbose "New OTRS version available!"
  verbose "Updating to OTRS docker image to version ${otrs_version}"

  #Get rpm file version to replace on Dockerfile
  for i in "01" "02" "03"; do
    rpm_version="${otrs_version}-${i}"
    verbose "Querying RPM packages version"
    OTRS_LATEST_RPM="http://ftp.otrs.org/pub/otrs/RPMS/rhel/7/otrs-${rpm_version}.noarch.rpm"

    wget -q ${OTRS_LATEST_RPM}
    if [ $? -eq 0 ];then
      verbose "RPM package version: ${rpm_version}"
      #otrs_version="${rpm_version}"
      break
    fi
    verbose "ERROR: Could not find rpm version !" ${ERROR_CODE} && exit 1
  done

  #Clone git repo to update OTRS version
  git clone ${OTRS_GIT_URL}
  [ $? -gt 0 ] && verbose "ERROR: Could not clone git repository." && exit 1

  cd docker-otrs/
  verbose "Update Dockerfile..."
  #TODO: Replace with a dockerfile build parameter
  sed -i -r "s/(ENV OTRS_VERSION *= *).*/\1${rpm_version}/" otrs/Dockerfile
  #Build image to test it builds ok with the new version

  verbose "Build image..."
  docker build --rm otrs/
  #If the image builds ok, commit and push
  if [ $? -eq 0 ];then

    verbose "Updating version in drone.io build file"
    sed -i s/${docker_otrs_version}/${otrs_version}/g .drone.yml
    if [ $? -gt 0 ];then
      verbose "ERROR: Cannot update version tag in .drone.yml file !: ${out}" ${ERROR_CODE} && exit 1
    fi
    verbose "Commit changes..."
    out="$(git commit -a -m "Automatic OTRS version update: ${docker_otrs_version} -> ${otrs_version}")"
    if [ $? -gt 0 ];then
      verbose "ERROR: Could not commit changes !: ${out}" ${ERROR_CODE} && exit 1
    fi
    if [ ${GIT_PUSH} -eq 1 ]; then
      verbose "Push changes..."
      out="$(git push)"
      if [ $? -gt 0 ];then
        verbose "ERROR: Could not push changes !: ${out}" ${ERROR_CODE} && exit 1
      fi
    fi
    verbose "SUCESS !! docker image updated to latest version."
  fi
  cd ..
else
  verbose "No new version available."
fi
cd ..

#Cleanup
cleanup

#!/usr/bin/env bash

# Fail fast on errors and unset variables.
set -eu

# Prepare.
# --------
# set version patch number to build number from travis
sed -i -r 's,^VERSION=([0-9]+\.[0-9]+)\.0$,VERSION=\1.'"${TRAVIS_BUILD_NUMBER:?SetupTravisCorrectly}"',g' metadata
VERSION=$(awk -F= '/VERSION/ {print $2}' metadata)
MODULE=$(awk -F= '/NAME/ {print $2}' metadata)

echo "Building version ${VERSION:?"Corrupt metadata file"} of ${MODULE:?"Corrupt metadata file"}..."
# Create a scratch directory and change directory to it.
WORK_DIR=$(mktemp -d "/tmp/build-$MODULE.XXXXXX")
mkdir "${WORK_DIR:?'Unable to create temp dir'}/bintray"

git clone "file://${TRAVIS_BUILD_DIR:?SetupTravisCorrectly}" "${WORK_DIR}/bintray"
cp -p metadata "${WORK_DIR}/bintray"/
# Bootstrap
# ---------

# Setup the rerun execution environment.
export RERUN_MODULES=${WORK_DIR}:${RERUN_MODULES:-/usr/lib/rerun/modules}

# Build the module.
# -----------------
echo "Packaging the build..."

# Build the archive!
rerun stubbs:archive --modules $MODULE
BIN=rerun.sh
[ ! -f ${BIN} ] && {
    echo >&2 "ERROR: ${BIN} archive was not created."; exit 1
}

# Test the archive by making it do a command list.
./${BIN} ${MODULE}

# Build a deb
#-------------
rerun stubbs:archive --modules $MODULE --format deb --version ${VERSION} --release ${RELEASE:=1}
sysver="${VERSION}-${RELEASE}"
DEB=rerun-${MODULE}_${sysver}_all.deb
[ ! -f ${DEB} ] && {
    echo >&2 "ERROR: ${DEB} file was not created."
    files=( *.deb )
    echo >&2 "ERROR: ${#files[*]} files matching .deb: ${files[*]}"
    exit 1
}
# Build a rpm
#-------------
rerun stubbs:archive --modules $MODULE --format rpm --version ${VERSION} --release ${RELEASE}
RPM=rerun-${MODULE}-${sysver}.linux.noarch.rpm
[ ! -f ${RPM} ] && {
    echo >&2 "ERROR: ${RPM} file was not created."
    files=( *.rpm )
    echo >&2 "ERROR: ${#files[*]} files matching .rpm: ${files[*]}"
    exit 1
}

if [[ "${TRAVIS_BRANCH}" == "master" && "${TRAVIS_PULL_REQUEST}" == "false" ]]; then

  export USER=${BINTRAY_USER}
  export APIKEY=${BINTRAY_APIKEY}
  export ORG=${BINTRAY_ORG}
  export PACKAGE=${MODULE}
  
  # Upload and publish to bintray
  echo "Uploading ${BIN} to bintray: /${BINTRAY_ORG}/rerun-modules/${MODULE}/${VERSION}..."
  export REPO="rerun-modules"
  rerun bintray:package-upload --file ${BIN}

  echo "Uploading debian package ${DEB} to bintray: /${BINTRAY_ORG}/rerun-deb ..."
  export PACKAGE="rerun-${MODULE}"
  export REPO="rerun-deb"
  rerun bintray:package-upload-deb --version "${sysver}" --file ${DEB} --deb_architecture all
  rerun bintray:package-upload --version "${sysver}" --file "${PACKAGE}_${VERSION}.orig.tar.gz"
  rerun bintray:package-upload --version "${sysver}" --file "${PACKAGE}_${sysver}.debian.tar.xz"
  rerun bintray:package-upload --version "${sysver}" --file "${PACKAGE}_${sysver}.amd64.build"
  rerun bintray:package-upload --version "${sysver}" --file "${PACKAGE}_${sysver}.amd64.changes"
  rerun bintray:package-upload --version "${sysver}" --file "${PACKAGE}_${sysver}.dsc"

  echo "Uploading rpm package ${RPM} to bintray: /${BINTRAY_ORG}/rerun-rpm ..."
  export REPO="rerun-rpm"
  rerun bintray:package-upload --version ${sysver} --file ${RPM}

else
  echo "***                     ***"
  echo "*** Travis-CI sayz LGTM ***"
  echo "***                     ***"
fi


echo "Done."

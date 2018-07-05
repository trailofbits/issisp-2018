#!/bin/bash

# sudo apt-get install rpm ruby-dev
# gem install fpm

echo "This script packages mcsema into deb and rpm packages"

FPM=$(which fpm)
if [ ! -e "${FPM}" ]
then
    echo "Could not find fpm."
    echo "Please install via:"
    echo ""
    echo "$ sudo apt-get install rpm ruby-dev"
    echo "$ sudo gem install fpm"
    exit 1
fi

DIR=`pwd`
PKGDIR=${DIR}/package

echo "Cleaning old directory"
rm -rf ${PKGDIR}

REMILL_DIR=${DIR}/remill
BUILD_DIR=${DIR}/remill/remill-build
MCSEMA_DIR=${REMILL_DIR}/tools/mcsema

OS_VERSION=

function os_version
{ 
  source /etc/lsb-release  
  case "${DISTRIB_CODENAME}" in
    xenial)
      OS_VERSION=ubuntu1604
      return 0
    ;;
    trusty)
      OS_VERSION=ubuntu1404
      return 0
    ;;
    *)
      printf "[x] The Ubuntu ${DISTRIB_CODENAME} is not supported.\n"
      return 1
    ;;
  esac
}

function mcsema_build
{
  rm -rf remill
  git clone -b master https://github.com/trailofbits/remill.git ${DIR}/remill
  git clone --depth 1 -b master https://github.com/trailofbits/mcsema.git ${DIR}/remill/tools/mcsema
  export REMILL_VERSION=`cat ${DIR}/remill/tools/mcsema/.remill_commit_id`
  pushd ${DIR}/remill
  git checkout -b temp $REMILL_VERSION
  mkdir remill-build
  pushd remill-build
  local LIBRARY_VERSION=libraries-llvm60-${OS_VERSION}-amd64
  wget https://s3.amazonaws.com/cxx-common/${LIBRARY_VERSION}.tar.gz
  tar xf ${LIBRARY_VERSION}.tar.gz --warning=no-timestamp
  #rm ${LIBRARY_VERSION}.tar.gz
  find ./libraries -type f -exec touch {} \;
  popd
  # end library fetching
  ./scripts/build.sh --prefix ${PKGDIR}
  virtualenv ${PKGDIR}
  pushd ${PKGDIR}
  source bin/activate
  popd
  pushd remill-build
  sudo make install
  popd
  popd
}

# get a version number
os_version
mcsema_build

pushd ${MCSEMA_DIR}
GIT_HASH=$(git rev-parse --short HEAD)
VERSION=2.0-${GIT_HASH}-${OS_VERSION}
echo "MCSEMA Version is: ${VERSION}"
popd

echo "Building .deb file..."
fpm -s dir -t deb --name mcsema --version ${VERSION} --maintainer "<mcsema@trailofbits.com>" --url "https://github.com/trailofbits/mcsema" --vendor "Trail of Bits" --prefix "" -C ${PKGDIR} .

echo "Building .rpm file..."
fpm -s dir -t rpm --name mcsema --version ${VERSION} --maintainer "<mcsema@trailofbits.com>" --url "https://github.com/trailofbits/mcsema" --vendor "Trail of Bits" --prefix "" -C ${PKGDIR} .

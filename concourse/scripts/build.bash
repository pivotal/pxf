#!/usr/bin/env bash

set -eox pipefail

: "${TARGET_OS:?TARGET_OS must be set}"

CWDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${CWDIR}/pxf_common.bash"

GPDB_PKG_DIR=gpdb_package
GPDB_VERSION=$(<"${GPDB_PKG_DIR}/version")

function install_gpdb() {
    local pkg_file
    if command -v rpm; then
        pkg_file=$(find "${GPDB_PKG_DIR}" -name "greenplum-db-${GPDB_VERSION}-rhel*-x86_64.rpm")
        echo "Installing RPM ${pkg_file}..."
        rpm --quiet -ivh "${pkg_file}" >/dev/null
    elif command -v apt-get; then
        # apt-get wants a full path
        pkg_file=$(find "${PWD}/${GPDB_PKG_DIR}" -name "greenplum-db-${GPDB_VERSION}-ubuntu18.04-amd64.deb")
        echo "Installing DEB ${pkg_file}..."
        apt-get install -qq "${pkg_file}" >/dev/null
    else
        echo "Unsupported operating system ${TARGET_OS}. Exiting..."
        exit 1
    fi
}

function compile_pxf() {
    source "${GPHOME}/greenplum_path.sh"

    case "${TARGET_OS}" in
    rhel*) MAKE_TARGET="rpm-tar" ;;
    ubuntu*) MAKE_TARGET="deb-tar" ;;
    *)
        echo "Unsupported operating system ${TARGET_OS}. Exiting..."
        exit 1
        ;;
    esac

    bash -c "
        source ~/.pxfrc
        VENDOR='${VENDOR}' LICENSE='${LICENSE}' make -C '${PWD}/pxf_src' ${MAKE_TARGET}
    "
}

function package_pxf() {
    # verify contents
    case "${TARGET_OS}" in
    rhel*) DIST_DIR=distrpm ;;
    ubuntu*) DIST_DIR=distdeb ;;
    *)
        echo "Unsupported operating system ${TARGET_OS}. Exiting..."
        exit 1
        ;;
    esac

    ls -al pxf_src/build/${DIST_DIR}
    tar -tvzf pxf_src/build/${DIST_DIR}/pxf-*.tar.gz
    cp pxf_src/build/${DIST_DIR}/pxf-*.tar.gz dist
}

install_gpdb
# installation of GPDB from RPM/DEB doesn't insure that the installation location will match the version
# given in the gpdb_package, so set the GPHOME after installation
GPHOME=$(find /usr/local/ -name "greenplum-db-${GPDB_VERSION}*")
inflate_dependencies
compile_pxf
package_pxf

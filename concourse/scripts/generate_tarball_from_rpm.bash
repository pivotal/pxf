#!/usr/bin/env bash

set -e

: "${GP_VER:?GP_VER must be set}"
: "${TARGET_OS_VERSION:?TARGET_OS_VERSION must be set}"

function fail() {
  echo "Error: $1"
  exit 1
}

# check if directory with artifacts is available
[[ -d pxf_artifacts ]] || fail "pxf_artifacts directory not found"

# check if the RPM for GP version and TARGET_OS_VERSION is available
rpm_file_name=$(find pxf_artifacts -type f -name "pxf-gp${GP_VER}-*-2.el${TARGET_OS_VERSION}.x86_64.rpm")
[[ -f ${rpm_file_name} ]] || fail "pxf_artifacts/licensed/pxf-gp${GP_VER}-*-2.el${TARGET_OS_VERSION}.x86_64.rpm not found"

# attempt to determine the PXF version
if [[ ${rpm_file_name##*/} =~ pxf-gp${GP_VER}-([0-9.]+)-2[\.-](.*\.(deb|rpm)) ]]; then
  pxf_version=${BASH_REMATCH[1]}
  suffix=${BASH_REMATCH[2]}
  echo "Determined PXF version number to be '${pxf_version}' with suffix '${suffix}'..."
else
  echo "Couldn't determine version number from file named '${rpm_file_name}'..."
  exit 1
fi

# install the new RPM, check that the OSL file is present
rpm -ivh "$rpm_file_name"
echo "listing installed directory /usr/local/pxf-gp${GP_VER}:"
ls -al "/usr/local/pxf-gp${GP_VER}"

# copy installed PXF into a staging directory
mkdir -p /tmp/pxf_tarball_repackage
cp -R "/usr/local/pxf-gp${GP_VER}/" /tmp/pxf_tarball_repackage/pxf

# place gpextable into the appropriate locations when creating internal `pxf.tar.gz` tarball, so they are just extracted and no additional copying is required
mv /tmp/pxf_tarball_repackage/pxf/gpextable/* /tmp/pxf_tarball_repackage/
rm -rf /tmp/pxf_tarball_repackage/pxf/gpextable/

# list staging directory
echo "listing staging directory /tmp/pxf_tarball_repackage"
ls -al /tmp/pxf_tarball_repackage

# create the pxf.tar.gz that contains all files from the RPM installation
echo "create the pxf tarball"
mkdir -p /tmp/pxf_tarball
tar -czf /tmp/pxf_tarball/pxf.tar.gz -C /tmp/pxf_tarball_repackage .

# create the install_gpdb_component file
cat > /tmp/pxf_tarball/install_gpdb_component <<EOF
#!/bin/bash
set -x
: "\${GPHOME:?GPHOME must be set}"
tar xvzf pxf.tar.gz -C \$GPHOME
EOF
chmod +x /tmp/pxf_tarball/install_gpdb_component

echo "create the pxf installer tarball in pxf_artifacts/licensed/pxf-gp${GP_VER}-${pxf_version}.tar.gz"
tar -czf "pxf_artifacts/licensed/pxf-gp${GP_VER}-${pxf_version}.tar.gz" -C /tmp/pxf_tarball .
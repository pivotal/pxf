#!/bin/bash -l

set -eox pipefail

if [ -z "$OUTPUT_ARTIFACT_DIR" ]; then echo 'OUTPUT_ARTIFACT_DIR must be set as a param in the task yml'; exit 1; fi
if [ -z "$TARGET_OS" ];           then echo 'TARGET_OS must be set as a param in the task yml'; exit 1; fi

GPHOME="/usr/local/greenplum-db-devel"
export PXF_ARTIFACTS_DIR="$(pwd)/${OUTPUT_ARTIFACT_DIR}"

_main() {
	export TERM=xterm
	export BUILD_NUMBER="${TARGET_OS}"
	export PXF_HOME="${GPHOME}/pxf"
	export JAVA_TOOL_OPTIONS=-Dfile.encoding=UTF8
	pushd pxf_src/server
		make install
		make version > "${PXF_HOME}/version"
	popd
	# Create tarball for PXF
	pushd "${GPHOME}"
		tar -czf "${PXF_ARTIFACTS_DIR}/pxf.tar.gz" pxf
	popd
}

_main

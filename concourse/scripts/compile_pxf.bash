#!/bin/bash -l

set -eox pipefail

CWDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${CWDIR}/pxf_common.bash"

assert_ci_param 'OUTPUT_ARTIFACT_DIR'
assert_ci_param 'TARGET_OS'

export PXF_ARTIFACTS_DIR="$(pwd)/${OUTPUT_ARTIFACT_DIR}"

_main() {
	export TERM=xterm
	export BUILD_NUMBER="${TARGET_OS}"
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

#!/usr/bin/env bash
#------------------------------------------------------------------
# bashunit migration notes:
# 1. PROGRAM_DIR not readonly - bashunit runs all tests in same session
# 2. Guard check skips if already loaded to avoid readonly variable conflicts
#------------------------------------------------------------------
set -u  # treat unset variables as an error

if [[ -z "${PROGRAM_DIR:-}" ]]; then
    PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
    [[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
fi

# Mock variables
LIB_PLATF_ARCHITECTURE=''
LIB_PLATF_POWER_PLATFORM_BASE=''
OS_VERSION=''
IBMCLOUD_RC=1

# Mock functions
LIB_FUNC_IS_IBMPOWER() { return 0 ; }
LIB_FUNC_IS_SLES() { return 0 ; }
LIB_FUNC_IS_CLOUD_IBM() { return "${IBMCLOUD_RC}" ; }


function test_power7_bigendian_sles_not_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER7'
    OS_VERSION='11.3'

    #act
    check_0004_os_hana_support_sles_ibmpower

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for POWER7 big endian"
    fi
}

function test_power9_bigendian_not_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'

    #act
    check_0004_os_hana_support_sles_ibmpower

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for POWER9 big endian"
    fi
}

function test_power7_littleendian_sles_not_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER7'
    OS_VERSION='11.4'

    #act
    check_0004_os_hana_support_sles_ibmpower

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for POWER7 little endian"
    fi
}

function test_power8_littleendian_sles_not_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER8'
    OS_VERSION='12.5'

    #act
    check_0004_os_hana_support_sles_ibmpower

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for POWER8"
    fi
}

function test_power9_littleendian_sles_not_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'
    OS_VERSION='12.2'

    #act
    check_0004_os_hana_support_sles_ibmpower

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for POWER9 unsupported SLES"
    fi
}

function test_power9_littleendian_sles_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'
    OS_VERSION='15.6'

    #act
    check_0004_os_hana_support_sles_ibmpower

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for POWER9 supported SLES"
    fi
}

function test_power10_littleendian_sles_not_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER10'
    OS_VERSION='12.2'

    #act
    check_0004_os_hana_support_sles_ibmpower

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for POWER10 unsupported SLES"
    fi
}

function test_power10_littleendian_sles_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER10'
    OS_VERSION='15.5'

    #act
    check_0004_os_hana_support_sles_ibmpower

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for POWER10 supported SLES"
    fi
}

function test_powerX_not_supported() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER6'

    #act
    check_0004_os_hana_support_sles_ibmpower

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for unsupported POWER generation"
    fi
}

function test_architecture_not_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc65le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'

    #act
    check_0004_os_hana_support_sles_ibmpower

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for unsupported architecture"
    fi
}

function test_environment_not_handled() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER90'
    OS_VERSION='15.3'

    #act
    check_0004_os_hana_support_sles_ibmpower

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for unhandled environment"
    fi
}

function test_sles_not_handled() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'
    OS_VERSION='15.9'

    #act
    check_0004_os_hana_support_sles_ibmpower

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for unhandled SLES version"
    fi
}

function test_ibmcloud_power9_littleendian_sles_not_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'
    OS_VERSION='12.4'
    IBMCLOUD_RC=0

    #act
    check_0004_os_hana_support_sles_ibmpower

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for IBM Cloud POWER9 unsupported"
    fi
}

function test_ibmcloud_power9_littleendian_sles_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'
    OS_VERSION='15.5'
    IBMCLOUD_RC=0

    #act
    check_0004_os_hana_support_sles_ibmpower

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for IBM Cloud POWER9 supported"
    fi
}

function test_ibmcloud_power10_littleendian_sles_not_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER10'
    OS_VERSION='12.5'
    IBMCLOUD_RC=0

    #act
    check_0004_os_hana_support_sles_ibmpower

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for IBM Cloud POWER10 unsupported"
    fi
}

function test_ibmcloud_power10_littleendian_sles_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER10'
    OS_VERSION='15.6'
    IBMCLOUD_RC=0

    #act
    check_0004_os_hana_support_sles_ibmpower

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for IBM Cloud POWER10 supported"
    fi
}


function set_up_before_script() {

    # Disable errexit - bashunit enables it but sourced files may return non-zero
    set +eE

    # Skip if already loaded (bashunit runs all tests in same session)
    [[ -n "${_0004_test_loaded:-}" ]] && return 0
    _0004_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/0004_os_hana_support_sles_ibmpower.check
    source "${PROGRAM_DIR}/../../lib/check/0004_os_hana_support_sles_ibmpower.check"

}

function set_up() {

    # Reset mock variables
    LIB_PLATF_ARCHITECTURE=
    LIB_PLATF_POWER_PLATFORM_BASE=
    OS_VERSION=
    IBMCLOUD_RC=1

}

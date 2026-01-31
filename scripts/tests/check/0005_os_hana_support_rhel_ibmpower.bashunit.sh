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
LIB_FUNC_IS_RHEL() { return 0 ; }
LIB_FUNC_IS_CLOUD_IBM() { return "${IBMCLOUD_RC}" ; }


function test_bigendian_not_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64'

    #act
    check_0005_os_hana_support_rhel_ibmpower

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for big endian"
    fi
}

function test_power7_not_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER7'

    #act
    check_0005_os_hana_support_rhel_ibmpower

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for POWER7"
    fi
}

function test_power8_not_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER8'

    #act
    check_0005_os_hana_support_rhel_ibmpower

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for POWER8"
    fi
}

function test_power9_rhel_not_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'
    OS_VERSION='7.9'

    #act
    check_0005_os_hana_support_rhel_ibmpower

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for POWER9 unsupported RHEL"
    fi
}

function test_power9_rhel_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'
    OS_VERSION='8.8'

    #act
    check_0005_os_hana_support_rhel_ibmpower

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for POWER9 supported RHEL"
    fi
}

function test_power10_rhel_not_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER10'
    OS_VERSION='7.9'

    #act
    check_0005_os_hana_support_rhel_ibmpower

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for POWER10 unsupported RHEL"
    fi
}

function test_power10_rhel_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER10'
    OS_VERSION='8.10'

    #act
    check_0005_os_hana_support_rhel_ibmpower

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for POWER10 supported RHEL"
    fi
}

function test_powerX_not_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWERx'

    #act
    check_0005_os_hana_support_rhel_ibmpower

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
    check_0005_os_hana_support_rhel_ibmpower

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for unsupported architecture"
    fi
}

function test_environment_not_handled() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER90'
    OS_VERSION='8.2'

    #act
    check_0005_os_hana_support_rhel_ibmpower

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for unhandled environment"
    fi
}

function test_rhel_not_handled() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'
    OS_VERSION='8.9'

    #act
    check_0005_os_hana_support_rhel_ibmpower

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for unhandled RHEL version"
    fi
}

function test_ibmcloud_power9_rhel_not_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'
    OS_VERSION='7.9'
    IBMCLOUD_RC=0

    #act
    check_0005_os_hana_support_rhel_ibmpower

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for IBM Cloud POWER9 unsupported"
    fi
}

function test_ibmcloud_power9_rhel_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'
    OS_VERSION='8.10'
    IBMCLOUD_RC=0

    #act
    check_0005_os_hana_support_rhel_ibmpower

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for IBM Cloud POWER9 supported"
    fi
}

function test_ibmcloud_power10_rhel_not_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER10'
    OS_VERSION='7.9'
    IBMCLOUD_RC=0

    #act
    check_0005_os_hana_support_rhel_ibmpower

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for IBM Cloud POWER10 unsupported"
    fi
}

function test_ibmcloud_power10_rhel_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER10'
    OS_VERSION='9.4'
    IBMCLOUD_RC=0

    #act
    check_0005_os_hana_support_rhel_ibmpower

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for IBM Cloud POWER10 supported"
    fi
}


function set_up_before_script() {

    # Disable errexit - bashunit enables it but sourced files may return non-zero
    set +eE

    # Skip if already loaded (bashunit runs all tests in same session)
    [[ -n "${_0005_test_loaded:-}" ]] && return 0
    _0005_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/0005_os_hana_support_rhel_ibmpower.check
    source "${PROGRAM_DIR}/../../lib/check/0005_os_hana_support_rhel_ibmpower.check"

}

function set_up() {

    # Reset mock variables
    LIB_PLATF_ARCHITECTURE=
    LIB_PLATF_POWER_PLATFORM_BASE=
    OS_VERSION=
    IBMCLOUD_RC=1

}

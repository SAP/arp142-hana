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
OS_VERSION=''
OS_LEVEL=''
COMPARE_VERSIONS_RC=0

# Mock functions
LIB_FUNC_IS_INTEL() { return 0 ; }
LIB_FUNC_IS_SLES() { return 0 ; }
LIB_FUNC_NORMALIZE_KERNELn() { : ; }

LIB_FUNC_COMPARE_VERSIONS() {
    # shellcheck disable=SC2086
    return $COMPARE_VERSIONS_RC ;
}


function test_sles_not_supported() {

    #arrange
    OS_VERSION='11.3'

    #act
    check_0010_os_kernel_sles

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for unsupported SLES"
    fi
}

function test_sles_supported_kernel_tolow() {

    #arrange
    OS_VERSION='15.7'
    COMPARE_VERSIONS_RC=2

    #act
    check_0010_os_kernel_sles

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for kernel too low"
    fi
}

function test_sles_supported_kernel_ok() {

    #arrange
    OS_VERSION='15.7'
    COMPARE_VERSIONS_RC=1

    #act
    check_0010_os_kernel_sles

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for supported kernel"
    fi
}


function set_up_before_script() {

    # Disable errexit - bashunit enables it but sourced files may return non-zero
    set +eE

    # Skip if already loaded (bashunit runs all tests in same session)
    [[ -n "${_0010_test_loaded:-}" ]] && return 0
    _0010_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/0010_os_kernel_sles.check
    source "${PROGRAM_DIR}/../../lib/check/0010_os_kernel_sles.check"

}

function set_up() {

    # Reset mock variables
    OS_VERSION=
    OS_LEVEL=
    COMPARE_VERSIONS_RC=0

}

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

# Mock functions
LIB_FUNC_IS_SLES() { return 0 ; }
LIB_FUNC_IS_SLES4SAP() { return 0 ; }


function test_sles_out_of_lifetime() {

    #arrange
    OS_VERSION='11.4'

    #act
    check_0000_os_support_sles

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for SLES out of lifetime"
    fi
}

function test_sles_not_supported() {

    #arrange
    OS_VERSION='14.0'

    #act
    check_0000_os_support_sles

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for SLES not supported"
    fi
}

function test_sles_supported() {

    #arrange
    OS_VERSION='15.5'

    #act
    check_0000_os_support_sles

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for SLES supported"
    fi
}

function test_sles_not_handled() {

    #arrange
    OS_VERSION='15.9'

    #act
    check_0000_os_support_sles

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for SLES not handled"
    fi
}


function set_up_before_script() {

    # Disable errexit - bashunit enables it but sourced files may return non-zero
    set +eE

    # Skip if already loaded (bashunit runs all tests in same session)
    [[ -n "${_0000_test_loaded:-}" ]] && return 0
    _0000_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/0000_os_support_sles.check
    source "${PROGRAM_DIR}/../../lib/check/0000_os_support_sles.check"

}

function set_up() {

    # Reset mock variables
    # shellcheck disable=SC2034
    OS_VERSION=

}

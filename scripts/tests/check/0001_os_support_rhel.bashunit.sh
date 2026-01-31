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
LIB_FUNC_IS_RHEL() { return 0 ; }
LIB_FUNC_IS_RHEL4SAP() { return 0 ; }


function test_rhel_out_of_lifetime() {

    #arrange
    OS_VERSION='6.9'

    #act
    check_0001_os_support_rhel

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for RHEL out of lifetime"
    fi
}

function test_rhel_not_supported() {

    #arrange
    OS_VERSION='7.8'

    #act
    check_0001_os_support_rhel

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for RHEL not supported"
    fi
}

function test_rhel_supported() {

    #arrange
    OS_VERSION='9.2'

    #act
    check_0001_os_support_rhel

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for RHEL supported"
    fi
}

function test_rhel_not_handled() {

    #arrange
    OS_VERSION='9.9'

    #act
    check_0001_os_support_rhel

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for RHEL not handled"
    fi
}


function set_up_before_script() {

    # Disable errexit - bashunit enables it but sourced files may return non-zero
    set +eE

    # Skip if already loaded (bashunit runs all tests in same session)
    [[ -n "${_0001_test_loaded:-}" ]] && return 0
    _0001_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/0001_os_support_rhel.check
    source "${PROGRAM_DIR}/../../lib/check/0001_os_support_rhel.check"

}

function set_up() {

    # Reset mock variables
    # shellcheck disable=SC2034
    OS_VERSION=

}

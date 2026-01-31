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
IS_RHEL_RC=0
LIB_FUNC_NORMALIZE_KERNEL_RETURN=''

# Mock functions
LIB_FUNC_IS_RHEL() { return $IS_RHEL_RC ; }
LIB_FUNC_IS_CLOUD_MICROSOFT() { return 1 ; }
LIB_FUNC_IS_IBMPOWER() { return 1 ; }
LIB_FUNC_NORMALIZE_KERNEL() { LIB_FUNC_NORMALIZE_KERNEL_RETURN="$1" ; }

LIB_FUNC_COMPARE_VERSIONS() {
    # shellcheck disable=SC2086
    return $COMPARE_VERSIONS_RC ;
}


function test_rhel_kernel_with_issue() {

    #arrange
    IS_RHEL_RC=0
    OS_VERSION='9.2'
    OS_LEVEL='5.14.0-284.30.el9'
    COMPARE_VERSIONS_RC=0  # kernel equals upper boundary (not higher)

    #act
    check_0021_os_kernel_knownissues_rhel

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for kernel with known issue"
    fi
}

function test_rhel_kernel_no_issue() {

    #arrange
    IS_RHEL_RC=0
    OS_VERSION='9.2'
    OS_LEVEL='5.14.0-284.50.el9'
    COMPARE_VERSIONS_RC=1  # kernel higher than upper boundary

    #act
    check_0021_os_kernel_knownissues_rhel

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for kernel without issue"
    fi
}

function test_rhel_not_applicable() {

    #arrange
    IS_RHEL_RC=1  # not RHEL
    OS_VERSION='11.3'
    OS_LEVEL='3.0.0'

    #act
    check_0021_os_kernel_knownissues_rhel

    #assert
    if [[ $? -ne 3 ]]; then
        bashunit::fail "Expected RC=3 (skipped) for non-RHEL"
    fi
}


function set_up_before_script() {

    # Disable errexit - bashunit enables it but sourced files may return non-zero
    set +eE

    # Skip if already loaded (bashunit runs all tests in same session)
    [[ -n "${_0021_test_loaded:-}" ]] && return 0
    _0021_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/0021_os_kernel_knownissues_rhel.check
    source "${PROGRAM_DIR}/../../lib/check/0021_os_kernel_knownissues_rhel.check"

}

function set_up() {

    # Reset mock variables
    OS_VERSION=
    OS_LEVEL=
    COMPARE_VERSIONS_RC=0
    IS_RHEL_RC=0
    LIB_FUNC_NORMALIZE_KERNEL_RETURN=

}

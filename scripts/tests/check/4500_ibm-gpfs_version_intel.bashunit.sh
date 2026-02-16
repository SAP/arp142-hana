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
OS_VERSION='12.5'                   #doesn't matter
LIB_FUNC_NORMALIZE_RPM_RETURN=''    #doesn't matter
declare -i compare_version_rc=0
declare -i rpm_rc=0

# Mock functions
LIB_FUNC_IS_INTEL() { return 0 ; }
LIB_FUNC_IS_RHEL() { return 1 ; }
LIB_FUNC_IS_SLES() { return 0 ; }
LIB_FUNC_NORMALIZE_RPM() { : ; }

LIB_FUNC_COMPARE_VERSIONS() {
    # shellcheck disable=SC2086
    return $compare_version_rc ;
}

rpm() {
    return "${rpm_rc}"
}


function test_gpfs_not_installed() {

    #arrange
    rpm_rc=1

    #act
    check_4500_ibm-gpfs_version_intel

    #assert
    if [[ $? -ne 3 ]]; then
        bashunit::fail "Expected RC=3 (skipped) for GPFS not installed"
    fi
}

function test_gpfs_version_toolow() {

    #arrange
    rpm_rc=0
    compare_version_rc=2

    #act
    check_4500_ibm-gpfs_version_intel

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for GPFS version too low"
    fi
}

function test_gpfs_version_ok() {

    #arrange
    rpm_rc=0
    compare_version_rc=1

    #act
    check_4500_ibm-gpfs_version_intel

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for GPFS version ok"
    fi
}


function set_up_before_script() {

    # Disable errexit - bashunit enables it but sourced files may return non-zero
    set +eE

    # Skip if already loaded (bashunit runs all tests in same session)
    [[ -n "${_4500_test_loaded:-}" ]] && return 0
    _4500_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/4500_ibm-gpfs_version_intel.check
    source "${PROGRAM_DIR}/../../lib/check/4500_ibm-gpfs_version_intel.check"

}

function set_up() {

    # Reset mock variables
    rpm_rc=0
    compare_version_rc=0

}

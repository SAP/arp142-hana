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
OS_VERSION='15.4'
compare_version_rc=0
rpm_rc=0
isused_rc=0

# Mock functions
LIB_FUNC_IS_SLES() { return 0 ; }
LIB_FUNC_NORMALIZE_RPMn() { : ; }

LIB_FUNC_COMPARE_VERSIONS() {
    # shellcheck disable=SC2086
    return $compare_version_rc ;
}

rpm() {
    return "${rpm_rc}"
}

systemctl() {
    return "${isused_rc}"
}


function test_sapconf_not_installed() {

    #arrange
    rpm_rc=1

    #act
    check_0440_sapconf_sles

    #assert
    if [[ $? -ne 3 ]]; then
        bashunit::fail "Expected RC=3 (skipped) for sapconf not installed"
    fi
}

function test_sapconf_ok() {

    #arrange
    rpm_rc=0
    compare_version_rc=1

    #act
    check_0440_sapconf_sles

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for sapconf ok"
    fi
}

function test_sapconf_old_but_not_used() {

    #arrange
    rpm_rc=0
    compare_version_rc=2
    isused_rc=1

    #act
    check_0440_sapconf_sles

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for sapconf old but not used"
    fi
}

function test_sapconf_old_and_used() {

    #arrange
    rpm_rc=0
    compare_version_rc=2
    isused_rc=0

    #act
    check_0440_sapconf_sles

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for sapconf old and used"
    fi
}


function set_up_before_script() {

    # Disable errexit - bashunit enables it but sourced files may return non-zero
    set +eE

    # Skip if already loaded (bashunit runs all tests in same session)
    [[ -n "${_0440_test_loaded:-}" ]] && return 0
    _0440_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/0440_sapconf_sles.check
    source "${PROGRAM_DIR}/../../lib/check/0440_sapconf_sles.check"

}

function set_up() {

    # Reset mock variables
    OS_VERSION='15.4'
    compare_version_rc=0
    rpm_rc=0
    isused_rc=0

}

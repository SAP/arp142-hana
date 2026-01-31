#!/usr/bin/env bash
#------------------------------------------------------------------
# bashunit migration: 7010_corosync_version_test.sh
# Tests for Corosync version check
#------------------------------------------------------------------
set -u

if [[ -z "${PROGRAM_DIR:-}" ]]; then
    PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
    [[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
fi

# Guard to avoid reloading
[[ -n "${_7010_corosync_version_test_loaded:-}" ]] && return 0
_7010_corosync_version_test_loaded=true

#mock PREREQUISITE functions
LIB_FUNC_IS_SLES() { return 0 ; }
LIB_FUNC_NORMALIZE_RPM() { : ; }

LIB_FUNC_COMPARE_VERSIONS() { return "$compare_version_rc" ; }
rpm() { return "${rpm_rc}" ; }
systemctl() { return "${isused_rc}" ; }

OS_VERSION=''
LIB_FUNC_NORMALIZE_RPM_RETURN=''
declare -i compare_version_rc=0
declare -i rpm_rc=0
declare -i isused_rc=0

function test_rpm_not_installed() {
    #arrange
    rpm_rc=1

    #act
    check_7010_corosync_version
    local rc=$?

    #assert
    if [[ "$rc" != '3' ]]; then
        bashunit::fail "Expected CheckSkipped RC=3 but got RC=$rc"
    fi
}

function test_OS_not_applicable() {
    #arrange
    rpm_rc=0
    OS_VERSION='11.4'

    #act
    check_7010_corosync_version
    local rc=$?

    #assert
    if [[ "$rc" != '3' ]]; then
        bashunit::fail "Expected CheckSkipped RC=3 but got RC=$rc"
    fi
}

function test_OS_not_listed() {
    #arrange
    rpm_rc=0
    OS_VERSION='14.0'

    #act
    check_7010_corosync_version
    local rc=$?

    #assert
    if [[ "$rc" != '3' ]]; then
        bashunit::fail "Expected CheckSkipped RC=3 but got RC=$rc"
    fi
}

function test_rpm_ok_sles12all() {
    #arrange
    rpm_rc=0
    OS_VERSION='12.5'       #test against 12.*
    compare_version_rc=1

    #act
    check_7010_corosync_version
    local rc=$?

    #assert
    if [[ "$rc" != '0' ]]; then
        bashunit::fail "Expected CheckOk RC=0 but got RC=$rc"
    fi
}

function test_rpm_ok_sles152() {
    #arrange
    rpm_rc=0
    OS_VERSION='15.3'       #test against 15.3
    compare_version_rc=1

    #act
    check_7010_corosync_version
    local rc=$?

    #assert
    if [[ "$rc" != '0' ]]; then
        bashunit::fail "Expected CheckOk RC=0 but got RC=$rc"
    fi
}

function test_rpm_old_but_not_used() {
    #arrange
    rpm_rc=0
    OS_VERSION='15.3'
    compare_version_rc=2
    isused_rc=1

    #act
    check_7010_corosync_version
    local rc=$?

    #assert
    if [[ "$rc" != '1' ]]; then
        bashunit::fail "Expected CheckWarning RC=1 but got RC=$rc"
    fi
}

function test_rpm_old_and_used() {
    #arrange
    rpm_rc=0
    OS_VERSION='15.3'
    compare_version_rc=2
    isused_rc=0

    #act
    check_7010_corosync_version
    local rc=$?

    #assert
    if [[ "$rc" != '2' ]]; then
        bashunit::fail "Expected CheckError RC=2 but got RC=$rc"
    fi
}

function set_up_before_script() {
    set +eE

    [[ -n "${HANA_HELPER_PROGVERSION:-}" ]] && return 0

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/7010_corosync_version.check
    source "${PROGRAM_DIR}/../../lib/check/7010_corosync_version.check"
}

function set_up() {
    OS_VERSION=''
    rpm_rc=0
    compare_version_rc=0
    isused_rc=0
}

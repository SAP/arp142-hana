#!/usr/bin/env bash
#------------------------------------------------------------------
# bashunit migration: 7015_pacemaker_version_test.sh
# Tests for Pacemaker version check
#------------------------------------------------------------------
set -u

if [[ -z "${PROGRAM_DIR:-}" ]]; then
    PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
    [[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
fi

# Guard to avoid reloading
[[ -n "${_7015_pacemaker_version_test_loaded:-}" ]] && return 0
_7015_pacemaker_version_test_loaded=true

#mock PREREQUISITE functions
LIB_FUNC_IS_SLES() { return 0 ; }
LIB_FUNC_IS_RHEL() { return 1 ; }
LIB_FUNC_NORMALIZE_RPMn() { : ; }

LIB_FUNC_COMPARE_VERSIONS() { return "$compare_version_rc" ; }

rpm() {
    if [[ "$1" == "-q" && "$2" == "--quiet" ]]; then
        return "${rpm_installed_rc}"
    elif [[ "$1" == "-q" && "$2" == "--queryformat" ]]; then
        printf "%s\n" "${rpm_version_output}"
        return 0
    else
        return 1
    fi
}

systemctl() {
    if [[ "$1" == "is-enabled" && "$2" == "pacemaker" ]]; then
        return "${systemctl_enabled_rc}"
    elif [[ "$1" == "is-active" && "$2" == "pacemaker" ]]; then
        return "${systemctl_active_rc}"
    else
        return 1
    fi
}

OS_VERSION=''
declare -i compare_version_rc=0
declare -i rpm_installed_rc=0
declare -i systemctl_enabled_rc=0
declare -i systemctl_active_rc=0
declare rpm_version_output=''

function test_pacemaker_not_installed() {
    #arrange
    rpm_installed_rc=1

    #act
    check_7015_pacemaker_version
    local rc=$?

    #assert
    if [[ "$rc" != '3' ]]; then
        bashunit::fail "Expected CheckSkipped RC=3 but got RC=$rc"
    fi
}

function test_rhel_os_not_applicable() {
    #arrange
    LIB_FUNC_IS_SLES() { return 1 ; }
    LIB_FUNC_IS_RHEL() { return 0 ; }
    rpm_installed_rc=0

    #act
    check_7015_pacemaker_version
    local rc=$?

    #assert
    if [[ "$rc" != '3' ]]; then
        bashunit::fail "Expected CheckSkipped RC=3 but got RC=$rc"
    fi
}

function test_sles_version_not_handled() {
    #arrange
    rpm_installed_rc=0
    OS_VERSION='14.0'
    systemctl_enabled_rc=1
    systemctl_active_rc=1

    #act
    check_7015_pacemaker_version
    local rc=$?

    #assert
    if [[ "$rc" != '3' ]]; then
        bashunit::fail "Expected CheckSkipped RC=3 but got RC=$rc"
    fi
}

function test_sles15_5_version_ok_enabled_and_active() {
    #arrange
    rpm_installed_rc=0
    OS_VERSION='15.5'
    rpm_version_output='2.1.5+20221208.a3f44794f-150500.99.99.1'
    compare_version_rc=1  # current version is higher than required
    systemctl_enabled_rc=0  # enabled
    systemctl_active_rc=0   # active

    #act
    check_7015_pacemaker_version
    local rc=$?

    #assert
    if [[ "$rc" != '0' ]]; then
        bashunit::fail "Expected CheckOk RC=0 but got RC=$rc"
    fi
}

function test_sles15_6_version_ok_not_used() {
    #arrange
    rpm_installed_rc=0
    OS_VERSION='15.6'
    rpm_version_output='2.1.7+20231219.0f7f88312-150600.99.99.1'
    compare_version_rc=1  # current version is higher than required
    systemctl_enabled_rc=1  # not enabled
    systemctl_active_rc=1   # not active

    #act
    check_7015_pacemaker_version
    local rc=$?

    #assert
    if [[ "$rc" != '0' ]]; then
        bashunit::fail "Expected CheckOk RC=0 but got RC=$rc"
    fi
}

function test_sles15_7_version_ok_equal() {
    #arrange
    rpm_installed_rc=0
    OS_VERSION='15.7'
    rpm_version_output='2.1.10+20250718.fdf796ebc8-150700.3.3.1'
    compare_version_rc=0  # versions are equal
    systemctl_enabled_rc=0  # enabled
    systemctl_active_rc=1   # not active

    #act
    check_7015_pacemaker_version
    local rc=$?

    #assert
    if [[ "$rc" != '0' ]]; then
        bashunit::fail "Expected CheckOk RC=0 but got RC=$rc"
    fi
}

function test_sles15_5_version_old_pacemaker_enabled() {
    #arrange
    rpm_installed_rc=0
    OS_VERSION='15.5'
    rpm_version_output='2.1.5+20221208.a3f44794f-150500.6.20.1'
    compare_version_rc=2  # current version is lower than required
    systemctl_enabled_rc=0  # enabled
    systemctl_active_rc=1   # not active

    #act
    check_7015_pacemaker_version
    local rc=$?

    #assert
    if [[ "$rc" != '2' ]]; then
        bashunit::fail "Expected CheckError RC=2 but got RC=$rc"
    fi
}

function test_sles15_6_version_old_pacemaker_active() {
    #arrange
    rpm_installed_rc=0
    OS_VERSION='15.6'
    rpm_version_output='2.1.7+20231219.0f7f88312-150600.6.10.1'
    compare_version_rc=2  # current version is lower than required
    systemctl_enabled_rc=1  # not enabled
    systemctl_active_rc=0   # active

    #act
    check_7015_pacemaker_version
    local rc=$?

    #assert
    if [[ "$rc" != '2' ]]; then
        bashunit::fail "Expected CheckError RC=2 but got RC=$rc"
    fi
}

function test_sles15_7_version_old_pacemaker_not_used() {
    #arrange
    rpm_installed_rc=0
    OS_VERSION='15.7'
    rpm_version_output='2.1.10+20250718.fdf796ebc8-150700.3.2.1'
    compare_version_rc=2  # current version is lower than required
    systemctl_enabled_rc=1  # not enabled
    systemctl_active_rc=1   # not active

    #act
    check_7015_pacemaker_version
    local rc=$?

    #assert
    if [[ "$rc" != '1' ]]; then
        bashunit::fail "Expected CheckWarning RC=1 but got RC=$rc"
    fi
}

function test_sles15_5_version_old_both_enabled_and_active() {
    #arrange
    rpm_installed_rc=0
    OS_VERSION='15.5'
    rpm_version_output='2.1.4+20220407.b2935090a-150500.6.15.1'
    compare_version_rc=2  # current version is lower than required
    systemctl_enabled_rc=0  # enabled
    systemctl_active_rc=0   # active

    #act
    check_7015_pacemaker_version
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

    #shellcheck source=../../lib/check/7015_pacemaker_version.check
    source "${PROGRAM_DIR}/../../lib/check/7015_pacemaker_version.check"
}

function set_up() {
    # Reset all mock variables
    OS_VERSION=''
    compare_version_rc=0
    rpm_installed_rc=0
    systemctl_enabled_rc=0
    systemctl_active_rc=0
    rpm_version_output=''

    # Reset function mocks to defaults
    LIB_FUNC_IS_SLES() { return 0 ; }
    LIB_FUNC_IS_RHEL() { return 1 ; }
}

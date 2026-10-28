#!/usr/bin/env bash
#------------------------------------------------------------------
# Tests for HA resource agent (HANA) check on RHEL
#------------------------------------------------------------------
set -u

if [[ -z "${PROGRAM_DIR:-}" ]]; then
    PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
    [[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
fi

#mock PREREQUISITE functions
LIB_FUNC_IS_RHEL() { return 0 ; }
LIB_FUNC_NORMALIZE_RPM() { : ; }

LIB_FUNC_COMPARE_VERSIONS() { return "$compare_version_rc" ; }
rpm() { return "${rpm_rc}" ; }

OS_VERSION=''
LIB_FUNC_NORMALIZE_RPM_RETURN=''
declare -i compare_version_rc=0
declare -i rpm_rc=0

assert_check_processed() {
    local rc=$1
    local context="${2:-}"
    assert_not_equals 99 "${rc}" "Check must be processed${context:+ in }${context}"
}

function test_not_rhel() {
    #arrange
    LIB_FUNC_IS_RHEL() { return 1 ; }

    #act
    check_7032_ha_resource_agent_hana_rhel
    local rc=$?

    #assert
    assert_check_processed "${rc}" 'not RHEL'
    assert_exit_code 3 'Expected CheckSkipped RC=3' "${rc}"
}

function test_rpm_not_installed() {
    #arrange
    rpm_rc=1

    #act
    check_7032_ha_resource_agent_hana_rhel
    local rc=$?

    #assert
    assert_check_processed "${rc}" 'package not installed'
    assert_exit_code 3 'Expected CheckSkipped RC=3' "${rc}"
}

function test_OS_not_listed() {
    #arrange
    rpm_rc=0
    OS_VERSION='8.10'

    #act
    check_7032_ha_resource_agent_hana_rhel
    local rc=$?

    #assert
    assert_check_processed "${rc}" 'unsupported OS release'
    assert_exit_code 1 'Expected CheckWarning RC=1' "${rc}"
}

function test_rpm_ok() {
    #arrange
    rpm_rc=0
    OS_VERSION='9.4'
    compare_version_rc=1

    #act
    check_7032_ha_resource_agent_hana_rhel
    local rc=$?

    #assert
    assert_check_processed "${rc}" 'package version accepted'
    assert_exit_code 0 'Expected CheckOk RC=0' "${rc}"
}

function test_rpm_old() {
    #arrange
    rpm_rc=0
    OS_VERSION='9.6'
    compare_version_rc=2

    #act
    check_7032_ha_resource_agent_hana_rhel
    local rc=$?

    #assert
    assert_check_processed "${rc}" 'package version too old'
    assert_exit_code 1 'Expected CheckWarning RC=1' "${rc}"
}

function test_rhel10_rpm_ok() {
    #arrange
    rpm_rc=0
    OS_VERSION='10.0'
    compare_version_rc=0

    #act
    check_7032_ha_resource_agent_hana_rhel
    local rc=$?

    #assert
    assert_check_processed "${rc}" 'RHEL 10.0'
    assert_exit_code 0 'Expected CheckOk RC=0 for RHEL 10.0' "${rc}"
}

function test_rhel102_rpm_ok() {
    #arrange
    rpm_rc=0
    OS_VERSION='10.2'
    compare_version_rc=0

    #act
    check_7032_ha_resource_agent_hana_rhel
    local rc=$?

    #assert
    assert_check_processed "${rc}" 'RHEL 10.2'
    assert_exit_code 0 'Expected CheckOk RC=0 for RHEL 10.2' "${rc}"
}

function set_up_before_script() {
    set +eE

    [[ -n "${_7032_test_loaded:-}" ]] && return 0
    _7032_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/7032_ha_resource_agent_hana_rhel.check
    source "${PROGRAM_DIR}/../../lib/check/7032_ha_resource_agent_hana_rhel.check"
}

function set_up() {
    OS_VERSION=''
    rpm_rc=0
    compare_version_rc=0
    LIB_FUNC_IS_RHEL() { return 0 ; }
}

#!/usr/bin/env bash
#------------------------------------------------------------------
# bashunit migration: 7031_ha_resource_agent_scaleout_rhel_test.sh
# Tests for HA resource agent check on RHEL (scale-out)
#------------------------------------------------------------------
set -u

if [[ -z "${PROGRAM_DIR:-}" ]]; then
    PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
    [[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
fi

# Guard to avoid reloading
[[ -n "${_7031_ha_resource_agent_scaleout_rhel_test_loaded:-}" ]] && return 0
_7031_ha_resource_agent_scaleout_rhel_test_loaded=true

#mock PREREQUISITE functions
LIB_FUNC_IS_RHEL() { return 0 ; }
LIB_FUNC_NORMALIZE_RPM() { : ; }

LIB_FUNC_COMPARE_VERSIONS() { return "$compare_version_rc" ; }
rpm() { return "${rpm_rc}" ; }

OS_VERSION=''
LIB_FUNC_NORMALIZE_RPM_RETURN=''
declare -i compare_version_rc=0
declare -i rpm_rc=0

function test_rpm_not_installed() {
    #arrange
    rpm_rc=1

    #act
    check_7031_ha_resource_agent_scaleout_rhel
    local rc=$?

    #assert
    if [[ "$rc" != '3' ]]; then
        bashunit::fail "Expected CheckSkipped RC=3 but got RC=$rc"
    fi
}

function test_OS_not_listed() {
    #arrange
    rpm_rc=0
    OS_VERSION='6.5'

    #act
    check_7031_ha_resource_agent_scaleout_rhel
    local rc=$?

    #assert
    if [[ "$rc" != '1' ]]; then
        bashunit::fail "Expected CheckWarning RC=1 but got RC=$rc"
    fi
}

function test_rpm_ok() {
    #arrange
    rpm_rc=0
    OS_VERSION='7.9'
    compare_version_rc=1

    #act
    check_7031_ha_resource_agent_scaleout_rhel
    local rc=$?

    #assert
    if [[ "$rc" != '0' ]]; then
        bashunit::fail "Expected CheckOk RC=0 but got RC=$rc"
    fi
}

function test_rpm_old() {
    #arrange
    rpm_rc=0
    OS_VERSION='8.10'
    compare_version_rc=2

    #act
    check_7031_ha_resource_agent_scaleout_rhel
    local rc=$?

    #assert
    if [[ "$rc" != '1' ]]; then
        bashunit::fail "Expected CheckWarning RC=1 but got RC=$rc"
    fi
}

function set_up_before_script() {
    set +eE

    [[ -n "${HANA_HELPER_PROGVERSION:-}" ]] && return 0

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/7031_ha_resource_agent_scaleout_rhel.check
    source "${PROGRAM_DIR}/../../lib/check/7031_ha_resource_agent_scaleout_rhel.check"
}

function set_up() {
    OS_VERSION=''
    rpm_rc=0
    compare_version_rc=0
}

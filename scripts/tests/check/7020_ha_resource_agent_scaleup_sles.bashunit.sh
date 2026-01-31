#!/usr/bin/env bash
#------------------------------------------------------------------
# bashunit migration: 7020_ha_resource_agent_scaleup_sles_test.sh
# Tests for HA resource agent check on SLES (scale-up)
#------------------------------------------------------------------
set -u

if [[ -z "${PROGRAM_DIR:-}" ]]; then
    PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
    [[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
fi

# Guard to avoid reloading
[[ -n "${_7020_ha_resource_agent_sles_test_loaded:-}" ]] && return 0
_7020_ha_resource_agent_sles_test_loaded=true

#mock PREREQUISITE functions
LIB_FUNC_IS_SLES() { return 0 ; }
LIB_FUNC_NORMALIZE_RPMn() { : ; }

LIB_FUNC_COMPARE_VERSIONS() { return "$compare_version_rc" ; }
rpm() { return "${rpm_rc}" ; }

OS_VERSION=''
declare -i compare_version_rc=0
declare -i rpm_rc=0

function test_rpm_not_installed() {
    #arrange
    rpm_rc=1

    #act
    check_7020_ha_resource_agents_sles
    local rc=$?

    #assert
    if [[ "$rc" != '3' ]]; then
        bashunit::fail "Expected CheckSkipped RC=3 but got RC=$rc"
    fi
}

function test_rpm_ok() {
    #arrange
    rpm_rc=0
    OS_VERSION='12.5'
    compare_version_rc=1

    #act
    check_7020_ha_resource_agents_sles
    local rc=$?

    #assert
    if [[ "$rc" != '0' ]]; then
        bashunit::fail "Expected CheckOk RC=0 but got RC=$rc"
    fi
}

function test_rpm_old() {
    #arrange
    rpm_rc=0
    OS_VERSION='15.5'
    compare_version_rc=2

    #act
    check_7020_ha_resource_agents_sles
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

    #shellcheck source=../../lib/check/7020_ha_resource_agents_sles.check
    source "${PROGRAM_DIR}/../../lib/check/7020_ha_resource_agents_sles.check"
}

function set_up() {
    OS_VERSION=''
    rpm_rc=0
    compare_version_rc=0
}

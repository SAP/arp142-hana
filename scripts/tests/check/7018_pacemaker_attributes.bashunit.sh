#!/usr/bin/env bash
#------------------------------------------------------------------
# bashunit migration: 7018_pacemaker_attributes_test.sh
# Tests for pacemaker attributes check
#------------------------------------------------------------------
set -u

if [[ -z "${PROGRAM_DIR:-}" ]]; then
    PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
    [[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
fi

# Guard to avoid reloading
[[ -n "${_7018_pacemaker_attributes_test_loaded:-}" ]] && return 0
_7018_pacemaker_attributes_test_loaded=true

#mock PREREQUISITE functions
LIB_FUNC_IS_SLES() { return 0 ; }
LIB_FUNC_IS_RHEL() { return 1 ; }

systemctl() { return "${systemctl_rc}" ; }
command() {
    if [[ "$1" == "-v" && "$2" == "cibadmin" ]]; then
        [[ "${command_rc}" -eq 0 ]] && echo "/bin/bash"
        return "${command_rc}"
    fi
    builtin command "$@"
}

cibadmin() { printf '%s\n' "${cibadmin_output}" ; }

path_to_pacemaker_config=''
declare -i systemctl_rc=0
declare -i command_rc=0
declare cibadmin_output=''

function set_up_before_script() {
    set +eE

    [[ -n "${HANA_HELPER_PROGVERSION:-}" ]] && return 0

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/7018_pacemaker_attributes.check
    source "${PROGRAM_DIR}/../../lib/check/7018_pacemaker_attributes.check"
}

function set_up() {
    path_to_pacemaker_config="${PROGRAM_DIR}/mock_pacemaker_config"
    echo '' > "${path_to_pacemaker_config}"
    systemctl_rc=0
    command_rc=0
    cibadmin_output=''
    LIB_FUNC_IS_SLES() { return 0 ; }
    LIB_FUNC_IS_RHEL() { return 1 ; }
}

function tear_down() {
    if [[ -f "${path_to_pacemaker_config}" ]]; then
        rm -f "${path_to_pacemaker_config}"
    fi
}

function test_pacemaker_not_installed() {
    #arrange
    rm -f "${path_to_pacemaker_config}"

    #act
    check_7018_pacemaker_attributes
    local rc=$?

    #assert
    if [[ "$rc" != '3' ]]; then
        bashunit::fail "Expected CheckSkipped RC=3 but got RC=$rc"
    fi
    assert_true true
}

function test_pacemaker_not_active() {
    #arrange
    systemctl_rc=1

    #act
    check_7018_pacemaker_attributes
    local rc=$?

    #assert
    if [[ "$rc" != '3' ]]; then
        bashunit::fail "Expected CheckSkipped RC=3 but got RC=$rc"
    fi
    assert_true true
}

function test_cibadmin_not_installed() {
    #arrange
    command_rc=1

    #act
    check_7018_pacemaker_attributes
    local rc=$?

    #assert
    if [[ "$rc" != '3' ]]; then
        bashunit::fail "Expected CheckSkipped RC=3 but got RC=$rc"
    fi
    assert_true true
}

function test_attributes_ok() {
    #arrange
    cibadmin_output='<nvpair id="rsc-options-resource-stickiness" name="resource-stickiness" value="1000"/>
<nvpair id="rsc-options-migration-threshold" name="migration-threshold" value="5000"/>'

    #act
    check_7018_pacemaker_attributes
    local rc=$?

    #assert
    if [[ "$rc" != '0' ]]; then
        bashunit::fail "Expected CheckOk RC=0 but got RC=$rc"
    fi
    assert_true true
}

function test_attributes_wrong() {
    #arrange
    cibadmin_output='<nvpair id="rsc-options-resource-stickiness" name="resource-stickiness" value="100"/>
<nvpair id="rsc-options-migration-threshold" name="migration-threshold" value="5000"/>'

    #act
    check_7018_pacemaker_attributes
    local rc=$?

    #assert
    if [[ "$rc" != '1' ]]; then
        bashunit::fail "Expected CheckWarning RC=1 but got RC=$rc"
    fi
    assert_true true
}

function test_attributes_missing() {
    #arrange
    cibadmin_output='<rsc_defaults> </rsc_defaults>'

    #act
    check_7018_pacemaker_attributes
    local rc=$?

    #assert
    if [[ "$rc" != '2' ]]; then
        bashunit::fail "Expected CheckError RC=2 but got RC=$rc"
    fi
    assert_true true
}

#!/usr/bin/env bash
#------------------------------------------------------------------
# bashunit test for check_3306_vnic_interfaces_ibmpower
#
# IMPORTANT: Every test MUST verify that RC != 99
# RC=99 means "check never reached a conclusion" - this is a BUG!
#------------------------------------------------------------------
set -u  # treat unset variables as an error

if [[ -z "${PROGRAM_DIR:-}" ]]; then
    PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
    [[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
fi

# Mock variables
if_vnic=()

# Mock functions
LIB_FUNC_IS_IBMPOWER() { return 0 ; }

grep() {
    #we fake (grep DRIVER=ibmvnic -rsH /sys/class/net/**/device/uevent)
    case "$*" in
        *'DRIVER=ibmvnic'*'uevent')  [[ ${#if_vnic[@]} -eq 0 ]] && : || printf "%s\n" "${if_vnic[@]}" ;;
        *)          command grep "$@" ;; # bashunit requires grep
    esac
}

#------------------------------------------------------------------
# Helper function: Assert check was processed (RC != 99)
# Use this in EVERY test to catch silent failures early!
#------------------------------------------------------------------
assert_check_processed() {
    local rc=$1
    local context="${2:-}"
    assert_not_equals 99 "${rc}" "Check must be processed${context:+ in }${context}"
}

function test_0interface_error() {
    #arrange
    if_vnic=()

    #act
    check_3306_vnic_interfaces_ibmpower
    local rc=$?

    #assert
    assert_check_processed ${rc} "0 vnic interfaces"
    assert_exit_code 2 '' "${rc}"
}

function test_1interface_warning() {
    #arrange
    if_vnic=()
    if_vnic+=('/sys/class/net/eth0/device/uevent:DRIVER=ibmvnic')

    #act
    check_3306_vnic_interfaces_ibmpower
    local rc=$?

    #assert
    assert_check_processed ${rc} "1 vnic interface"
    assert_exit_code 1 '' "${rc}"
}

function test_2interfaces_ok() {
    #arrange
    if_vnic=()
    if_vnic+=('/sys/class/net/eth0/device/uevent:DRIVER=ibmvnic')
    if_vnic+=('/sys/class/net/eth1/device/uevent:DRIVER=ibmvnic')

    #act
    check_3306_vnic_interfaces_ibmpower
    local rc=$?

    #assert
    assert_check_processed ${rc} "2 vnic interfaces"
    assert_exit_code 0 '' "${rc}"
}

function test_4interfaces_ok() {
    #arrange
    if_vnic=()
    if_vnic+=('/sys/class/net/eth0/device/uevent:DRIVER=ibmvnic')
    if_vnic+=('/sys/class/net/eth1/device/uevent:DRIVER=ibmvnic')
    if_vnic+=('/sys/class/net/eth2/device/uevent:DRIVER=ibmvnic')
    if_vnic+=('/sys/class/net/eth3/device/uevent:DRIVER=ibmvnic')

    #act
    check_3306_vnic_interfaces_ibmpower
    local rc=$?

    #assert
    assert_check_processed ${rc} "4 vnic interfaces"
    assert_exit_code 0 '' "${rc}"
}

function test_not_ibmpower_skip() {
    #arrange
    if_vnic=()
    LIB_FUNC_IS_IBMPOWER() { return 1 ; }

    #act
    check_3306_vnic_interfaces_ibmpower
    local rc=$?

    #assert
    assert_check_processed ${rc} "non-IBM Power"
    assert_exit_code 3 '' "${rc}"
}


function set_up_before_script() {
    # Disable errexit - bashunit enables it but sourced files may return non-zero
    set +eE

    # CRITICAL: Guard inside set_up_before_script! Use _NNNN_test_loaded format
    # Do NOT use HANA_HELPER_PROGVERSION - it breaks other tests
    [[ -n "${_3306_test_loaded:-}" ]] && return 0
    _3306_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/3306_vnic_interfaces_ibmpower.check
    source "${PROGRAM_DIR}/../../lib/check/3306_vnic_interfaces_ibmpower.check"
}

function set_up() {
    # Reset mock variables before each test
    if_vnic=()
    LIB_FUNC_IS_IBMPOWER() { return 0 ; }
}

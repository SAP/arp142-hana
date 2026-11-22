#!/usr/bin/env bash
#------------------------------------------------------------------
# bashunit test for check_3301_aan_interfaces_azure
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
if_aan=()

# Mock functions
LIB_FUNC_IS_CLOUD_MICROSOFT() { return 0 ; }

grep() {
    #we fake (grep DRIVER=mana -rsH /sys/class/net/**/device/uevent)
    case "$*" in
        *'uevent')  [[ ${#if_aan[@]} -eq 0 ]] && : || printf "%s\n" "${if_aan[@]}" ;;
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
    if_aan=()

    #act
    check_3301_aan_interfaces_azure
    local rc=$?

    #assert
    assert_check_processed ${rc} "0 interfaces"
    assert_exit_code 2 '' "${rc}"
}

function test_1pair_warning() {
    #arrange
    if_aan=()
    if_aan+=('/sys/class/net/eth0/device/uevent:DRIVER=hv_netvsc')
    if_aan+=('/sys/class/net/eth1/device/uevent:DRIVER=mana')

    #act
    check_3301_aan_interfaces_azure
    local rc=$?

    #assert
    assert_check_processed ${rc} "1 AAN + 1 synthetic pair"
    assert_exit_code 1 '' "${rc}"
}

function test_single_aan_without_pair_error() {
    #arrange
    if_aan=()
    if_aan+=('/sys/class/net/eth0/device/uevent:DRIVER=mana')

    #act
    check_3301_aan_interfaces_azure
    local rc=$?

    #assert
    assert_check_processed ${rc} "single AAN without synthetic pair"
    assert_exit_code 2 '' "${rc}"
}

function test_2pairs_ok() {
    #arrange
    if_aan=()
    if_aan+=('/sys/class/net/eth0/device/uevent:DRIVER=hv_netvsc')
    if_aan+=('/sys/class/net/eth1/device/uevent:DRIVER=mana')
    if_aan+=('/sys/class/net/eth2/device/uevent:DRIVER=hv_netvsc')
    if_aan+=('/sys/class/net/eth3/device/uevent:DRIVER=mlx')

    #act
    check_3301_aan_interfaces_azure
    local rc=$?

    #assert
    assert_check_processed ${rc} "2 AAN + 2 synthetic pairs"
    assert_exit_code 0 '' "${rc}"
}

function test_4pairs_ok() {
    #arrange
    if_aan=()
    if_aan+=('/sys/class/net/eth0/device/uevent:DRIVER=hv_netvsc')
    if_aan+=('/sys/class/net/eth1/device/uevent:DRIVER=mana')
    if_aan+=('/sys/class/net/eth2/device/uevent:DRIVER=hv_netvsc')
    if_aan+=('/sys/class/net/eth3/device/uevent:DRIVER=mlx')
    if_aan+=('/sys/class/net/eth4/device/uevent:DRIVER=hv_netvsc')
    if_aan+=('/sys/class/net/eth5/device/uevent:DRIVER=mlx')
    if_aan+=('/sys/class/net/eth6/device/uevent:DRIVER=hv_netvsc')
    if_aan+=('/sys/class/net/eth7/device/uevent:DRIVER=mana')

    #act
    check_3301_aan_interfaces_azure
    local rc=$?

    #assert
    assert_check_processed ${rc} "4 AAN + 4 synthetic pairs"
    assert_exit_code 0 '' "${rc}"
}

function test_only_synthetic_error() {
    #arrange
    if_aan=()
    if_aan+=('/sys/class/net/eth0/device/uevent:DRIVER=hv_netvsc')
    if_aan+=('/sys/class/net/eth1/device/uevent:DRIVER=hv_netvsc')

    #act
    check_3301_aan_interfaces_azure
    local rc=$?

    #assert
    assert_check_processed ${rc} "only synthetic interfaces"
    assert_exit_code 2 '' "${rc}"
}

function test_partial_aan_error() {
    #arrange
    if_aan=()
    if_aan+=('/sys/class/net/eth0/device/uevent:DRIVER=hv_netvsc')
    if_aan+=('/sys/class/net/eth1/device/uevent:DRIVER=mana')
    if_aan+=('/sys/class/net/eth2/device/uevent:DRIVER=hv_netvsc')

    #act
    check_3301_aan_interfaces_azure
    local rc=$?

    #assert
    assert_check_processed ${rc} "partial AAN enablement"
    assert_exit_code 2 '' "${rc}"
}

function test_not_azure_skip() {
    #arrange
    if_aan=()
    LIB_FUNC_IS_CLOUD_MICROSOFT() { return 1 ; }

    #act
    check_3301_aan_interfaces_azure
    local rc=$?

    #assert
    assert_check_processed ${rc} "non-Azure"
    assert_exit_code 3 '' "${rc}"
}


function set_up_before_script() {
    # Disable errexit - bashunit enables it but sourced files may return non-zero
    set +eE

    # CRITICAL: Guard inside set_up_before_script! Use _NNNN_test_loaded format
    # Do NOT use HANA_HELPER_PROGVERSION - it breaks other tests
    [[ -n "${_3301_test_loaded:-}" ]] && return 0
    _3301_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/3301_aan_interfaces_azure.check
    source "${PROGRAM_DIR}/../../lib/check/3301_aan_interfaces_azure.check"
}


function set_up() {
    # Reset mock variables before each test
    if_aan=()
    LIB_FUNC_IS_CLOUD_MICROSOFT() { return 0 ; }
}

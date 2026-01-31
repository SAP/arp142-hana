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


function test_0interface_error() {

    #arrange
    if_aan=()

    #act
    check_3301_network_accelerated_azure

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for 0 interfaces"
    fi
}

function test_1interface_ok() {

    #arrange
    if_aan=()
    if_aan+=('/sys/class/net/eth0/device/uevent:DRIVER=mana')

    #act
    check_3301_network_accelerated_azure

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for 1 interface"
    fi
}

function test_2interfaces_ok() {

    #arrange
    if_aan=()
    if_aan+=('/sys/class/net/eth0/device/uevent:DRIVER=mana')
    if_aan+=('/sys/class/net/eth1/device/uevent:DRIVER=mlx')

    #act
    check_3301_network_accelerated_azure

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for 2 interfaces"
    fi
}

function test_4interfaces_ok() {

    #arrange
    if_aan=()
    if_aan+=('/sys/class/net/eth0/device/uevent:DRIVER=mana')
    if_aan+=('/sys/class/net/eth1/device/uevent:DRIVER=mlx')
    if_aan+=('/sys/class/net/eth2/device/uevent:DRIVER=mlx')
    if_aan+=('/sys/class/net/eth4/device/uevent:DRIVER=mana')

    #act
    check_3301_network_accelerated_azure

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for 4 interfaces"
    fi
}


function set_up_before_script() {

    # Disable errexit - bashunit enables it but sourced files may return non-zero
    set +eE

    # Skip if already loaded (bashunit runs all tests in same session)
    [[ -n "${_3301_test_loaded:-}" ]] && return 0
    _3301_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/3301_network_accelerated_azure.check
    source "${PROGRAM_DIR}/../../lib/check/3301_network_accelerated_azure.check"

}

function set_up() {

    # Reset mock variables
    if_aan=()

}

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
if_vmxnet3=()

# Mock functions
LIB_FUNC_IS_VIRT_VMWARE() { return 0 ; }

grep() {

    #we fake (grep DRIVER=vmxnet3 -rsH /sys/class/net/**/device/uevent)
    case "$*" in
        *'uevent')  [[ ${#if_vmxnet3[@]} -eq 0 ]] && : || printf "%s\n" "${if_vmxnet3[@]}" ;;

        *)          command grep "$@" ;; # bashunit requires grep
    esac
}


function test_0interface_error() {

    #arrange
    if_vmxnet3=()

    #act
    check_3309_vmxnet3_interfaces_vmware

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for 0 interfaces"
    fi
}

function test_1interface_warning() {

    #arrange
    if_vmxnet3=()
    if_vmxnet3+=('/sys/class/net/eth0/device/uevent:DRIVER=vmxnet3')

    #act
    check_3309_vmxnet3_interfaces_vmware

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for 1 interface"
    fi
}

function test_2interfaces_ok() {

    #arrange
    if_vmxnet3=()
    if_vmxnet3+=('/sys/class/net/eth0/device/uevent:DRIVER=vmxnet3')
    if_vmxnet3+=('/sys/class/net/eth1/device/uevent:DRIVER=vmxnet3')

    #act
    check_3309_vmxnet3_interfaces_vmware

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for 2 interfaces"
    fi
}

function test_4interfaces_ok() {

    #arrange
    if_vmxnet3=()
    if_vmxnet3+=('/sys/class/net/eth0/device/uevent:DRIVER=vmxnet3')
    if_vmxnet3+=('/sys/class/net/eth1/device/uevent:DRIVER=vmxnet3')
    if_vmxnet3+=('/sys/class/net/eth2/device/uevent:DRIVER=vmxnet3')
    if_vmxnet3+=('/sys/class/net/eth4/device/uevent:DRIVER=vmxnet3')

    #act
    check_3309_vmxnet3_interfaces_vmware

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for 4 interfaces"
    fi
}


function set_up_before_script() {

    # Disable errexit - bashunit enables it but sourced files may return non-zero
    set +eE

    # Skip if already loaded (bashunit runs all tests in same session)
    [[ -n "${_3309_test_loaded:-}" ]] && return 0
    _3309_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/3309_vmxnet3_interfaces_vmware.check
    source "${PROGRAM_DIR}/../../lib/check/3309_vmxnet3_interfaces_vmware.check"

}

function set_up() {

    # Reset mock variables
    if_vmxnet3=()

}

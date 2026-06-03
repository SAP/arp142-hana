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
if_gvnic=()

# Mock functions
LIB_FUNC_IS_CLOUD_GOOGLE() { return 0 ; }
LIB_FUNC_IS_VIRT_KVM() { return 0 ; }

grep() {

    #we fake (grep DRIVER=gve -rsH /sys/class/net/**/device/uevent)
    case "$*" in
        *'DRIVER=gve'*'uevent')  [[ ${#if_gvnic[@]} -eq 0 ]] && : || printf "%s\n" "${if_gvnic[@]}" ;;

        *)          command grep "$@" ;; # bashunit requires grep
    esac
}


function test_0interface_error() {

    #arrange
    if_gvnic=()

    #act
    check_3304_gvnic_interfaces_gcp

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for 0 gvnic interfaces"
    fi
    assert_true true
}

function test_1interface_warning() {

    #arrange
    if_gvnic=()
    if_gvnic+=('/sys/class/net/eth0/device/uevent:DRIVER=gve')

    #act
    check_3304_gvnic_interfaces_gcp

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for 1 gvnic interface"
    fi
    assert_true true
}

function test_2interfaces_ok() {

    #arrange
    if_gvnic=()
    if_gvnic+=('/sys/class/net/eth0/device/uevent:DRIVER=gve')
    if_gvnic+=('/sys/class/net/eth1/device/uevent:DRIVER=gve')

    #act
    check_3304_gvnic_interfaces_gcp

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for 2 gvnic interfaces"
    fi
    assert_true true
}

function test_4interfaces_ok() {

    #arrange
    if_gvnic=()
    if_gvnic+=('/sys/class/net/eth0/device/uevent:DRIVER=gve')
    if_gvnic+=('/sys/class/net/eth1/device/uevent:DRIVER=gve')
    if_gvnic+=('/sys/class/net/eth2/device/uevent:DRIVER=gve')
    if_gvnic+=('/sys/class/net/eth3/device/uevent:DRIVER=gve')

    #act
    check_3304_gvnic_interfaces_gcp

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for 4 gvnic interfaces"
    fi
    assert_true true
}

function test_not_gcp_skip() {

    #arrange
    LIB_FUNC_IS_CLOUD_GOOGLE() { return 1 ; }

    #act
    check_3304_gvnic_interfaces_gcp

    #assert
    if [[ $? -ne 3 ]]; then
        bashunit::fail "Expected RC=3 (skip) for non-GCP"
    fi
    assert_true true
}

function test_not_kvm_skip() {

    #arrange
    LIB_FUNC_IS_CLOUD_GOOGLE() { return 0 ; }
    LIB_FUNC_IS_VIRT_KVM() { return 1 ; }

    #act
    check_3304_gvnic_interfaces_gcp

    #assert
    if [[ $? -ne 3 ]]; then
        bashunit::fail "Expected RC=3 (skip) for non-KVM"
    fi
    assert_true true
}


function set_up_before_script() {

    # Disable errexit - bashunit enables it but sourced files may return non-zero
    set +eE

    # Skip if already loaded (bashunit runs all tests in same session)
    [[ -n "${_3304_test_loaded:-}" ]] && return 0
    _3304_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/3304_gvnic_interfaces_gcp.check
    source "${PROGRAM_DIR}/../../lib/check/3304_gvnic_interfaces_gcp.check"

}

function set_up() {

    # Reset mock variables
    if_gvnic=()
    LIB_FUNC_IS_CLOUD_GOOGLE() { return 0 ; }
    LIB_FUNC_IS_VIRT_KVM() { return 0 ; }

}

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
if_mtu=()

# Mock functions
LIB_FUNC_IS_CLOUD_AMAZON() { return 0 ; }

grep() {

    #we fake (grep . -rsH /sys/class/net/*/mtu)
    case "$*" in
        *'mtu')     printf "%s\n" "${if_mtu[@]}" ;;

        *)          command grep "$@" ;; # bashunit requires grep
    esac
}


function test_1if_with_mtu_ok() {

    #arrange
    if_mtu=()
    if_mtu+=('/sys/class/net/eth0/mtu:1500')

    #act
    check_3202_mtu_jumbo_amazon

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for 1 interface with correct MTU"
    fi
}

function test_2if_with_loopback_ignore() {

    #arrange
    if_mtu=()
    if_mtu+=('/sys/class/net/eth0/mtu:1500')
    if_mtu+=('/sys/class/net/lo/mtu:65536')

    #act
    check_3202_mtu_jumbo_amazon

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for loopback ignored"
    fi
}

function test_4if_with_eth1_mtu_toolow() {

    #arrange
    if_mtu=()
    if_mtu+=('/sys/class/net/eth0/mtu:1500')
    if_mtu+=('/sys/class/net/eth1/mtu:8999')
    if_mtu+=('/sys/class/net/eth1/mtu:9000')
    if_mtu+=('/sys/class/net/lo/mtu:65536')

    #act
    check_3202_mtu_jumbo_amazon

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for MTU too low"
    fi
}

function test_3if_with_eth1_mtu_tohigh() {

    #arrange
    if_mtu=()
    if_mtu+=('/sys/class/net/eth0/mtu:1500')
    if_mtu+=('/sys/class/net/eth1/mtu:9002')
    if_mtu+=('/sys/class/net/lo/mtu:65536')

    #act
    check_3202_mtu_jumbo_amazon

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for MTU too high"
    fi
}

function test_4if_with_mtu_ok() {

    #arrange
    if_mtu=()
    if_mtu+=('/sys/class/net/eth0/mtu:1500')
    if_mtu+=('/sys/class/net/eth1/mtu:9001')
    if_mtu+=('/sys/class/net/eth2/mtu:9001')
    if_mtu+=('/sys/class/net/lo/mtu:65536')

    #act
    check_3202_mtu_jumbo_amazon

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for 4 interfaces with correct MTU"
    fi
}

function test_2if_with_wrong_output_not_processed() {

    #arrange
    if_mtu=()
    if_mtu+=('/sys/class/net//mtu:9000')
    if_mtu+=('/sys/class/net/eth1/mtu:')

    #act
    check_3202_mtu_jumbo_amazon

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for wrong output not processed"
    fi
}


function set_up_before_script() {

    # Disable errexit - bashunit enables it but sourced files may return non-zero
    set +eE

    # Skip if already loaded (bashunit runs all tests in same session)
    [[ -n "${_3202_test_loaded:-}" ]] && return 0
    _3202_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/3202_mtu_jumbo_amazon.check
    source "${PROGRAM_DIR}/../../lib/check/3202_mtu_jumbo_amazon.check"

}

function set_up() {

    # Reset mock variables
    if_mtu=()

}

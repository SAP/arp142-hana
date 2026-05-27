#!/usr/bin/env bash
#------------------------------------------------------------------
# bashunit test for check_3412_network_ringbuffer_azure
#------------------------------------------------------------------
set -u

if [[ -z "${PROGRAM_DIR:-}" ]]; then
    PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
    [[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
fi

# CRITICAL: Use a test-specific guard variable
[[ -n "${_3412_network_ringbuffer_azure_test_loaded:-}" ]] && return 0
_3412_network_ringbuffer_azure_test_loaded=true

# Mock variables
TEST_ETHTOOL_OUTPUT=''
TEST_INTERFACES=()

# Mock functions
LIB_FUNC_IS_CLOUD_MICROSOFT() { return 0 ; }

grep() {
    case "$*" in
        *'uevent')  [[ ${#TEST_INTERFACES[@]} -eq 0 ]] && : || printf "%s\n" "${TEST_INTERFACES[@]}" ;;
        *)          command grep "$@" ;;
    esac
}

ethtool() {
    echo "${TEST_ETHTOOL_OUTPUT}"
}


function set_up_before_script() {

    set +eE

    [[ -n "${_3412_test_sourced:-}" ]] && return 0
    _3412_test_sourced=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/3412_network_ringbuffer_azure.check
    source "${PROGRAM_DIR}/../../lib/check/3412_network_ringbuffer_azure.check"
}

function set_up() {
    TEST_ETHTOOL_OUTPUT='Ring parameters for eth0:
Pre-set maximums:
RX:		4096
TX:		4096
Current hardware settings:
RX:		1024
TX:		1024'
    TEST_INTERFACES=()
    TEST_INTERFACES+=('/sys/class/net/eth0/device/uevent:DRIVER=hv_netvsc')
    TEST_INTERFACES+=('/sys/class/net/eth1/device/uevent:DRIVER=mana')

    LIB_FUNC_IS_CLOUD_MICROSOFT() { return 0 ; }
}

function test_all_ok() {

    #act
    check_3412_network_ringbuffer_azure
    local rc=$?

    #assert
    if [[ ${rc} -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok), got RC=${rc}"
    fi
    assert_true true
}

function test_ring_buffer_too_small_warning() {

    #arrange
    TEST_ETHTOOL_OUTPUT='Ring parameters for eth0:
Pre-set maximums:
RX:		4096
TX:		4096
Current hardware settings:
RX:		256
TX:		256'

    #act
    check_3412_network_ringbuffer_azure
    local rc=$?

    #assert
    if [[ ${rc} -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for small ring buffers, got RC=${rc}"
    fi
    assert_true true
}

function test_ring_buffer_larger_ok() {

    #arrange
    TEST_ETHTOOL_OUTPUT='Ring parameters for eth0:
Pre-set maximums:
RX:		4096
TX:		4096
Current hardware settings:
RX:		4096
TX:		4096'

    #act
    check_3412_network_ringbuffer_azure
    local rc=$?

    #assert
    if [[ ${rc} -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for ring buffers >= recommended, got RC=${rc}"
    fi
    assert_true true
}

function test_not_azure_skip() {

    #arrange
    LIB_FUNC_IS_CLOUD_MICROSOFT() { return 1 ; }

    #act
    check_3412_network_ringbuffer_azure
    local rc=$?

    #assert
    if [[ ${rc} -ne 3 ]]; then
        bashunit::fail "Expected RC=3 (skip) for non-Azure, got RC=${rc}"
    fi
    assert_true true
}

function test_no_interfaces_warning() {

    #arrange
    TEST_INTERFACES=()

    #act
    check_3412_network_ringbuffer_azure
    local rc=$?

    #assert
    if [[ ${rc} -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) with no interfaces, got RC=${rc}"
    fi
    assert_true true
}

function test_partial_ring_buffer_warning() {

    #arrange
    TEST_INTERFACES=()
    TEST_INTERFACES+=('/sys/class/net/eth0/device/uevent:DRIVER=hv_netvsc')
    TEST_INTERFACES+=('/sys/class/net/eth1/device/uevent:DRIVER=mana')
    TEST_INTERFACES+=('/sys/class/net/eth2/device/uevent:DRIVER=hv_netvsc')

    # ethtool mock returns same for all - only RX 256 which is too small
    TEST_ETHTOOL_OUTPUT='Ring parameters for eth0:
Pre-set maximums:
RX:		4096
TX:		4096
Current hardware settings:
RX:		256
TX:		1024'

    #act
    check_3412_network_ringbuffer_azure
    local rc=$?

    #assert
    if [[ ${rc} -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for partial ring buffer issue, got RC=${rc}"
    fi
    assert_true true
}

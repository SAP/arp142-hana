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
is_sles=1
is_rhel=1
OS_VERSION="12.4"
mock_tcp_tw_reuse_value=0
mock_tcp_tw_recycle_value=0
mock_tcp_tw_recycle_exists=true

# Mock functions
LIB_FUNC_IS_SLES() { return ${is_sles} ; }
LIB_FUNC_IS_RHEL() { return ${is_rhel} ; }

# Create mock proc directory structure
create_mock_files() {
    mkdir -p "${PROGRAM_DIR}/mock_proc/sys/net/ipv4"
    echo "${mock_tcp_tw_reuse_value}" > "${PROGRAM_DIR}/mock_proc/sys/net/ipv4/tcp_tw_reuse"

    if ${mock_tcp_tw_recycle_exists}; then
        echo "${mock_tcp_tw_recycle_value}" > "${PROGRAM_DIR}/mock_proc/sys/net/ipv4/tcp_tw_recycle"
    else
        rm -f "${PROGRAM_DIR}/mock_proc/sys/net/ipv4/tcp_tw_recycle"
    fi
}

# Helper function to be called in each test after setting variables
setup_test() {
    create_mock_files
    export path_to_tcp_tw_reuse="${PROGRAM_DIR}/mock_proc/sys/net/ipv4/tcp_tw_reuse"
    export path_to_tcp_tw_recycle="${PROGRAM_DIR}/mock_proc/sys/net/ipv4/tcp_tw_recycle"
    export OS_VERSION
}


function test_sles_12_4_correct_values() {

    #arrange
    is_sles=0
    is_rhel=1
    OS_VERSION="12.4"
    mock_tcp_tw_reuse_value=0
    mock_tcp_tw_recycle_value=0
    mock_tcp_tw_recycle_exists=true
    setup_test

    #act
    check_3011_network_tcp_tw_parameter

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for SLES 12.4 correct values"
    fi
}

function test_sles_12_4_wrong_reuse_value() {

    #arrange
    is_sles=0
    is_rhel=1
    OS_VERSION="12.4"
    mock_tcp_tw_reuse_value=1
    mock_tcp_tw_recycle_value=0
    mock_tcp_tw_recycle_exists=true
    setup_test

    #act
    check_3011_network_tcp_tw_parameter

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for SLES 12.4 wrong reuse value"
    fi
}

function test_sles_12_4_wrong_recycle_value() {

    #arrange
    is_sles=0
    is_rhel=1
    OS_VERSION="12.4"
    mock_tcp_tw_reuse_value=0
    mock_tcp_tw_recycle_value=1
    mock_tcp_tw_recycle_exists=true
    setup_test

    #act
    check_3011_network_tcp_tw_parameter

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for SLES 12.4 wrong recycle value"
    fi
}

function test_sles_15_2_correct_values() {

    #arrange
    is_sles=0
    is_rhel=1
    OS_VERSION="15.2"
    mock_tcp_tw_reuse_value=2
    mock_tcp_tw_recycle_value=0
    mock_tcp_tw_recycle_exists=true
    setup_test

    #act
    check_3011_network_tcp_tw_parameter

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for SLES 15.2 correct values"
    fi
}

function test_sles_15_2_wrong_reuse_value() {

    #arrange
    is_sles=0
    is_rhel=1
    OS_VERSION="15.2"
    mock_tcp_tw_reuse_value=0
    mock_tcp_tw_recycle_value=0
    mock_tcp_tw_recycle_exists=true
    setup_test

    #act
    check_3011_network_tcp_tw_parameter

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for SLES 15.2 wrong reuse value"
    fi
}

function test_sles_15_2_reuse_value_1() {

    #arrange
    is_sles=0
    is_rhel=1
    OS_VERSION="15.2"
    mock_tcp_tw_reuse_value=1
    mock_tcp_tw_recycle_value=0
    mock_tcp_tw_recycle_exists=true
    setup_test

    #act
    check_3011_network_tcp_tw_parameter

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for SLES 15.2 reuse value 1"
    fi
}

function test_rhel_7_9_correct_values() {

    #arrange
    is_sles=1
    is_rhel=0
    OS_VERSION="7.9"
    mock_tcp_tw_reuse_value=0
    mock_tcp_tw_recycle_value=0
    mock_tcp_tw_recycle_exists=true
    setup_test

    #act
    check_3011_network_tcp_tw_parameter

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for RHEL 7.9 correct values"
    fi
}

function test_rhel_8_0_correct_values() {

    #arrange
    is_sles=1
    is_rhel=0
    OS_VERSION="8.0"
    mock_tcp_tw_reuse_value=0
    mock_tcp_tw_recycle_value=0
    mock_tcp_tw_recycle_exists=true
    setup_test

    #act
    check_3011_network_tcp_tw_parameter

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for RHEL 8.0 correct values"
    fi
}

function test_rhel_8_1_correct_values() {

    #arrange
    is_sles=1
    is_rhel=0
    OS_VERSION="8.1"
    mock_tcp_tw_reuse_value=2
    mock_tcp_tw_recycle_value=0
    mock_tcp_tw_recycle_exists=true
    setup_test

    #act
    check_3011_network_tcp_tw_parameter

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for RHEL 8.1 correct values"
    fi
}

function test_rhel_8_1_wrong_reuse_value() {

    #arrange
    is_sles=1
    is_rhel=0
    OS_VERSION="8.1"
    mock_tcp_tw_reuse_value=0
    mock_tcp_tw_recycle_value=0
    mock_tcp_tw_recycle_exists=true
    setup_test

    #act
    check_3011_network_tcp_tw_parameter

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for RHEL 8.1 wrong reuse value"
    fi
}

function test_tcp_tw_recycle_not_available() {

    #arrange
    is_sles=0
    is_rhel=1
    OS_VERSION="15.2"
    mock_tcp_tw_reuse_value=2
    mock_tcp_tw_recycle_exists=false
    setup_test

    #act
    check_3011_network_tcp_tw_parameter

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for tcp_tw_recycle not available"
    fi
}

function test_both_parameters_wrong() {

    #arrange
    is_sles=0
    is_rhel=1
    OS_VERSION="12.4"
    mock_tcp_tw_reuse_value=1
    mock_tcp_tw_recycle_value=1
    mock_tcp_tw_recycle_exists=true
    setup_test

    #act
    check_3011_network_tcp_tw_parameter

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for both parameters wrong"
    fi
}

function test_sles_15_1_boundary() {

    #arrange
    is_sles=0
    is_rhel=1
    OS_VERSION="15.1"
    mock_tcp_tw_reuse_value=0
    mock_tcp_tw_recycle_value=0
    mock_tcp_tw_recycle_exists=true
    setup_test

    #act
    check_3011_network_tcp_tw_parameter

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for SLES 15.1 boundary"
    fi
}

function test_rhel_9_0_correct_values() {

    #arrange
    is_sles=1
    is_rhel=0
    OS_VERSION="9.0"
    mock_tcp_tw_reuse_value=2
    mock_tcp_tw_recycle_value=0
    mock_tcp_tw_recycle_exists=true
    setup_test

    #act
    check_3011_network_tcp_tw_parameter

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for RHEL 9.0 correct values"
    fi
}


function set_up_before_script() {

    # Disable errexit - bashunit enables it but sourced files may return non-zero
    set +eE

    # Skip if already loaded (bashunit runs all tests in same session)
    [[ -n "${_3011_test_loaded:-}" ]] && return 0
    _3011_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/3011_network_tcp_tw_parameter.check
    source "${PROGRAM_DIR}/../../lib/check/3011_network_tcp_tw_parameter.check"

}

function set_up() {

    # Default settings - can be overridden by individual tests
    is_sles=1
    is_rhel=1
    OS_VERSION="12.4"
    mock_tcp_tw_reuse_value=0
    mock_tcp_tw_recycle_value=0
    mock_tcp_tw_recycle_exists=true

}

function tear_down() {
    # Clean up mock files
    rm -rf "${PROGRAM_DIR}/mock_proc"
}

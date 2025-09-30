#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
readonly PROGRAM_DIR

# Mock OS functions
LIB_FUNC_IS_SLES() { return ${is_sles} ; }
LIB_FUNC_IS_RHEL() { return ${is_rhel} ; }

# Variables to control environment simulation
is_sles=1
is_rhel=1
OS_VERSION="12.4"

# Mock file system by creating actual mock files
mock_tcp_tw_reuse_value=0
mock_tcp_tw_recycle_value=0
mock_tcp_tw_recycle_exists=true

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



test_sles_12_4_correct_values() {

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
    assertEquals "CheckOk? RC" '0' "$?"
}

test_sles_12_4_wrong_reuse_value() {

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
    assertEquals "CheckWarning? RC" '1' "$?"
}

test_sles_12_4_wrong_recycle_value() {

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
    assertEquals "CheckWarning? RC" '1' "$?"
}

test_sles_15_2_correct_values() {

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
    assertEquals "CheckOk? RC" '0' "$?"
}

test_sles_15_2_wrong_reuse_value() {

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
    assertEquals "CheckWarning? RC" '1' "$?"
}

test_sles_15_2_reuse_value_1() {

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
    assertEquals "CheckWarning? RC" '1' "$?"
}

test_rhel_7_9_correct_values() {

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
    assertEquals "CheckOk? RC" '0' "$?"
}

test_rhel_8_0_correct_values() {

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
    assertEquals "CheckOk? RC" '0' "$?"
}

test_rhel_8_1_correct_values() {

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
    assertEquals "CheckOk? RC" '0' "$?"
}

test_rhel_8_1_wrong_reuse_value() {

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
    assertEquals "CheckWarning? RC" '1' "$?"
}

test_tcp_tw_recycle_not_available() {

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
    assertEquals "CheckOk? RC" '0' "$?"
}

test_both_parameters_wrong() {

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
    assertEquals "CheckWarning? RC" '1' "$?"
}

test_sles_15_1_boundary() {

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
    assertEquals "CheckOk? RC" '0' "$?"
}

test_rhel_9_0_correct_values() {

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
    assertEquals "CheckOk? RC" '0' "$?"
}

oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/3011_network_tcp_tw_parameter.check
    source "${PROGRAM_DIR}/../../lib/check/3011_network_tcp_tw_parameter.check"

    export avoidDoubleTearDownExecution=true

}

oneTimeTearDown() {

    if ${avoidDoubleTearDownExecution:-false}; then
        unset -v avoidDoubleTearDownExecution
    fi
}

setUp() {

    # Default settings - can be overridden by individual tests
    is_sles=1
    is_rhel=1
    OS_VERSION="12.4"
    mock_tcp_tw_reuse_value=0
    mock_tcp_tw_recycle_value=0
    mock_tcp_tw_recycle_exists=true

}

# Helper function to be called in each test after setting variables
setup_test() {
    create_mock_files
    export path_to_tcp_tw_reuse="${PROGRAM_DIR}/mock_proc/sys/net/ipv4/tcp_tw_reuse"
    export path_to_tcp_tw_recycle="${PROGRAM_DIR}/mock_proc/sys/net/ipv4/tcp_tw_recycle"
    export OS_VERSION
}

tearDown() {
    # Clean up mock files
    rm -rf "${PROGRAM_DIR}/mock_proc"
}

#Import Libraries
# - order is important - sourcing shunit triggers testing
# - that's also the reason, why it could not be done during oneTimeSetup

#Load and run shUnit2
#shellcheck source=../shunit2
source "${PROGRAM_DIR}/../shunit2"
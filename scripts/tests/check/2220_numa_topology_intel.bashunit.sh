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
is_intel=1
LIB_PLATF_CPU_SOCKETS=8
path_to_numa_distance=''

# Mock functions
LIB_FUNC_IS_INTEL() { return ${is_intel} ; }


function test_not_intel_cpu() {

    #arrange
    is_intel=1
    LIB_PLATF_CPU_SOCKETS=8

    #act
    check_2220_numa_topology_intel

    #assert
    if [[ $? -ne 3 ]]; then
        bashunit::fail "Expected RC=3 (skipped) for not Intel CPU"
    fi
}

function test_sockets_unknown() {

    #arrange
    is_intel=0
    unset LIB_PLATF_CPU_SOCKETS

    #act
    check_2220_numa_topology_intel

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for sockets unknown"
    fi
}

function test_less_than_8_sockets() {

    #arrange
    is_intel=0
    LIB_PLATF_CPU_SOCKETS=4

    #act
    check_2220_numa_topology_intel

    #assert
    if [[ $? -ne 3 ]]; then
        bashunit::fail "Expected RC=3 (skipped) for less than 8 sockets"
    fi
}

function test_exactly_8_sockets() {

    #arrange
    is_intel=0
    LIB_PLATF_CPU_SOCKETS=8
    echo "10 20 30 40 50 60 70 80" > "${PROGRAM_DIR}/mock_numa_distance"
    path_to_numa_distance="${PROGRAM_DIR}/mock_numa_distance"

    #act
    check_2220_numa_topology_intel

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for exactly 8 sockets"
    fi
}

function test_more_than_8_sockets() {

    #arrange
    is_intel=0
    LIB_PLATF_CPU_SOCKETS=12
    echo "10 20 30 40 50 60 70 80 90 10 20 30" > "${PROGRAM_DIR}/mock_numa_distance"
    path_to_numa_distance="${PROGRAM_DIR}/mock_numa_distance"

    #act
    check_2220_numa_topology_intel

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for more than 8 sockets"
    fi
}

function test_numa_distance_file_not_found() {

    #arrange
    is_intel=0
    LIB_PLATF_CPU_SOCKETS=8
    path_to_numa_distance="${PROGRAM_DIR}/nonexistent_numa_distance"

    #act
    check_2220_numa_topology_intel

    #assert
    if [[ $? -ne 3 ]]; then
        bashunit::fail "Expected RC=3 (skipped) for NUMA distance file not found"
    fi
}

function test_incorrect_numa_pattern_exact_match() {

    #arrange
    is_intel=0
    LIB_PLATF_CPU_SOCKETS=8
    echo "10 20 20 20 20 20 20 20" > "${PROGRAM_DIR}/mock_numa_distance"
    path_to_numa_distance="${PROGRAM_DIR}/mock_numa_distance"

    #act
    check_2220_numa_topology_intel

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for incorrect NUMA pattern"
    fi
}

function test_incorrect_numa_pattern_12sockets() {

    #arrange
    is_intel=0
    LIB_PLATF_CPU_SOCKETS=12
    echo "10 20 20 20 20 20 20 20 20 20 20 20" > "${PROGRAM_DIR}/mock_numa_distance"
    path_to_numa_distance="${PROGRAM_DIR}/mock_numa_distance"

    #act
    check_2220_numa_topology_intel

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for incorrect NUMA pattern 12 sockets"
    fi
}

function test_correct_numa_topology_different_pattern() {

    #arrange
    is_intel=0
    LIB_PLATF_CPU_SOCKETS=8
    echo "10 20 30 20 30 20 30 20" > "${PROGRAM_DIR}/mock_numa_distance"
    path_to_numa_distance="${PROGRAM_DIR}/mock_numa_distance"

    #act
    check_2220_numa_topology_intel

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for correct NUMA topology different pattern"
    fi
}

function test_correct_numa_topology_different_values() {

    #arrange
    is_intel=0
    LIB_PLATF_CPU_SOCKETS=8
    echo "10 21 22 23 24 25 26 27" > "${PROGRAM_DIR}/mock_numa_distance"
    path_to_numa_distance="${PROGRAM_DIR}/mock_numa_distance"

    #act
    check_2220_numa_topology_intel

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for correct NUMA topology different values"
    fi
}

function test_numa_file_read_error() {

    #arrange
    is_intel=0
    LIB_PLATF_CPU_SOCKETS=8
    # Create a directory instead of a file to simulate read error
    mkdir -p "${PROGRAM_DIR}/mock_numa_distance_dir"
    path_to_numa_distance="${PROGRAM_DIR}/mock_numa_distance_dir"

    #act
    check_2220_numa_topology_intel

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for NUMA file read error"
    fi
}

function test_numa_pattern_single_digit_differences() {

    #arrange
    is_intel=0
    LIB_PLATF_CPU_SOCKETS=8
    echo "10 20 20 20 20 20 20 21" > "${PROGRAM_DIR}/mock_numa_distance"
    path_to_numa_distance="${PROGRAM_DIR}/mock_numa_distance"

    #act
    check_2220_numa_topology_intel

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for NUMA pattern single digit differences"
    fi
}


function set_up_before_script() {

    # Disable errexit - bashunit enables it but sourced files may return non-zero
    set +eE

    # Skip if already loaded (bashunit runs all tests in same session)
    [[ -n "${_2220_test_loaded:-}" ]] && return 0
    _2220_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/2220_numa_topology_intel.check
    source "${PROGRAM_DIR}/../../lib/check/2220_numa_topology_intel.check"

}

function set_up() {

    # Default settings - can be overridden by individual tests
    is_intel=1
    LIB_PLATF_CPU_SOCKETS=8
    path_to_numa_distance="/sys/devices/system/node/node0/distance"

    # Clean up any existing mock files
    rm -f "${PROGRAM_DIR}/mock_numa_distance"
    rm -rf "${PROGRAM_DIR}/mock_numa_distance_dir"

}

function tear_down() {

    rm -f "${PROGRAM_DIR}/mock_numa_distance"
    rm -rf "${PROGRAM_DIR}/mock_numa_distance_dir"

}

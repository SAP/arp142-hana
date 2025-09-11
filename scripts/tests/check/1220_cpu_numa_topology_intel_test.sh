#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
readonly PROGRAM_DIR

#fake PREREQUISITE functions
LIB_FUNC_IS_INTEL() { return ${is_intel} ; }

# Variables to control environment simulation
is_intel=1
LIB_PLATF_CPU_SOCKETS=8

test_not_intel_cpu() {

    #arrange
    is_intel=1
    LIB_PLATF_CPU_SOCKETS=8

    #act
    check_1220_cpu_numa_topology_intel

    #assert
    assertEquals "CheckSkip? RC" '3' "$?"
}

test_sockets_unknown() {

    #arrange
    is_intel=0
    unset LIB_PLATF_CPU_SOCKETS

    #act
    check_1220_cpu_numa_topology_intel

    #assert
    assertEquals "CheckWarning? RC" '1' "$?"
}

test_less_than_8_sockets() {

    #arrange
    is_intel=0
    LIB_PLATF_CPU_SOCKETS=4

    #act
    check_1220_cpu_numa_topology_intel

    #assert
    assertEquals "CheckSkip? RC" '3' "$?"
}

test_exactly_8_sockets() {

    #arrange
    is_intel=0
    LIB_PLATF_CPU_SOCKETS=8
    echo "10 20 30 40 50 60 70 80" > "${PROGRAM_DIR}/mock_numa_distance"
    path_to_numa_distance="${PROGRAM_DIR}/mock_numa_distance"

    #act
    check_1220_cpu_numa_topology_intel

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_more_than_8_sockets() {

    #arrange
    is_intel=0
    LIB_PLATF_CPU_SOCKETS=12
    echo "10 20 30 40 50 60 70 80 90 10 20 30" > "${PROGRAM_DIR}/mock_numa_distance"
    path_to_numa_distance="${PROGRAM_DIR}/mock_numa_distance"

    #act
    check_1220_cpu_numa_topology_intel

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_numa_distance_file_not_found() {

    #arrange
    is_intel=0
    LIB_PLATF_CPU_SOCKETS=8
    path_to_numa_distance="${PROGRAM_DIR}/nonexistent_numa_distance"

    #act
    check_1220_cpu_numa_topology_intel

    #assert
    assertEquals "CheckSkip? RC" '3' "$?"
}

test_incorrect_numa_pattern_exact_match() {

    #arrange
    is_intel=0
    LIB_PLATF_CPU_SOCKETS=8
    echo "10 20 20 20 20 20 20 20" > "${PROGRAM_DIR}/mock_numa_distance"
    path_to_numa_distance="${PROGRAM_DIR}/mock_numa_distance"

    #act
    check_1220_cpu_numa_topology_intel

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_incorrect_numa_pattern_12sockets() {

    #arrange
    is_intel=0
    LIB_PLATF_CPU_SOCKETS=12
    echo "10 20 20 20 20 20 20 20 20 20 20 20" > "${PROGRAM_DIR}/mock_numa_distance"
    path_to_numa_distance="${PROGRAM_DIR}/mock_numa_distance"

    #act
    check_1220_cpu_numa_topology_intel

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_correct_numa_topology_different_pattern() {

    #arrange
    is_intel=0
    LIB_PLATF_CPU_SOCKETS=8
    echo "10 20 30 20 30 20 30 20" > "${PROGRAM_DIR}/mock_numa_distance"
    path_to_numa_distance="${PROGRAM_DIR}/mock_numa_distance"

    #act
    check_1220_cpu_numa_topology_intel

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_correct_numa_topology_different_values() {

    #arrange
    is_intel=0
    LIB_PLATF_CPU_SOCKETS=8
    echo "10 21 22 23 24 25 26 27" > "${PROGRAM_DIR}/mock_numa_distance"
    path_to_numa_distance="${PROGRAM_DIR}/mock_numa_distance"

    #act
    check_1220_cpu_numa_topology_intel

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_numa_file_read_error() {

    #arrange
    is_intel=0
    LIB_PLATF_CPU_SOCKETS=8
    # Create a directory instead of a file to simulate read error
    mkdir -p "${PROGRAM_DIR}/mock_numa_distance_dir"
    path_to_numa_distance="${PROGRAM_DIR}/mock_numa_distance_dir"

    #act
    check_1220_cpu_numa_topology_intel

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_numa_pattern_single_digit_differences() {

    #arrange
    is_intel=0
    LIB_PLATF_CPU_SOCKETS=8
    echo "10 20 20 20 20 20 20 21" > "${PROGRAM_DIR}/mock_numa_distance"
    path_to_numa_distance="${PROGRAM_DIR}/mock_numa_distance"

    #act
    check_1220_cpu_numa_topology_intel

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/1220_cpu_numa_topology_intel.check
    source "${PROGRAM_DIR}/../../lib/check/1220_cpu_numa_topology_intel.check"

    export avoidDoubleTearDownExecution=true

}

oneTimeTearDown() {

    if ${avoidDoubleTearDownExecution:-false}; then

        rm -f "${PROGRAM_DIR}/mock_numa_distance"
        rm -rf "${PROGRAM_DIR}/mock_numa_distance_dir"

        unset -v avoidDoubleTearDownExecution
    fi
}

setUp() {

    # Default settings - can be overridden by individual tests
    is_intel=1
    LIB_PLATF_CPU_SOCKETS=8
    path_to_numa_distance="/sys/devices/system/node/node0/distance"

    # Clean up any existing mock files
    rm -f "${PROGRAM_DIR}/mock_numa_distance"
    rm -rf "${PROGRAM_DIR}/mock_numa_distance_dir"

}

#tearDown

#Import Libraries
# - order is important - sourcing shunit triggers testing
# - that's also the reason, why it could not be done during oneTimeSetup

#Load and run shUnit2
#shellcheck source=../shunit2
source "${PROGRAM_DIR}/../shunit2"
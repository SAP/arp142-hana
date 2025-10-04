#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
[[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
readonly PROGRAM_DIR

LIB_FUNC_IS_RHEL() { return 1 ; }

# Override the file read operation by creating a function that the original check will use
# We'll modify the original function to use this variable instead of reading the file directly

test_recommended_values() {

    #arrange
    echo "32000 1024000000 500 32000" > "${PROGRAM_DIR}/mock_kernel_sem"
    path_to_kernel_sem="${PROGRAM_DIR}/mock_kernel_sem"

    #act
    check_2510_kernel_semaphores

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_semmsl_too_low() {

    #arrange
    echo "16000 1024000000 500 32000" > "${PROGRAM_DIR}/mock_kernel_sem"
    path_to_kernel_sem="${PROGRAM_DIR}/mock_kernel_sem"

    #act
    check_2510_kernel_semaphores

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_semmns_too_low() {

    #arrange
    echo "32000 512000000 500 32000" > "${PROGRAM_DIR}/mock_kernel_sem"
    path_to_kernel_sem="${PROGRAM_DIR}/mock_kernel_sem"

    #act
    check_2510_kernel_semaphores

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_semopm_too_low() {

    #arrange
    echo "32000 1024000000 250 32000" > "${PROGRAM_DIR}/mock_kernel_sem"
    path_to_kernel_sem="${PROGRAM_DIR}/mock_kernel_sem"

    #act
    check_2510_kernel_semaphores

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_semmni_too_low() {

    #arrange
    echo "32000 1024000000 500 16000" > "${PROGRAM_DIR}/mock_kernel_sem"
    path_to_kernel_sem="${PROGRAM_DIR}/mock_kernel_sem"

    #act
    check_2510_kernel_semaphores

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_multiple_values_too_low() {

    #arrange
    echo "16000 512000000 250 16000" > "${PROGRAM_DIR}/mock_kernel_sem"
    path_to_kernel_sem="${PROGRAM_DIR}/mock_kernel_sem"

    #act
    check_2510_kernel_semaphores

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_all_values_higher_than_recommended() {

    #arrange
    echo "64000 2048000000 1000 64000" > "${PROGRAM_DIR}/mock_kernel_sem"
    path_to_kernel_sem="${PROGRAM_DIR}/mock_kernel_sem"

    #act
    check_2510_kernel_semaphores

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_semmsl_higher() {

    #arrange
    echo "64000 1024000000 500 32000" > "${PROGRAM_DIR}/mock_kernel_sem"
    path_to_kernel_sem="${PROGRAM_DIR}/mock_kernel_sem"

    #act
    check_2510_kernel_semaphores

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_semmns_higher() {

    #arrange
    echo "32000 2048000000 500 32000" > "${PROGRAM_DIR}/mock_kernel_sem"
    path_to_kernel_sem="${PROGRAM_DIR}/mock_kernel_sem"

    #act
    check_2510_kernel_semaphores

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_mixed_some_low_some_ok() {

    #arrange
    echo "32000 512000000 500 16000" > "${PROGRAM_DIR}/mock_kernel_sem"
    path_to_kernel_sem="${PROGRAM_DIR}/mock_kernel_sem"

    #act
    check_2510_kernel_semaphores

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_insufficient_parameters() {

    #arrange
    echo "32000 1024000000 500" > "${PROGRAM_DIR}/mock_kernel_sem"
    path_to_kernel_sem="${PROGRAM_DIR}/mock_kernel_sem"

    #act
    check_2510_kernel_semaphores

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_boundary_values_exact_match() {

    #arrange
    echo "32000 1024000000 500 32000" > "${PROGRAM_DIR}/mock_kernel_sem"
    path_to_kernel_sem="${PROGRAM_DIR}/mock_kernel_sem"

    #act
    check_2510_kernel_semaphores

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_boundary_values_one_above() {

    #arrange
    echo "32001 1024000001 501 32001" > "${PROGRAM_DIR}/mock_kernel_sem"
    path_to_kernel_sem="${PROGRAM_DIR}/mock_kernel_sem"

    #act
    check_2510_kernel_semaphores

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_boundary_values_one_below() {

    #arrange
    echo "31999 1023999999 499 31999" > "${PROGRAM_DIR}/mock_kernel_sem"
    path_to_kernel_sem="${PROGRAM_DIR}/mock_kernel_sem"

    #act
    check_2510_kernel_semaphores

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/2510_kernel_semaphores.check
    source "${PROGRAM_DIR}/../../lib/check/2510_kernel_semaphores.check"

    export avoidDoubleTearDownExecution=true

}

oneTimeTearDown() {

    if ${avoidDoubleTearDownExecution:-false}; then

        rm -f "${PROGRAM_DIR}/mock_kernel_sem"

        unset -v avoidDoubleTearDownExecution
    fi
}

setUp() {

    # Default path - can be overridden by individual tests
    path_to_kernel_sem="/proc/sys/kernel/sem"
    echo "32000 1024000000 500 32000" > "${PROGRAM_DIR}/mock_kernel_sem"

}

#tearDown

#Import Libraries
# - order is important - sourcing shunit triggers testing
# - that's also the reason, why it could not be done during oneTimeSetup

#Load and run shUnit2
#shellcheck source=../shunit2
source "${PROGRAM_DIR}/../shunit2"

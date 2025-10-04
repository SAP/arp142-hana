#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
[[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
readonly PROGRAM_DIR

#fake PREREQUISITE functions

test_kernel-tainted_set0-untainted_ok() {

    #arrange
    path_to_kernel_tainted="${PROGRAM_DIR}/mock_kernel_tainted"
    echo 0 > "${path_to_kernel_tainted}"

    #act
    check_0090_os_kernel_tainted

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_kernel-tainted_set1-tainted_error() {

    #arrange
    path_to_kernel_tainted="${PROGRAM_DIR}/mock_kernel_tainted"
    echo 1 > "${path_to_kernel_tainted}"

    #act
    check_0090_os_kernel_tainted

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_kernel-tainted_set8-tainted_warning() {

    #arrange
    path_to_kernel_tainted="${PROGRAM_DIR}/mock_kernel_tainted"
    echo 8 > "${path_to_kernel_tainted}"

    #act
    check_0090_os_kernel_tainted

    #assert
    assertEquals "CheckWarning? RC" '1' "$?"
}

test_kernel-tainted_set_non_listed-tainted_warning() {

    #arrange
    path_to_kernel_tainted="${PROGRAM_DIR}/mock_kernel_tainted"
    echo 1048576 > "${path_to_kernel_tainted}"

    #act
    check_0090_os_kernel_tainted

    #assert
    assertEquals "CheckWarning? RC" '1' "$?"
}

test_kernel-tainted_set15-tainted_error() {

    #arrange
    path_to_kernel_tainted="${PROGRAM_DIR}/mock_kernel_tainted"
    echo 15 > "${path_to_kernel_tainted}"

    #act
    check_0090_os_kernel_tainted

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/0090_os_kernel_tainted.check
    source "${PROGRAM_DIR}/../../lib/check/0090_os_kernel_tainted.check"

    export avoidDoubleTearDownExecution=true

}

oneTimeTearDown() {

    if ${avoidDoubleTearDownExecution:-false}; then

        rm -f "${PROGRAM_DIR}/mock_kernel_tainted"

        unset -v avoidDoubleTearDownExecution
    fi

}

setUp() {

    echo 0 > "${PROGRAM_DIR}/mock_kernel_tainted"

}

#tearDown

#Import Libraries
# - order is important - sourcing shunit triggers testing
# - that's also the reason, why it could not be done during oneTimeSetup

#Load and run shUnit2
#shellcheck source=../shunit2
source "${PROGRAM_DIR}/../shunit2"

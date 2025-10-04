#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
[[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
readonly PROGRAM_DIR

#mock PREREQUISITE functions
LIB_FUNC_IS_RHEL() { return 0 ; }
LIB_FUNC_IS_RHEL4SAP() { return 0 ; }

OS_VERSION=''

test_rhel_out_of_lifetime() {

    #arrange
    OS_VERSION='6.9'

    #act
    check_0001_os_support_rhel

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_rhel_not_supported() {

    #arrange
    OS_VERSION='7.8'

    #act
    check_0001_os_support_rhel

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_rhel_supported() {

    #arrange
    OS_VERSION='9.2'

    #act
    check_0001_os_support_rhel

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_rhel_not_handled() {

    #arrange
    OS_VERSION='9.9'

    #act
    check_0001_os_support_rhel

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/0001_os_support_rhel.check
    source "${PROGRAM_DIR}/../../lib/check/0001_os_support_rhel.check"

}

# oneTimeTearDown

setUp() {

    # shellcheck disable=SC2034
    OS_VERSION=

}

# tearDown

#Import Libraries
# - order is important - sourcing shunit triggers testing
# - that's also the reason, why it could not be done during oneTimeSetup

#Load and run shUnit2
#shellcheck source=../shunit2
source "${PROGRAM_DIR}/../shunit2"

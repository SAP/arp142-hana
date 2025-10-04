#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
[[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
readonly PROGRAM_DIR

#mock PREREQUISITE functions
LIB_FUNC_IS_SLES() { return 0 ; }
LIB_FUNC_IS_SLES4SAP() { return 0 ; }

OS_VERSION=''

test_sles_out_of_lifetime() {

    #arrange
    OS_VERSION='11.4'

    #act
    check_0000_os_support_sles

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_sles_not_supported() {

    #arrange
    OS_VERSION='14.0'

    #act
    check_0000_os_support_sles

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_sles_supported() {

    #arrange
    OS_VERSION='15.5'

    #act
    check_0000_os_support_sles

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_sles_not_handled() {

    #arrange
    OS_VERSION='15.9'

    #act
    check_0000_os_support_sles

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/0000_os_support_sles.check
    source "${PROGRAM_DIR}/../../lib/check/0000_os_support_sles.check"

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

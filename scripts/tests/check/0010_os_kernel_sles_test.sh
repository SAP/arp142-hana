#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
readonly PROGRAM_DIR

#mock PREREQUISITE functions
LIB_FUNC_IS_INTEL() { return 0 ; }
LIB_FUNC_IS_SLES() { return 0 ; }
LIB_FUNC_NORMALIZE_KERNEL() { : ; }

LIB_FUNC_COMPARE_VERSIONS() {
    # shellcheck disable=SC2086
    return $COMPARE_VERSIONS_RC ;
}

OS_VERSION=''
OS_LEVEL=''
LIB_FUNC_NORMALIZE_KERNEL_RETURN=''
COMPARE_VERSIONS_RC=


test_sles_not_supported() {

    #arrange
    OS_VERSION='11.3'

    #act
    check_0010_os_kernel_sles

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_sles_supported_kernel_tolow() {

    #arrange
    OS_VERSION='15.3'
    COMPARE_VERSIONS_RC=2

    #act
    check_0010_os_kernel_sles

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_sles_supported_kernel_ok() {

    #arrange
    OS_VERSION='15.3'
    COMPARE_VERSIONS_RC=1

    #act
    check_0010_os_kernel_sles

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}


oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/0010_os_kernel_sles.check
    source "${PROGRAM_DIR}/../../lib/check/0010_os_kernel_sles.check"

}

# oneTimeTearDown

setUp() {

    OS_VERSION=
    OS_LEVEL=
    LIB_FUNC_NORMALIZE_KERNEL_RETURN=
    declare -i COMPARE_VERSIONS_RC=

}

# tearDown

#Import Libraries
# - order is important - sourcing shunit triggers testing
# - that's also the reason, why it could not be done during oneTimeSetup

#Load and run shUnit2
#shellcheck source=../shunit2
source "${PROGRAM_DIR}/../shunit2"

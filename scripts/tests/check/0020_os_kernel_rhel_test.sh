#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
[[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
readonly PROGRAM_DIR

#mock PREREQUISITE functions
LIB_FUNC_IS_INTEL() { return 0 ; }
LIB_FUNC_IS_RHEL() { return 0 ; }
LIB_FUNC_NORMALIZE_KERNEL() { : ; }

LIB_FUNC_COMPARE_VERSIONS() {
    # shellcheck disable=SC2086
    return $COMPARE_VERSIONS_RC ;
}

OS_VERSION=''
OS_LEVEL=''
LIB_FUNC_NORMALIZE_KERNEL_RETURN=''
COMPARE_VERSIONS_RC=


test_rhel_not_supported() {

    #arrange
    OS_VERSION='6.9'

    #act
    check_0020_os_kernel_rhel

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_rhel_supported_kernel_tolow() {

    #arrange
    OS_VERSION='8.10'
    COMPARE_VERSIONS_RC=2

    #act
    check_0020_os_kernel_rhel

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_rhel_supported_kernel_ok() {

    #arrange
    OS_VERSION='8.10'
    COMPARE_VERSIONS_RC=1

    #act
    check_0020_os_kernel_rhel

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}


oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/0020_os_kernel_rhel.check
    source "${PROGRAM_DIR}/../../lib/check/0020_os_kernel_rhel.check"

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

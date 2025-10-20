#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
[[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
readonly PROGRAM_DIR

#mock PREREQUISITE functions
LIB_FUNC_IS_SLES() { return $IS_SLES_RC ; }
LIB_FUNC_IS_CLOUD_MICROSOFT() { return 1 ; }
LIB_FUNC_IS_IBMPOWER() { return 1 ; }
LIB_FUNC_NORMALIZE_KERNELn() { : ; }

LIB_FUNC_COMPARE_VERSIONS() {
    # shellcheck disable=SC2086
    return $COMPARE_VERSIONS_RC ;
}

OS_VERSION=''
OS_LEVEL=''
COMPARE_VERSIONS_RC=
IS_SLES_RC=


test_sles_kernel_with_issue() {

    #arrange
    IS_SLES_RC=0
    OS_VERSION='12.5'
    OS_LEVEL='4.12.14-122.1'
    COMPARE_VERSIONS_RC=0  # kernel equals upper boundary (not higher)

    #act
    check_0011_os_kernel_knownissue_sles

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_sles_kernel_no_issue() {

    #arrange
    IS_SLES_RC=0
    OS_VERSION='12.5'
    OS_LEVEL='4.12.14-122.8'
    COMPARE_VERSIONS_RC=1  # kernel higher than upper boundary

    #act
    check_0011_os_kernel_knownissue_sles

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_sles_not_applicable() {

    #arrange
    IS_SLES_RC=1  # not SLES
    OS_VERSION='11.3'
    OS_LEVEL='3.0.0'

    #act
    check_0011_os_kernel_knownissue_sles

    #assert
    assertEquals "CheckSkipped? RC" '3' "$?"
}


oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/0011_os_kernel_knownissue_sles.check
    source "${PROGRAM_DIR}/../../lib/check/0011_os_kernel_knownissue_sles.check"

}

# oneTimeTearDown

setUp() {

    OS_VERSION=
    OS_LEVEL=
    declare -i COMPARE_VERSIONS_RC=
    declare -i IS_SLES_RC=

}

# shellcheck source=../shunit2
source "${PROGRAM_DIR}/../shunit2"
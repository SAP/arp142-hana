#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
[[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
readonly PROGRAM_DIR

#mock PREREQUISITE functions
LIB_FUNC_IS_RHEL() { return $IS_RHEL_RC ; }
LIB_FUNC_IS_CLOUD_MICROSOFT() { return 1 ; }
LIB_FUNC_IS_IBMPOWER() { return 1 ; }
LIB_FUNC_NORMALIZE_KERNEL() { LIB_FUNC_NORMALIZE_KERNEL_RETURN="$1" ; }

LIB_FUNC_COMPARE_VERSIONS() {
    # shellcheck disable=SC2086
    return $COMPARE_VERSIONS_RC ;
}

OS_VERSION=''
OS_LEVEL=''
COMPARE_VERSIONS_RC=
IS_RHEL_RC=
LIB_FUNC_NORMALIZE_KERNEL_RETURN=''


test_rhel_kernel_with_issue() {

    #arrange
    IS_RHEL_RC=0
    OS_VERSION='9.2'
    OS_LEVEL='5.14.0-284.30.el9'
    COMPARE_VERSIONS_RC=0  # kernel equals upper boundary (not higher)

    #act
    check_0021_os_kernel_knownissues_rhel

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_rhel_kernel_no_issue() {

    #arrange
    IS_RHEL_RC=0
    OS_VERSION='9.2'
    OS_LEVEL='5.14.0-284.50.el9'
    COMPARE_VERSIONS_RC=1  # kernel higher than upper boundary

    #act
    check_0021_os_kernel_knownissues_rhel

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_rhel_not_applicable() {

    #arrange
    IS_RHEL_RC=1  # not RHEL
    OS_VERSION='11.3'
    OS_LEVEL='3.0.0'

    #act
    check_0021_os_kernel_knownissues_rhel

    #assert
    assertEquals "CheckSkipped? RC" '3' "$?"
}


oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/0021_os_kernel_knownissues_rhel.check
    source "${PROGRAM_DIR}/../../lib/check/0021_os_kernel_knownissues_rhel.check"

}

# oneTimeTearDown

setUp() {

    OS_VERSION=
    OS_LEVEL=
    declare -i COMPARE_VERSIONS_RC=
    declare -i IS_RHEL_RC=
    LIB_FUNC_NORMALIZE_KERNEL_RETURN=

}

# shellcheck source=../shunit2
source "${PROGRAM_DIR}/../shunit2"
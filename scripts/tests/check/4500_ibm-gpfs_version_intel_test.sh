#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
readonly PROGRAM_DIR

#fake PREREQUISITE functions
LIB_FUNC_IS_INTEL() { return 0 ; }
LIB_FUNC_IS_RHEL() { return 1 ; }
LIB_FUNC_IS_SLES() { return 0 ; }
LIB_FUNC_NORMALIZE_RPM() { : ; }

LIB_FUNC_COMPARE_VERSIONS() {
    # shellcheck disable=SC2086
    return $compare_version_rc ;
}

rpm() {
    return "${rpm_rc}"
}

OS_VERSION='15.3'                   #doesn't matter
LIB_FUNC_NORMALIZE_RPM_RETURN=''    #doesn't matter
declare -i compare_version_rc
declare -i rpm_rc

test_gpfs_not_installed() {

    #arrange
    rpm_rc=1

    #act
    check_4500_ibm-gpfs_version_intel

    #assert
    assertEquals "CheckSkipped? RC" '3' "$?"
}

test_gpfs_version_toolow() {

    #arrange
    rpm_rc=0
    compare_version_rc=2

    #act
    check_4500_ibm-gpfs_version_intel

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_gpfs_version_ok() {

    #arrange
    rpm_rc=0
    compare_version_rc=1

    #act
    check_4500_ibm-gpfs_version_intel

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}


oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/4500_ibm-gpfs_version_intel.check
    source "${PROGRAM_DIR}/../../lib/check/4500_ibm-gpfs_version_intel.check"

}

# oneTimeTearDown

setUp() {

    #reset before each test
    rpm_rc=
    compare_version_rc=

}

# tearDown

#Import Libraries
# - order is important - sourcing shunit triggers testing
# - that's also the reason, why it could not be done during oneTimeSetup

#Load and run shUnit2
#shellcheck source=../shunit2
source "${PROGRAM_DIR}/../shunit2"

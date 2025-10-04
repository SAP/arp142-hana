#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
[[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
readonly PROGRAM_DIR

#mock PREREQUISITE functions
LIB_FUNC_IS_SLES() { return 0 ; }
LIB_FUNC_NORMALIZE_RPM() { : ; }

LIB_FUNC_COMPARE_VERSIONS() { return "$compare_version_rc" ; }
rpm() { return "${rpm_rc}" ; }
systemctl() { return "${isused_rc}" ; }

OS_VERSION=''
LIB_FUNC_NORMALIZE_RPM_RETURN=''    #doesn't matter
declare -i compare_version_rc
declare -i rpm_rc
declare -i isused_rc


test_rpm_not_installed() {

    #arrange
    rpm_rc=1

    #act
    check_7010_corosync_version

    #assert
    assertEquals "CheckSkipped? RC" '3' "$?"
}

test_OS_not_applicable() {

    #arrange
    rpm_rc=0
    OS_VERSION='11.4'

    #act
    check_7010_corosync_version

    #assert
    assertEquals "CheckSkipped? RC" '3' "$?"
}

test_OS_not_listed() {

    #arrange
    rpm_rc=0
    OS_VERSION='14.0'

    #act
    check_7010_corosync_version

    #assert
    assertEquals "CheckSkipped? RC" '3' "$?"
}

test_rpm_ok_sles12all() {

    #arrange
    rpm_rc=0
    OS_VERSION='12.5'       #test against 12.*
    compare_version_rc=1

    #act
    check_7010_corosync_version

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_rpm_ok_sles152() {

    #arrange
    rpm_rc=0
    OS_VERSION='15.3'       #test against 15.3
    compare_version_rc=1

    #act
    check_7010_corosync_version

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_rpm_old_but_not_used() {

    #arrange
    rpm_rc=0
    OS_VERSION='15.3'
    compare_version_rc=2
    isused_rc=1

    #act
    check_7010_corosync_version

    #assert
    assertEquals "CheckWarning? RC" '1' "$?"
}

test_rpm_old_and_used() {

    #arrange
    rpm_rc=0
    OS_VERSION='15.3'
    compare_version_rc=2
    isused_rc=0

    #act
    check_7010_corosync_version

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}


oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/7010_corosync_version.check
    source "${PROGRAM_DIR}/../../lib/check/7010_corosync_version.check"

}

# oneTimeTearDown

setUp() {

    OS_VERSION=
    rpm_rc=
    compare_version_rc=
    isused_rc=

}

# tearDown

#Import Libraries
# - order is important - sourcing shunit triggers testing
# - that's also the reason, why it could not be done during oneTimeSetup

#Load and run shUnit2
#shellcheck source=../shunit2
source "${PROGRAM_DIR}/../shunit2"

#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
[[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
readonly PROGRAM_DIR

#mock PREREQUISITE functions
LIB_FUNC_IS_SLES() { return 0 ; }
LIB_FUNC_IS_RHEL() { return 1 ; }
LIB_FUNC_NORMALIZE_RPMn() { : ; }

LIB_FUNC_COMPARE_VERSIONS() { return "$compare_version_rc" ; }
rpm() {
    if [[ "$1" == "-q" && "$2" == "--quiet" ]]; then
        return "${rpm_installed_rc}"
    elif [[ "$1" == "-q" && "$2" == "--queryformat" ]]; then
        printf "%s\n" "${rpm_version_output}"
        return 0
    else
        return 1
    fi
}

systemctl() {
    if [[ "$1" == "is-enabled" && "$2" == "pacemaker" ]]; then
        return "${systemctl_enabled_rc}"
    elif [[ "$1" == "is-active" && "$2" == "pacemaker" ]]; then
        return "${systemctl_active_rc}"
    else
        return 1
    fi
}

OS_VERSION=''
declare -i compare_version_rc
declare -i rpm_installed_rc
declare -i systemctl_enabled_rc
declare -i systemctl_active_rc
declare rpm_version_output


test_pacemaker_not_installed() {

    #arrange
    rpm_installed_rc=1

    #act
    check_7015_pacemaker_version

    #assert
    assertEquals "CheckSkipped? RC" '3' "$?"
}

test_rhel_os_not_applicable() {

    #arrange
    LIB_FUNC_IS_SLES() { return 1 ; }
    LIB_FUNC_IS_RHEL() { return 0 ; }
    rpm_installed_rc=0

    #act
    check_7015_pacemaker_version

    #assert
    assertEquals "CheckSkipped? RC" '3' "$?"
}

test_sles_version_not_handled() {

    #arrange
    rpm_installed_rc=0
    OS_VERSION='14.0'
    systemctl_enabled_rc=1
    systemctl_active_rc=1

    #act
    check_7015_pacemaker_version

    #assert
    assertEquals "CheckSkipped? RC" '3' "$?"
}

test_sles15_5_version_ok_enabled_and_active() {

    #arrange
    rpm_installed_rc=0
    OS_VERSION='15.5'
    rpm_version_output='2.1.5+20221208.a3f44794f-150500.99.99.1'
    compare_version_rc=1  # current version is higher than required
    systemctl_enabled_rc=0  # enabled
    systemctl_active_rc=0   # active

    #act
    check_7015_pacemaker_version

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_sles15_6_version_ok_not_used() {

    #arrange
    rpm_installed_rc=0
    OS_VERSION='15.6'
    rpm_version_output='2.1.7+20231219.0f7f88312-150600.99.99.1'
    compare_version_rc=1  # current version is higher than required
    systemctl_enabled_rc=1  # not enabled
    systemctl_active_rc=1   # not active

    #act
    check_7015_pacemaker_version

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_sles15_7_version_ok_equal() {

    #arrange
    rpm_installed_rc=0
    OS_VERSION='15.7'
    rpm_version_output='2.1.10+20250718.fdf796ebc8-150700.3.3.1'
    compare_version_rc=0  # versions are equal
    systemctl_enabled_rc=0  # enabled
    systemctl_active_rc=1   # not active

    #act
    check_7015_pacemaker_version

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_sles15_5_version_old_pacemaker_enabled() {

    #arrange
    rpm_installed_rc=0
    OS_VERSION='15.5'
    rpm_version_output='2.1.5+20221208.a3f44794f-150500.6.20.1'
    compare_version_rc=2  # current version is lower than required
    systemctl_enabled_rc=0  # enabled
    systemctl_active_rc=1   # not active

    #act
    check_7015_pacemaker_version

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_sles15_6_version_old_pacemaker_active() {

    #arrange
    rpm_installed_rc=0
    OS_VERSION='15.6'
    rpm_version_output='2.1.7+20231219.0f7f88312-150600.6.10.1'
    compare_version_rc=2  # current version is lower than required
    systemctl_enabled_rc=1  # not enabled
    systemctl_active_rc=0   # active

    #act
    check_7015_pacemaker_version

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_sles15_7_version_old_pacemaker_not_used() {

    #arrange
    rpm_installed_rc=0
    OS_VERSION='15.7'
    rpm_version_output='2.1.10+20250718.fdf796ebc8-150700.3.2.1'
    compare_version_rc=2  # current version is lower than required
    systemctl_enabled_rc=1  # not enabled
    systemctl_active_rc=1   # not active

    #act
    check_7015_pacemaker_version

    #assert
    assertEquals "CheckWarning? RC" '1' "$?"
}

test_sles15_5_version_old_both_enabled_and_active() {

    #arrange
    rpm_installed_rc=0
    OS_VERSION='15.5'
    rpm_version_output='2.1.4+20220407.b2935090a-150500.6.15.1'
    compare_version_rc=2  # current version is lower than required
    systemctl_enabled_rc=0  # enabled
    systemctl_active_rc=0   # active

    #act
    check_7015_pacemaker_version

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/7015_pacemaker_version.check
    source "${PROGRAM_DIR}/../../lib/check/7015_pacemaker_version.check"

}

# oneTimeTearDown

setUp() {

    # Reset all mock variables
    OS_VERSION=
    compare_version_rc=
    rpm_installed_rc=
    systemctl_enabled_rc=
    systemctl_active_rc=
    rpm_version_output=

    # Reset function mocks to defaults
    LIB_FUNC_IS_SLES() { return 0 ; }
    LIB_FUNC_IS_RHEL() { return 1 ; }

}

# tearDown

#Import Libraries
# - order is important - sourcing shunit triggers testing
# - that's also the reason, why it could not be done during oneTimeSetup

#Load and run shUnit2
#shellcheck source=../shunit2
source "${PROGRAM_DIR}/../shunit2"
#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
readonly PROGRAM_DIR

#mock PREREQUISITE functions
LIB_FUNC_IS_RHEL() { return 0 ; }
LIB_FUNC_NORMALIZE_RPM() { : ; }

LIB_FUNC_COMPARE_VERSIONS() { return "$compare_version_rc" ; }
rpm() { return "${rpm_rc}" ; }

OS_VERSION=''
LIB_FUNC_NORMALIZE_RPM_RETURN=''    #doesn't matter
declare -i compare_version_rc
declare -i rpm_rc


test_rpm_not_installed() {

    #arrange
    rpm_rc=1

    #act
    check_7031_ha_resource_agent_scaleout_rhel

    #assert
    assertEquals "CheckSkipped? RC" '3' "$?"
}

test_OS_not_listed() {

    #arrange
    rpm_rc=0
    OS_VERSION='6.5'

    #act
    check_7031_ha_resource_agent_scaleout_rhel

    #assert
    assertEquals "CheckWarning? RC" '1' "$?"
}

test_rpm_ok() {

    #arrange
    rpm_rc=0
    OS_VERSION='7.9'
    compare_version_rc=1

    #act
    check_7031_ha_resource_agent_scaleout_rhel

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_rpm_old() {

    #arrange
    rpm_rc=0
    OS_VERSION='8.10'
    compare_version_rc=2

    #act
    check_7031_ha_resource_agent_scaleout_rhel

    #assert
    assertEquals "CheckWarning? RC" '1' "$?"
}


oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/7031_ha_resource_agent_scaleout_rhel.check
    source "${PROGRAM_DIR}/../../lib/check/7031_ha_resource_agent_scaleout_rhel.check"

}

# oneTimeTearDown

setUp() {

    OS_VERSION=
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

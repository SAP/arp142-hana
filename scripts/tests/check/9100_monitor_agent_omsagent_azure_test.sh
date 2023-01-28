#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
readonly PROGRAM_DIR

#mock PREREQUISITE functions
LIB_FUNC_IS_CLOUD_MICROSOFT() { return 0 ; }
LIB_FUNC_NORMALIZE_RPM() { : ; }

LIB_FUNC_COMPARE_VERSIONS() { return "$compare_version_rc" ; }
rpm() { return "${rpm_rc}" ; }

LIB_FUNC_NORMALIZE_RPM_RETURN=''    #doesn't matter
declare -i compare_version_rc
declare -i rpm_rc


test_rpm_not_installed() {

    #arrange
    rpm_rc=1

    #act
    check_9100_monitor_agent_omsagent_azure

    #assert
    assertEquals "CheckSkipped? RC" '3' "$?"
}

test_rpm_ok() {

    #arrange
    rpm_rc=0
    compare_version_rc=1

    #act
    check_9100_monitor_agent_omsagent_azure

    #assert
    assertEquals "CheckWarning? RC" '1' "$?"
}

test_rpm_old() {

    #arrange
    rpm_rc=0
    compare_version_rc=2

    #act
    check_9100_monitor_agent_omsagent_azure

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}


oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/9100_monitor_agent_omsagent_azure.check
    source "${PROGRAM_DIR}/../../lib/check/9100_monitor_agent_omsagent_azure.check"

}

# oneTimeTearDown

setUp() {

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

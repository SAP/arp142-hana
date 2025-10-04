#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
[[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
readonly PROGRAM_DIR

#mock PREREQUISITE functions
LIB_FUNC_IS_SLES() { return 0 ; }
LIB_FUNC_NORMALIZE_RPMn() { : ; }

LIB_FUNC_COMPARE_VERSIONS() { return "$compare_version_rc" ; }
rpm() { return "${rpm_rc}" ; }

OS_VERSION=''
declare -i compare_version_rc
declare -i rpm_rc


test_rpm_not_installed() {

    #arrange
    rpm_rc=1

    #act
    check_7020_ha_resource_agents_sles

    #assert
    assertEquals "CheckSkipped? RC" '3' "$?"
}

test_rpm_ok() {

    #arrange
    rpm_rc=0
    OS_VERSION='12.5'
    compare_version_rc=1

    #act
    check_7020_ha_resource_agents_sles

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_rpm_old() {

    #arrange
    rpm_rc=0
    OS_VERSION='15.5'
    compare_version_rc=2

    #act
    check_7020_ha_resource_agents_sles

    #assert
    assertEquals "CheckWarning? RC" '1' "$?"
}


oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/7020_ha_resource_agents_sles.check
    source "${PROGRAM_DIR}/../../lib/check/7020_ha_resource_agents_sles.check"

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

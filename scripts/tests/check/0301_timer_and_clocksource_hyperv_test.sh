#!/usr/bin/env bash
set -u      # treat unset variables as an error

PROGRAM_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
readonly PROGRAM_DIR

#fake PREREQUISITE functions
LIB_FUNC_IS_VIRT_MICROSOFT() { return 0 ; }

# still to mock for tests
# /sys/devices/system/clocksource/clocksource0/current_clocksource
TEST_CURRENT_CLOCKSOURCE=''

test_reco_clock() {

    #arrange
    TEST_CURRENT_CLOCKSOURCE='hyperv_clocksource_tsc_page'

    #act
    check_0301_timer_and_clocksource_hyperv

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_wrong_clocksource() {

    #arrange
    TEST_CURRENT_CLOCKSOURCE='acpi_pm'

    #act
    check_0301_timer_and_clocksource_hyperv

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

 oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/0300_timer_and_clocksource_intel.check
    source "${PROGRAM_DIR}/../../lib/check/0301_timer_and_clocksource_hyperv.check"

 }

# oneTimeTearDown

# setUp

# tearDown

#Import Libraries
# - order is important - sourcing shunit triggers testing
# - that's also the reason, why it could not be done during oneTimeSetup

#Load and run shUnit2
#shellcheck source=../shunit2
source "${PROGRAM_DIR}/../shunit2"

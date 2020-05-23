#!/usr/bin/env bash
set -u      # treat unset variables as an error

PROGRAM_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
readonly PROGRAM_DIR

#fake PREREQUISITE functions
LIB_FUNC_IS_VIRT_MICROSOFT() { return 0 ; }
LIB_FUNC_IS_SLES() { return 0 ; }
LIB_FUNC_IS_RHEL() { return 1 ; }

LIB_FUNC_NORMALIZE_KERNEL() {
    # shellcheck disable=SC2034
    LIB_FUNC_NORMALIZE_KERNEL_RETURN="$1" ;
}

LIB_FUNC_COMPARE_VERSIONS() { return "${RC_COMPARE_VERSIONS}" ; }

# still to mock for tests
# /sys/devices/system/clocksource/clocksource0/current_clocksource
TEST_CURRENT_CLOCKSOURCE=''
OS_LEVEL=''

test_reco_clock_vdso() {

    #arrange
    TEST_CURRENT_CLOCKSOURCE='hyperv_clocksource_tsc_page'

    OS_LEVEL='4.4.178-94.91'                 #VDSO support
    RC_COMPARE_VERSIONS=1

    #act
    check_0301_timer_and_clocksource_hyperv

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_reco_clock_no_vdso() {

    #arrange
    TEST_CURRENT_CLOCKSOURCE='hyperv_clocksource_tsc_page'

    OS_LEVEL='4.4.178-94.90'                 #no VDSO support
    RC_COMPARE_VERSIONS=2

    #act
    check_0301_timer_and_clocksource_hyperv

    #assert
    assertEquals "CheckError? RC" '2' "$?"
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

setUp() {

    # shellcheck disable=SC2034
    OS_LEVEL=
}

# tearDown

#Import Libraries
# - order is important - sourcing shunit triggers testing
# - that's also the reason, why it could not be done during oneTimeSetup

#Load and run shUnit2
#shellcheck source=../shunit2
source "${PROGRAM_DIR}/../shunit2"

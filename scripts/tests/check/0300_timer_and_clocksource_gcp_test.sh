#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
readonly PROGRAM_DIR

#fake PREREQUISITE functions
LIB_FUNC_IS_INTEL() { return 0 ; }
LIB_FUNC_IS_VIRT_MICROSOFT() { return 1 ; }
LIB_FUNC_IS_CLOUD_GOOGLE() { return 0 ; }
LIB_FUNC_IS_VIRT_KVM() { return 0 ; }

# still to mock for tests
# grep /proc/cpuinfo
# /sys/devices/system/clocksource/clocksource0/current_clocksource
# /sys/devices/system/clocksource/clocksource0/available_clocksource
TEST_CURRENT_CLOCKSOURCE=''
TEST_AVAILABLE_CLOCKSOURCE=''

grep() {
    #we fake <(grep -e '^flags' -m1 /proc/cpuinfo |
            #  grep -E -e 'constant_tsc|nonstop_tsc|rdtscp' -o)
    case "$*" in
        '-e ^flags'* )  : ;;

        '-E -e constant_tsc'* )
                        : ;;

        *)              command grep "$@" ;; # shunit2 requires grep
    esac
}

test_correct_clocksource() {

    #arrange
    TEST_CURRENT_CLOCKSOURCE='kvm-clock'
    TEST_AVAILABLE_CLOCKSOURCE='tsc kvm-clock'

    #act
    check_0300_timer_and_clocksource_intel

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_all_cpu_flags_available_and_wrong_clocksource() {

    #arrange
    TEST_CURRENT_CLOCKSOURCE='xen'
    TEST_AVAILABLE_CLOCKSOURCE='kvm-clock tsc'

    #act
    check_0300_timer_and_clocksource_intel

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

 oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/0300_timer_and_clocksource_intel.check
    source "${PROGRAM_DIR}/../../lib/check/0300_timer_and_clocksource_intel.check"

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

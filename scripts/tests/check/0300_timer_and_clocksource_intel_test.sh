#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
readonly PROGRAM_DIR

#fake PREREQUISITE functions
LIB_FUNC_IS_INTEL() { return 0 ; }
LIB_FUNC_IS_VIRT_MICROSOFT() { return 1 ; }
LIB_FUNC_IS_CLOUD_GOOGLE() { return 1 ; }
LIB_FUNC_IS_VIRT_KVM() { return 1 ; }

# still to mock for tests
# grep /proc/cpuinfo
# /sys/devices/system/clocksource/clocksource0/current_clocksource
# /sys/devices/system/clocksource/clocksource0/available_clocksource
cpu_flags=''
TEST_CURRENT_CLOCKSOURCE=''
TEST_AVAILABLE_CLOCKSOURCE=''

grep() {
    #we fake <(grep -e '^flags' -m1 /proc/cpuinfo |
            #  grep -E -e 'constant_tsc|nonstop_tsc|rdtscp' -o)
    case "$*" in
        '-e ^flags'* )  : ;;

        '-E -e constant_tsc'* )
                        printf "%s\n" "${cpu_flags[@]}" ;;

        *)              command grep "$@" ;; # shunit2 requires grep
    esac
}

test_all_cpu_flags_available_and_correct_clocksource() {

    #arrange
    cpu_flags=()
    cpu_flags+=('constant_tsc')
    cpu_flags+=('nonstop_tsc')
    cpu_flags+=('rdtscp')

    TEST_CURRENT_CLOCKSOURCE='tsc'
    TEST_AVAILABLE_CLOCKSOURCE='tsc'

    #act
    check_0300_timer_and_clocksource_intel

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_all_cpu_flags_available_and_wrong_clocksource() {

    #arrange
    cpu_flags=()
    cpu_flags+=('constant_tsc')
    cpu_flags+=('nonstop_tsc')
    cpu_flags+=('rdtscp')

    TEST_CURRENT_CLOCKSOURCE='kvm-clock'
    TEST_AVAILABLE_CLOCKSOURCE='kvm-clock tsc'

    #act
    check_0300_timer_and_clocksource_intel

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_missing_rdtscp_but_correct_clocksource() {

    #arrange
    cpu_flags=()
    cpu_flags+=('constant_tsc')
    cpu_flags+=('nonstop_tsc')

    TEST_CURRENT_CLOCKSOURCE='tsc'
    TEST_AVAILABLE_CLOCKSOURCE='tsc'

    #act
    check_0300_timer_and_clocksource_intel

    #assert
    assertEquals "CheckWarning? RC" '1' "$?"
}

test_missing_rdtscp_and_wrong_clocksource() {

    #arrange
    cpu_flags=()
    cpu_flags+=('constant_tsc')
    cpu_flags+=('nonstop_tsc')

    TEST_CURRENT_CLOCKSOURCE='kvm-clock'
    TEST_AVAILABLE_CLOCKSOURCE='kvm-clock tsc'

    #act
    check_0300_timer_and_clocksource_intel

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_missing_constant_tsc() {

    #arrange
    cpu_flags=()
    cpu_flags+=('nonstop_tsc')
    cpu_flags+=('rdtscp')

    #act
    check_0300_timer_and_clocksource_intel

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_missing_nonstop_tsc() {

    #arrange
    cpu_flags=()
    cpu_flags+=('constant_tsc')
    cpu_flags+=('rdtsc')

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

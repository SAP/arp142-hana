#! /bin/bash
set -u  # treat unset variables as an error

PROGRAM_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
readonly PROGRAM_DIR

#fake PREREQUISITE functions
LIB_FUNC_IS_INTEL() { return 0 ; }
LIB_FUNC_IS_VIRT_MICROSOFT() { return 1 ; }

# still to fake for tests
# grep /proc/cpuinfo
# /sys/devices/system/clocksource/clocksource0/current_clocksource
# /sys/devices/system/clocksource/clocksource0/available_clocksource
cpu_flags=''
TEST_CURRENT_CLOCKSOURCE=''
TEST_AVAILABLE_CLOCKSOURCE=''

grep() {
    #we fake <(grep -e '^flags' -m1 /proc/cpuinfo | grep -E -e 'constant_tsc|nonstop_tsc|rdtscp' -o)
    for item in ${cpu_flags[*]}
    do
        printf "%s\n" "${item}"
    done
}

test_all_cpu_flags_available_and_correct_clocksource() {

    #arrange
    cpu_flags=()
    cpu_flags+=('constant_tsc')
    cpu_flags+=('nonstop_tsc')
    cpu_flags+=('rdtscp')

    TEST_CURRENT_CLOCKSOURCE='tsc'
    TEST_AVAILABLE_CLOCKSOURCE='tsc'

    #test
    check_0300_timer_and_clocksource_intel

    #assert
    assertTrue "${FUNCNAME[0]} failure - expect RC=0 (CheckOk)" "[ $? -eq 0 ]"
}

test_all_cpu_flags_available_and_wrong_clocksource() {

    #arrange
    cpu_flags=()
    cpu_flags+=('constant_tsc')
    cpu_flags+=('nonstop_tsc')
    cpu_flags+=('rdtscp')

    TEST_CURRENT_CLOCKSOURCE='kvm_clock'
    TEST_AVAILABLE_CLOCKSOURCE='kvm_clock tsc'

    #test
    check_0300_timer_and_clocksource_intel

    #assert
    assertTrue "${FUNCNAME[0]} failure - expect RC=2 (CheckError)" "[ $? -eq 2 ]"
}

test_missing_rdtscp_but_correct_clocksource() {

    #arrange
    cpu_flags=()
    cpu_flags+=('constant_tsc')
    cpu_flags+=('nonstop_tsc')

    TEST_CURRENT_CLOCKSOURCE='tsc'
    TEST_AVAILABLE_CLOCKSOURCE='tsc'

    #test
    check_0300_timer_and_clocksource_intel

    #test
    assertTrue "${FUNCNAME[0]} failure - expect RC=1 (CheckWarning)" "[ $? -eq 1 ]"
}

test_missing_rdtscp_and_wrong_clocksource() {

    #arrange
    cpu_flags=()
    cpu_flags+=('constant_tsc')
    cpu_flags+=('nonstop_tsc')

    TEST_CURRENT_CLOCKSOURCE='kvm_clock'
    TEST_AVAILABLE_CLOCKSOURCE='kvm_clock tsc'

    #test
    check_0300_timer_and_clocksource_intel

    #test
    assertTrue "${FUNCNAME[0]} failure - expect RC=2 (CheckError)" "[ $? -eq 2 ]"
}

test_missing_constant_tsc() {

    #arrange
    cpu_flags=()
    cpu_flags+=('nonstop_tsc')
    cpu_flags+=('rdtscp')

    #test
    check_0300_timer_and_clocksource_intel

    #assert
    assertTrue "${FUNCNAME[0]} failure  - expect RC=2 (CheckError)" "[ $? -eq 2 ]"
}

test_missing_nonstop_tsc() {

    #arrange
    cpu_flags=()
    cpu_flags+=('constant_tsc')
    cpu_flags+=('rdtsc')

    #test
    check_0300_timer_and_clocksource_intel

    #assert
    assertTrue "${FUNCNAME[0]} failure  - expect RC=2 (CheckError)" "[ $? -eq 2 ]"
}


# testCompareTooBigNumbersShouldFail() {
#     local -i _rc

#     #The following tests should fail (test the tester)
#     LIB_COMPARE_TOOBIG_NUMBERS '1' '2'
#     _rc=$?
#     assertNotEquals 'test[1]: testing the tester failed' '0' "${_rc}"
#     assertNotEquals 'test[1]: testing the tester failed' '1' "${_rc}"

#     LIB_COMPARE_TOOBIG_NUMBERS '2' '2'
#     _rc=$?
#     assertNotEquals 'test[2]: testing the tester failed' '1' "${_rc}"
#     assertNotEquals 'test[2]: testing the tester failed' '2' "${_rc}"

#     LIB_COMPARE_TOOBIG_NUMBERS '2' '1'
#     _rc=$?
#     assertNotEquals 'test[3]: testing the tester failed' '0' "${_rc}"
#     assertNotEquals 'test[3]: testing the tester failed' '2' "${_rc}"
# }

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

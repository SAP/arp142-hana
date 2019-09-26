#! /bin/bash
set -u      # treat unset variables as an error

PROGRAM_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
readonly PROGRAM_DIR

#fake PREREQUISITE functions
LIB_FUNC_IS_VIRT_MICROSOFT() { return 0 ; }
LIB_FUNC_IS_SLES() { return 0 ; }
LIB_FUNC_IS_RHEL() { return 1 ; }
LIB_FUNC_NORMALIZE_KERNEL() { LIB_FUNC_NORMALIZE_KERNEL_RETURN="$1" ; }
LIB_FUNC_COMPARE_VERSIONS() { return "${RC_COMPARE_VERSIONS}" ; }

# still to fake for tests
# grep /proc/cpuinfo
# /sys/devices/system/clocksource/clocksource0/current_clocksource
# /sys/devices/system/clocksource/clocksource0/available_clocksource
cpu_flags=''
TEST_CURRENT_CLOCKSOURCE=''
TEST_AVAILABLE_CLOCKSOURCE=''

OS_LEVEL=''

grep() {
    #we fake <(grep -e '^flags' -m1 /proc/cpuinfo | grep -E -e 'constant_tsc|nonstop_tsc|rdtscp' -o)
    for item in ${cpu_flags[*]}
    do
        printf "%s\n" "${item}"
    done
}

test_all_cpu_flags_and_tsc_clocksource() {

    # currently this is not possible - hyperv does not offer <tsc> clocksource

    #arrange
    cpu_flags=()
    cpu_flags+=('constant_tsc')
    cpu_flags+=('nonstop_tsc')
    cpu_flags+=('rdtscp')

    TEST_CURRENT_CLOCKSOURCE='tsc'
    TEST_AVAILABLE_CLOCKSOURCE='tsc'

    #test
    check_0301_timer_and_clocksource_hyperv

    #assert
    assertTrue "${FUNCNAME[0]} failure - expect RC=0 (CheckOk)" "[ $? -eq 0 ]"
}

test_all_cpu_flags_and_reco_clock_vdso() {

    #this will be the standard case

    #arrange
    cpu_flags=()
    cpu_flags+=('constant_tsc')
    cpu_flags+=('nonstop_tsc')
    cpu_flags+=('rdtscp')

    TEST_CURRENT_CLOCKSOURCE='hyperv_clocksource_tsc_page'
    TEST_AVAILABLE_CLOCKSOURCE='hyperv_clocksource_tsc_page acpi_pm'

    RC_COMPARE_VERSIONS=1   #VDSO support

    #test
    check_0301_timer_and_clocksource_hyperv

    #assert
    assertTrue "${FUNCNAME[0]} failure - expect RC=1 (CheckWarning)" "[ $? -eq 1 ]"
}

test_all_cpu_flags_and_reco_clock_no_vdso() {

    #this will be the standard case

    #arrange
    cpu_flags=()
    cpu_flags+=('constant_tsc')
    cpu_flags+=('nonstop_tsc')
    cpu_flags+=('rdtscp')

    TEST_CURRENT_CLOCKSOURCE='hyperv_clocksource_tsc_page'
    TEST_AVAILABLE_CLOCKSOURCE='hyperv_clocksource_tsc_page acpi_pm'

    RC_COMPARE_VERSIONS=2   #no VDSO support

    #test
    check_0301_timer_and_clocksource_hyperv

    #assert
    assertTrue "${FUNCNAME[0]} failure - expect RC=2 (CheckError)" "[ $? -eq 2 ]"
}

test_all_cpu_flags_and_wrong_clocksource() {

    #arrange
    cpu_flags=()
    cpu_flags+=('constant_tsc')
    cpu_flags+=('nonstop_tsc')
    cpu_flags+=('rdtscp')

    TEST_CURRENT_CLOCKSOURCE='acpi_pm'
    TEST_AVAILABLE_CLOCKSOURCE='hyperv_clocksource_tsc_page acpi_pm'

    #test
    check_0301_timer_and_clocksource_hyperv

    #assert
    assertTrue "${FUNCNAME[0]} failure - expect RC=2 (CheckError)" "[ $? -eq 2 ]"
}

test_missing_rdtscp_and_tsc_clocksource() {

    # currently this is not possible - hyperv does not offer TSC

    #arrange
    cpu_flags=()
    cpu_flags+=('constant_tsc')
    cpu_flags+=('nonstop_tsc')

    TEST_CURRENT_CLOCKSOURCE='tsc'
    TEST_AVAILABLE_CLOCKSOURCE='tsc'

    #test
    check_0301_timer_and_clocksource_hyperv

    #test
    assertTrue "${FUNCNAME[0]} failure - expect RC=1 (CheckWarning)" "[ $? -eq 1 ]"
}

test_missing_rdtscp_and_reco_clock_vdso() {

    #this will be the standard case

    #arrange
    cpu_flags=()
    cpu_flags+=('constant_tsc')
    cpu_flags+=('nonstop_tsc')

    TEST_CURRENT_CLOCKSOURCE='hyperv_clocksource_tsc_page'
    TEST_AVAILABLE_CLOCKSOURCE='hyperv_clocksource_tsc_page acpi_pm'

    RC_COMPARE_VERSIONS=1   #VDSO support

    #test
    check_0301_timer_and_clocksource_hyperv

    #assert
    assertTrue "${FUNCNAME[0]} failure - expect RC=1 (CheckWarning)" "[ $? -eq 1 ]"
}

test_missing_rdtscp_and_reco_clock_no-vdso() {

    #this will be the standard case

    #arrange
    cpu_flags=()
    cpu_flags+=('constant_tsc')
    cpu_flags+=('nonstop_tsc')

    TEST_CURRENT_CLOCKSOURCE='hyperv_clocksource_tsc_page'
    TEST_AVAILABLE_CLOCKSOURCE='hyperv_clocksource_tsc_page acpi_pm'

    RC_COMPARE_VERSIONS=2   #no VDSO support

    #test
    check_0301_timer_and_clocksource_hyperv

    #assert
    assertTrue "${FUNCNAME[0]} failure - expect RC=2 (CheckError)" "[ $? -eq 2 ]"
}

test_missing_rdtscp_and_wrong_clocksource() {

    #arrange
    cpu_flags=()
    cpu_flags+=('constant_tsc')
    cpu_flags+=('nonstop_tsc')

    TEST_CURRENT_CLOCKSOURCE='acpi_pm'
    TEST_AVAILABLE_CLOCKSOURCE='hyperv_clocksource_tsc_page acpi_pm'

    #test
    check_0301_timer_and_clocksource_hyperv

    #test
    assertTrue "${FUNCNAME[0]} failure - expect RC=2 (CheckError)" "[ $? -eq 2 ]"
}

test_missing_constant_tsc() {

    #arrange
    cpu_flags=()
    cpu_flags+=('nonstop_tsc')
    cpu_flags+=('rdtscp')

    #test
    check_0301_timer_and_clocksource_hyperv

    #assert
    assertTrue "${FUNCNAME[0]} failure  - expect RC=2 (CheckError)" "[ $? -eq 2 ]"
}

test_missing_nonstop_tsc() {

    #arrange
    cpu_flags=()
    cpu_flags+=('constant_tsc')
    cpu_flags+=('rdtsc')

    #test
    check_0301_timer_and_clocksource_hyperv

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

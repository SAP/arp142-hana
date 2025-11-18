#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
[[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
readonly PROGRAM_DIR

#mock PREREQUISITE functions
LIB_FUNC_IS_INTEL() { return 0 ; }
LIB_FUNC_IS_SLES() { return 0 ; }
LIB_FUNC_IS_RHEL() { return 1 ; }  # Default: not RHEL (we test SLES by default)
LIB_FUNC_IS_ROOT() { return 0 ; }
declare TEST_INTEL_IDLE='intel_idle'

# still to mock for tests
# OS_VERSION
# TEST_INTEL_IDLE
# _maxCstateLatency
# _maxForceLatency

hexdump() {
    #we fake $(hexdump -e '"%i"' /dev/cpu_dma_latency)
    printf "%s\n" "${TEST_maxForceLatency}"
}

OS_VERSION=''
OS_NAME=''
declare -i TEST_driverMaxCstate
declare -i TEST_maxCstateLatency
declare -i TEST_maxForceLatency


test_latency_cstate_high_cstatelatency_too_high33() {

    #arrange
    OS_VERSION='12.5'
    TEST_driverMaxCstate=6
    TEST_maxCstateLatency=33            #C1=3, C1E=10, C3=33, C6=133
    TEST_maxForceLatency=2000000000

    #act
    check_1410_cpu_idle_intel_cstates_intel

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_latency_cstate_high_forcelatency_too_high() {

    #arrange
    OS_VERSION='12.5'
    TEST_driverMaxCstate=6
    TEST_maxCstateLatency=2000000000
    TEST_maxForceLatency=70

    #act
    check_1410_cpu_idle_intel_cstates_intel

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_latency_cstate_high_cstatelatency_correct10() {

    #arrange
    OS_VERSION='12.5'
    TEST_driverMaxCstate=6
    TEST_maxCstateLatency=10
    TEST_maxForceLatency=2000000000

    #act
    check_1410_cpu_idle_intel_cstates_intel

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_latency_cstate_high_forcelatency_correct3() {

    #arrange
    OS_VERSION='12.5'
    TEST_driverMaxCstate=6
    TEST_maxCstateLatency=2000000000
    TEST_maxForceLatency=3

    #act
    check_1410_cpu_idle_intel_cstates_intel

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_latency_cstate_too_low_cstatelatency_too_low() {

    #arrange
    OS_VERSION='12.5'
    TEST_driverMaxCstate=1
    TEST_maxCstateLatency=3
    TEST_maxForceLatency=2000000000

    #act
    check_1410_cpu_idle_intel_cstates_intel

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_latency_cstate_latency_exactly1_should_warn() {

    #arrange
    OS_VERSION='12.5'
    TEST_driverMaxCstate=6
    TEST_maxCstateLatency=1
    TEST_maxForceLatency=2000000000

    #act
    check_1410_cpu_idle_intel_cstates_intel

    #assert
    assertEquals "CheckWarn? RC" '1' "$?"
}

test_latency_cstate_latency_exactlyC1_should_warn() {

    #arrange
    OS_VERSION='12.5'
    TEST_driverMaxCstate=6
    TEST_maxCstateLatency=2
    TEST_maxForceLatency=2000000000

    #act
    check_1410_cpu_idle_intel_cstates_intel

    #assert
    assertEquals "CheckWarn? RC" '1' "$?"
}

# OS VERSION TESTS
test_sles15_supported() {

    #arrange
    OS_VERSION='15.4'
    TEST_driverMaxCstate=6
    TEST_maxCstateLatency=5
    TEST_maxForceLatency=2000000000

    #act
    check_1410_cpu_idle_intel_cstates_intel

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_sles_unsupported_version() {

    #arrange
    OS_VERSION='11.4'  # Unsupported SLES version
    TEST_driverMaxCstate=6
    TEST_maxCstateLatency=5
    TEST_maxForceLatency=2000000000

    #act
    check_1410_cpu_idle_intel_cstates_intel

    #assert
    assertEquals "CheckWarning? RC" '1' "$?"
}

# ROOT PERMISSION TESTS
test_non_root_warning() {

    #arrange
    local orig_root_func
    orig_root_func=$(declare -f LIB_FUNC_IS_ROOT)

    LIB_FUNC_IS_ROOT() { return 1 ; }  # Mock non-root
    OS_VERSION='12.5'
    TEST_driverMaxCstate=6
    TEST_maxCstateLatency=5
    TEST_maxForceLatency=2000000000

    #act
    check_1410_cpu_idle_intel_cstates_intel

    #assert
    assertEquals "CheckOk? RC" '0' "$?"

    # Restore mock
    eval "$orig_root_func"
}

# DRIVER MAX CSTATE WARNING
test_driver_maxcstate_warning() {

    #arrange
    OS_VERSION='12.5'
    TEST_driverMaxCstate=0  # Restrictive max_cstate
    TEST_maxCstateLatency=1  # Low latency that triggers warning
    TEST_maxForceLatency=2000000000

    #act
    check_1410_cpu_idle_intel_cstates_intel

    #assert
    assertEquals "CheckWarn? RC" '1' "$?"
}

# EDGE CASES
test_latency_zero_should_error() {

    #arrange
    OS_VERSION='12.5'
    TEST_driverMaxCstate=6
    TEST_maxCstateLatency=0
    TEST_maxForceLatency=2000000000

    #act
    check_1410_cpu_idle_intel_cstates_intel

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_force_latency_limits_cstate() {

    #arrange
    OS_VERSION='12.5'
    TEST_driverMaxCstate=6
    TEST_maxCstateLatency=15  # Higher than force latency
    TEST_maxForceLatency=8    # Lower, should limit

    #act
    check_1410_cpu_idle_intel_cstates_intel

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/1410_cpu_idle_intel_cstates_intel.check
    source "${PROGRAM_DIR}/../../lib/check/1410_cpu_idle_intel_cstates_intel.check"

}

# oneTimeTearDown
setUp() {

    OS_VERSION=
    OS_NAME=
    TEST_driverMaxCstate=
    TEST_maxCstateLatency=
    TEST_maxForceLatency=

}
# tearDown

#Import Libraries
# - order is important - sourcing shunit triggers testing
# - that's also the reason, why it could not be done during oneTimeSetup

#Load and run shUnit2
#shellcheck source=../shunit2
source "${PROGRAM_DIR}/../shunit2"

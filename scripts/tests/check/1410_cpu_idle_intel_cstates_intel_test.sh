#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
readonly PROGRAM_DIR

#mock PREREQUISITE functions
LIB_FUNC_IS_INTEL() { return 0 ; }
LIB_FUNC_IS_BARE_METAL() { return 0 ; }
LIB_FUNC_IS_SLES() { return 0 ; }
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
declare -i TEST_driverMaxCstate
declare -i TEST_maxCstateLatency
declare -i TEST_maxForceLatency

test_classic_cstate_too_high_latency_too_high() {

    #arrange
    OS_VERSION='12.1'
    TEST_driverMaxCstate=2
    TEST_maxCstateLatency=2000000000
    TEST_maxForceLatency=2000000000

    #act
    check_1410_cpu_idle_intel_cstates_intel

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_classic_cstate_too_high_latency_correct() {

    #arrange
    OS_VERSION='12.1'
    TEST_driverMaxCstate=2
    TEST_maxCstateLatency=3
    TEST_maxForceLatency=2000000000

    #act
    check_1410_cpu_idle_intel_cstates_intel

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_classic_cstate_correct_latency_correct() {

    #arrange
    OS_VERSION='12.1'
    TEST_driverMaxCstate=1
    TEST_maxCstateLatency=3
    TEST_maxForceLatency=3

    #act
    check_1410_cpu_idle_intel_cstates_intel

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_classic_cstate_correct_latency_too_low() {

    #arrange
    OS_VERSION='12.1'
    TEST_driverMaxCstate=1
    TEST_maxForceLatency=0

    #act
    check_1410_cpu_idle_intel_cstates_intel

    #assert
    assertEquals "CheckWarn? RC" '1' "$?"
}

test_classic_cstate_too_low_latency_too_low() {

    #arrange
    OS_VERSION='12.1'
    TEST_driverMaxCstate=0
    TEST_maxCstateLatency=0

    #act
    check_1410_cpu_idle_intel_cstates_intel

    #assert
    assertEquals "CheckWarn? RC" '1' "$?"
}

test_latency_cstate_high_latency_too_high() {

    #arrange
    OS_VERSION='12.3'
    TEST_driverMaxCstate=6
    TEST_maxCstateLatency=2000000000
    TEST_maxForceLatency=2000000000

    #act
    check_1410_cpu_idle_intel_cstates_intel

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_latency_cstate_high_cstatelatency_correct() {

    #arrange
    OS_VERSION='12.3'
    TEST_driverMaxCstate=6
    TEST_maxCstateLatency=70
    TEST_maxForceLatency=2000000000

    #act
    check_1410_cpu_idle_intel_cstates_intel

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_latency_cstate_high_forcelatency_correct() {

    #arrange
    OS_VERSION='12.3'
    TEST_driverMaxCstate=6
    TEST_maxCstateLatency=2000000000
    TEST_maxForceLatency=70

    #act
    check_1410_cpu_idle_intel_cstates_intel

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_latency_cstate_high_cstatelatency_too_low() {

    #arrange
    OS_VERSION='12.3'
    TEST_driverMaxCstate=6
    TEST_maxCstateLatency=3
    TEST_maxForceLatency=2000000000

    #act
    check_1410_cpu_idle_intel_cstates_intel

    #assert
    assertEquals "CheckWarn? RC" '1' "$?"
}

test_latency_cstate_high_forcelatency_too_low() {

    #arrange
    OS_VERSION='12.3'
    TEST_driverMaxCstate=6
    TEST_maxCstateLatency=2000000000
    TEST_maxForceLatency=3

    #act
    check_1410_cpu_idle_intel_cstates_intel

    #assert
    assertEquals "CheckWarn? RC" '1' "$?"
}

test_latency_cstate_too_low_cstatelatency_too_low() {

    #arrange
    OS_VERSION='12.3'
    TEST_driverMaxCstate=1
    TEST_maxCstateLatency=3
    TEST_maxForceLatency=2000000000

    #act
    check_1410_cpu_idle_intel_cstates_intel

    #assert
    assertEquals "CheckWarn? RC" '1' "$?"
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

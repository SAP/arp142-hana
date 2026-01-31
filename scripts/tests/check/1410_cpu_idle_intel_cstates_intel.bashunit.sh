#!/usr/bin/env bash
#------------------------------------------------------------------
# bashunit migration notes:
# 1. PROGRAM_DIR not readonly - bashunit runs all tests in same session
# 2. Guard check skips if already loaded to avoid readonly variable conflicts
#------------------------------------------------------------------
set -u  # treat unset variables as an error

if [[ -z "${PROGRAM_DIR:-}" ]]; then
    PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
    [[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
fi

# Mock variables
OS_VERSION=''
OS_NAME=''
TEST_INTEL_IDLE='intel_idle'
TEST_driverMaxCstate=0
TEST_maxCstateLatency=0
TEST_maxForceLatency=0

# Mock functions
LIB_FUNC_IS_INTEL() { return 0 ; }
LIB_FUNC_IS_SLES() { return 0 ; }
LIB_FUNC_IS_RHEL() { return 1 ; }
LIB_FUNC_IS_ROOT() { return 0 ; }

hexdump() {
    #we fake $(hexdump -e '"%i"' /dev/cpu_dma_latency)
    printf "%s\n" "${TEST_maxForceLatency}"
}


function test_latency_cstate_high_cstatelatency_too_high33() {

    #arrange
    OS_VERSION='12.5'
    TEST_driverMaxCstate=6
    TEST_maxCstateLatency=33            #C1=3, C1E=10, C3=33, C6=133
    TEST_maxForceLatency=2000000000

    #act
    check_1410_cpu_idle_intel_cstates_intel

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for C-state latency too high"
    fi
}

function test_latency_cstate_high_forcelatency_too_high() {

    #arrange
    OS_VERSION='12.5'
    TEST_driverMaxCstate=6
    TEST_maxCstateLatency=2000000000
    TEST_maxForceLatency=70

    #act
    check_1410_cpu_idle_intel_cstates_intel

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for force latency too high"
    fi
}

function test_latency_cstate_high_cstatelatency_correct10() {

    #arrange
    OS_VERSION='12.5'
    TEST_driverMaxCstate=6
    TEST_maxCstateLatency=10
    TEST_maxForceLatency=2000000000

    #act
    check_1410_cpu_idle_intel_cstates_intel

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for C-state latency 10"
    fi
}

function test_latency_cstate_high_forcelatency_correct3() {

    #arrange
    OS_VERSION='12.5'
    TEST_driverMaxCstate=6
    TEST_maxCstateLatency=2000000000
    TEST_maxForceLatency=3

    #act
    check_1410_cpu_idle_intel_cstates_intel

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for force latency 3"
    fi
}

function test_latency_cstate_too_low_cstatelatency_too_low() {

    #arrange
    OS_VERSION='12.5'
    TEST_driverMaxCstate=1
    TEST_maxCstateLatency=3
    TEST_maxForceLatency=2000000000

    #act
    check_1410_cpu_idle_intel_cstates_intel

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for low C-state latency"
    fi
}

function test_latency_cstate_latency_exactly1_should_warn() {

    #arrange
    OS_VERSION='12.5'
    TEST_driverMaxCstate=6
    TEST_maxCstateLatency=1
    TEST_maxForceLatency=2000000000

    #act
    check_1410_cpu_idle_intel_cstates_intel

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for latency exactly 1"
    fi
}

function test_latency_cstate_latency_exactlyC1_should_warn() {

    #arrange
    OS_VERSION='12.5'
    TEST_driverMaxCstate=6
    TEST_maxCstateLatency=2
    TEST_maxForceLatency=2000000000

    #act
    check_1410_cpu_idle_intel_cstates_intel

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for latency exactly C1"
    fi
}

# OS VERSION TESTS
function test_sles15_supported() {

    #arrange
    OS_VERSION='15.4'
    TEST_driverMaxCstate=6
    TEST_maxCstateLatency=5
    TEST_maxForceLatency=2000000000

    #act
    check_1410_cpu_idle_intel_cstates_intel

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for SLES 15"
    fi
}

function test_sles_unsupported_version() {

    #arrange
    OS_VERSION='11.4'  # Unsupported SLES version
    TEST_driverMaxCstate=6
    TEST_maxCstateLatency=5
    TEST_maxForceLatency=2000000000

    #act
    check_1410_cpu_idle_intel_cstates_intel

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for unsupported SLES version"
    fi
}

# ROOT PERMISSION TESTS
function test_non_root_warning() {

    #arrange
    LIB_FUNC_IS_ROOT() { return 1 ; }  # Mock non-root
    OS_VERSION='12.5'
    TEST_driverMaxCstate=6
    TEST_maxCstateLatency=5
    TEST_maxForceLatency=2000000000

    #act
    check_1410_cpu_idle_intel_cstates_intel
    local rc=$?

    # Restore mock
    LIB_FUNC_IS_ROOT() { return 0 ; }

    #assert
    if [[ $rc -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for non-root"
    fi
}

# DRIVER MAX CSTATE WARNING
function test_driver_maxcstate_warning() {

    #arrange
    OS_VERSION='12.5'
    TEST_driverMaxCstate=0  # Restrictive max_cstate
    TEST_maxCstateLatency=1  # Low latency that triggers warning
    TEST_maxForceLatency=2000000000

    #act
    check_1410_cpu_idle_intel_cstates_intel

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for driver max_cstate 0"
    fi
}

# EDGE CASES
function test_latency_zero_should_error() {

    #arrange
    OS_VERSION='12.5'
    TEST_driverMaxCstate=6
    TEST_maxCstateLatency=0
    TEST_maxForceLatency=2000000000

    #act
    check_1410_cpu_idle_intel_cstates_intel

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for latency zero"
    fi
}

function test_force_latency_limits_cstate() {

    #arrange
    OS_VERSION='12.5'
    TEST_driverMaxCstate=6
    TEST_maxCstateLatency=15  # Higher than force latency
    TEST_maxForceLatency=8    # Lower, should limit

    #act
    check_1410_cpu_idle_intel_cstates_intel

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for force latency limiting C-state"
    fi
}


function set_up_before_script() {

    # Disable errexit - bashunit enables it but sourced files may return non-zero
    set +eE

    # Skip if already loaded (bashunit runs all tests in same session)
    [[ -n "${_1410_test_loaded:-}" ]] && return 0
    _1410_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/1410_cpu_idle_intel_cstates_intel.check
    source "${PROGRAM_DIR}/../../lib/check/1410_cpu_idle_intel_cstates_intel.check"

}

function set_up() {

    # Reset mock variables
    OS_VERSION=
    OS_NAME=
    TEST_driverMaxCstate=0
    TEST_maxCstateLatency=0
    TEST_maxForceLatency=0

}

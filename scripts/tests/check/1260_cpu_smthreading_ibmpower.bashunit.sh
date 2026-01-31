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
LIB_PLATF_CPU_SOCKETS=''
LIB_PLATF_CPU_CORESPERSOCKET=''
LIB_PLATF_CPU_THREADSPERCORE=''
LIB_PLATF_POWER_PLATFORM_BASE=''

# Mock functions
LIB_FUNC_IS_IBMPOWER() { return 0 ; }

LIB_FUNC_STRINGCONTAIN() { [[ -z "${1##*"$2"*}" ]] && [[ -z "$2" || -n "$1" ]]; }


function test_precondition_cpusockets_unknown() {

    #arrange
    LIB_PLATF_CPU_SOCKETS=

    #act
    check_1260_cpu_smthreading_ibmpower

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for unknown sockets"
    fi
}

function test_precondition_cpucores_unknown() {

    #arrange
    LIB_PLATF_CPU_SOCKETS=1
    LIB_PLATF_CPU_CORESPERSOCKET=

    #act
    check_1260_cpu_smthreading_ibmpower

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for unknown cores"
    fi
}

function test_precondition_cputhreads_unknown() {

    #arrange
    LIB_PLATF_CPU_SOCKETS=1
    LIB_PLATF_CPU_CORESPERSOCKET=1
    LIB_PLATF_CPU_THREADSPERCORE=

    #act
    check_1260_cpu_smthreading_ibmpower

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for unknown threads"
    fi
}

function test_powerX_nothandled_error() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWERX'
    LIB_PLATF_CPU_SOCKETS=8
    LIB_PLATF_CPU_CORESPERSOCKET=10
    LIB_PLATF_CPU_THREADSPERCORE=8

    #act
    check_1260_cpu_smthreading_ibmpower

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for unhandled POWER"
    fi
}

function test_power9_corestotallow_smt4_ok() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'
    LIB_PLATF_CPU_SOCKETS=8
    LIB_PLATF_CPU_CORESPERSOCKET=10
    LIB_PLATF_CPU_THREADSPERCORE=4

    #act
    check_1260_cpu_smthreading_ibmpower

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for POWER9 low cores SMT4"
    fi
}

function test_power9_corestotalhigh_smt4_ok() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'
    LIB_PLATF_CPU_SOCKETS=8
    LIB_PLATF_CPU_CORESPERSOCKET=12
    LIB_PLATF_CPU_THREADSPERCORE=4

    #act
    check_1260_cpu_smthreading_ibmpower

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for POWER9 high cores SMT4"
    fi
}

function test_power9_corestotallow_smt8_ok() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'
    LIB_PLATF_CPU_SOCKETS=8
    LIB_PLATF_CPU_CORESPERSOCKET=10
    LIB_PLATF_CPU_THREADSPERCORE=8

    #act
    check_1260_cpu_smthreading_ibmpower

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for POWER9 low cores SMT8"
    fi
}

function test_power9_corestotalhigh_smt8_ok() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'
    LIB_PLATF_CPU_SOCKETS=8
    LIB_PLATF_CPU_CORESPERSOCKET=12
    LIB_PLATF_CPU_THREADSPERCORE=8

    #act
    check_1260_cpu_smthreading_ibmpower

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for POWER9 high cores SMT8"
    fi
}

function test_power10_threadspercore_smt4_ok() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER10'
    LIB_PLATF_CPU_SOCKETS=1
    LIB_PLATF_CPU_CORESPERSOCKET=1
    LIB_PLATF_CPU_THREADSPERCORE=4

    #act
    check_1260_cpu_smthreading_ibmpower

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for POWER10 SMT4"
    fi
}

function test_power10_threadspercore_smt8_warning() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER10'
    LIB_PLATF_CPU_SOCKETS=1
    LIB_PLATF_CPU_CORESPERSOCKET=1
    LIB_PLATF_CPU_THREADSPERCORE=8

    #act
    check_1260_cpu_smthreading_ibmpower

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for POWER10 SMT8"
    fi
}

function test_power10_corestotalhigh_covered() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER10'
    LIB_PLATF_CPU_SOCKETS=8
    LIB_PLATF_CPU_CORESPERSOCKET=14
    LIB_PLATF_CPU_THREADSPERCORE=4

    #act
    check_1260_cpu_smthreading_ibmpower

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for POWER10 high cores"
    fi
}


function set_up_before_script() {

    # Disable errexit - bashunit enables it but sourced files may return non-zero
    set +eE

    # Skip if already loaded (bashunit runs all tests in same session)
    [[ -n "${_1260_test_loaded:-}" ]] && return 0
    _1260_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/1260_cpu_smthreading_ibmpower.check
    source "${PROGRAM_DIR}/../../lib/check/1260_cpu_smthreading_ibmpower.check"

}

function set_up() {

    # Reset mock variables
    LIB_PLATF_CPU_SOCKETS=
    LIB_PLATF_CPU_CORESPERSOCKET=
    LIB_PLATF_CPU_THREADSPERCORE=
    LIB_PLATF_POWER_PLATFORM_BASE=

}

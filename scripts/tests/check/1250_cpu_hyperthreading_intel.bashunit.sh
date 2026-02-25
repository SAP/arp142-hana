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
LIB_PLATF_CPU_THREADSPERCORE=''
LIB_PLATF_NAME=''
LIB_PLATF_CPU_MODELID=''
LIB_PLATF_CPU_STEPID=''

# Mock functions
LIB_FUNC_IS_INTEL() { return 0 ; }
LIB_FUNC_IS_BARE_METAL() { return 0 ; }
LIB_FUNC_IS_CLOUD_AMAZON() { return 1 ; }
LIB_FUNC_IS_CLOUD_MICROSOFT() { return 1 ; }
LIB_FUNC_IS_CLOUD_GOOGLE() { return 1 ; }
LIB_FUNC_IS_CLOUD_IBM() { return 1 ; }


function test_precondition_hyperscaler_skip() {

    #arrange
    LIB_FUNC_IS_CLOUD_AMAZON() { return 0 ; }

    #act
    check_1250_cpu_hyperthreading_intel

    #assert
    if [[ $? -ne 3 ]]; then
        bashunit::fail "Expected RC=3 (skipped) for hyperscaler cloud"
    fi
}

function test_precondition_cpusockets_unknown() {

    #arrange
    LIB_PLATF_CPU_SOCKETS=

    #act
    check_1250_cpu_hyperthreading_intel

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for unknown sockets"
    fi
}

function test_precondition_cputhreads_unknown() {

    #arrange
    LIB_PLATF_CPU_SOCKETS=4
    LIB_PLATF_CPU_THREADSPERCORE=

    #act
    check_1250_cpu_hyperthreading_intel

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for unknown threads"
    fi
}

function test_socket8_HToff_warning() {

    #arrange
    LIB_PLATF_CPU_SOCKETS=8
    LIB_PLATF_CPU_THREADSPERCORE=1

    #act
    check_1250_cpu_hyperthreading_intel

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for 8 sockets HT off"
    fi
}

function test_socket8_HTon_ok() {

    #arrange
    LIB_PLATF_CPU_SOCKETS=8
    LIB_PLATF_CPU_THREADSPERCORE=2

    #act
    check_1250_cpu_hyperthreading_intel

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for 8 sockets HT on"
    fi
}

function test_socket16_HTon_error() {

    #arrange
    LIB_PLATF_CPU_SOCKETS=16
    LIB_PLATF_CPU_THREADSPERCORE=2

    #act
    check_1250_cpu_hyperthreading_intel

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for 16 sockets HT on"
    fi
}

function test_socket16_HToff_ok() {

    #arrange
    LIB_PLATF_CPU_SOCKETS=16
    LIB_PLATF_CPU_THREADSPERCORE=1

    #act
    check_1250_cpu_hyperthreading_intel

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for 16 sockets HT off"
    fi
}

function test_SDFlex_SKL_socket12_HToff_warning() {

    #arrange
    LIB_PLATF_CPU_SOCKETS=12
    LIB_PLATF_CPU_THREADSPERCORE=1
    LIB_PLATF_NAME='Superdome Flex'
    LIB_PLATF_CPU_MODELID=85
    LIB_PLATF_CPU_STEPID=4

    #act
    check_1250_cpu_hyperthreading_intel

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for SDFlex SKL 12 sockets HT off"
    fi
}

function test_SDFlex_CLX_socket12_HTon_ok() {

    #arrange
    LIB_PLATF_CPU_SOCKETS=12
    LIB_PLATF_CPU_THREADSPERCORE=2
    LIB_PLATF_NAME='Superdome Flex'
    LIB_PLATF_CPU_MODELID=85
    LIB_PLATF_CPU_STEPID=7

    #act
    check_1250_cpu_hyperthreading_intel

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for SDFlex CLX 12 sockets HT on"
    fi
}

function test_SDFlex_SKL_socket20_HToff_ok() {

    #arrange
    LIB_PLATF_CPU_SOCKETS=20
    LIB_PLATF_CPU_THREADSPERCORE=1
    LIB_PLATF_NAME='Superdome Flex'
    LIB_PLATF_CPU_MODELID=85
    LIB_PLATF_CPU_STEPID=4

    #act
    check_1250_cpu_hyperthreading_intel

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for SDFlex SKL 20 sockets HT off"
    fi
}

function test_SDFlex_CLX_socket20_HTon_error() {

    #arrange
    LIB_PLATF_CPU_SOCKETS=20
    LIB_PLATF_CPU_THREADSPERCORE=2
    LIB_PLATF_NAME='Superdome Flex'
    LIB_PLATF_CPU_MODELID=85
    LIB_PLATF_CPU_STEPID=7

    #act
    check_1250_cpu_hyperthreading_intel

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for SDFlex CLX 20 sockets HT on"
    fi
}

function test_SDFlex_nonSKL_socket12_HTon_error() {

    #arrange
    LIB_PLATF_CPU_SOCKETS=12
    LIB_PLATF_CPU_THREADSPERCORE=2
    LIB_PLATF_NAME='Superdome Flex'
    LIB_PLATF_CPU_MODELID=85
    LIB_PLATF_CPU_STEPID=3

    #act
    check_1250_cpu_hyperthreading_intel

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for SDFlex non-SKL 12 sockets HT on"
    fi
}

function test_SDFlex_nonSKL_socket12_HToff_ok() {

    #arrange
    LIB_PLATF_CPU_SOCKETS=12
    LIB_PLATF_CPU_THREADSPERCORE=1
    LIB_PLATF_NAME='Superdome Flex'
    LIB_PLATF_CPU_MODELID=85
    LIB_PLATF_CPU_STEPID=3

    #act
    check_1250_cpu_hyperthreading_intel

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for SDFlex non-SKL 12 sockets HT off"
    fi
}


function set_up_before_script() {

    # Disable errexit - bashunit enables it but sourced files may return non-zero
    set +eE

    # Skip if already loaded (bashunit runs all tests in same session)
    [[ -n "${_1250_test_loaded:-}" ]] && return 0
    _1250_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/1250_cpu_hyperthreading_intel.check
    source "${PROGRAM_DIR}/../../lib/check/1250_cpu_hyperthreading_intel.check"

}

function set_up() {

    # Reset mock variables
    LIB_PLATF_CPU_SOCKETS=
    LIB_PLATF_CPU_THREADSPERCORE=
    LIB_PLATF_NAME=
    LIB_PLATF_CPU_MODELID=
    LIB_PLATF_CPU_STEPID=

    # Reset mock functions
    LIB_FUNC_IS_INTEL() { return 0 ; }
    LIB_FUNC_IS_BARE_METAL() { return 0 ; }
    LIB_FUNC_IS_CLOUD_AMAZON() { return 1 ; }
    LIB_FUNC_IS_CLOUD_MICROSOFT() { return 1 ; }
    LIB_FUNC_IS_CLOUD_GOOGLE() { return 1 ; }
    LIB_FUNC_IS_CLOUD_IBM() { return 1 ; }

}

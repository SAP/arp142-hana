#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
readonly PROGRAM_DIR

#mock PREREQUISITE functions
LIB_FUNC_IS_IBMPOWER() { return 0 ; }

# still to mock for tests
# LIB_PLATF_CPU_SOCKETS=
# LIB_PLATF_CPU_CORESPERSOCKET=
# LIB_PLATF_CPU_THREADSPERCORE=
# LIB_PLATF_CPU=''

test_precondition_cpusockets_unknown() {

    #arrange
    LIB_PLATF_CPU_SOCKETS=

    #act
    check_1260_cpu_smthreading_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_precondition_cpucores_unknown() {

    #arrange
    LIB_PLATF_CPU_SOCKETS=1
    LIB_PLATF_CPU_CORESPERSOCKET=

    #act
    check_1260_cpu_smthreading_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_precondition_cputhreads_unknown() {

    #arrange
    LIB_PLATF_CPU_SOCKETS=1
    LIB_PLATF_CPU_CORESPERSOCKET=1
    LIB_PLATF_CPU_THREADSPERCORE=

    #act
    check_1260_cpu_smthreading_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_power9_corestotallow_warning() {

    #arrange
    LIB_PLATF_CPU='POWER9 (architected), altivec supported'
    LIB_PLATF_CPU_SOCKETS=8
    LIB_PLATF_CPU_CORESPERSOCKET=12
    LIB_PLATF_CPU_THREADSPERCORE=4

    #act
    check_1260_cpu_smthreading_ibmpower

    #assert
    assertEquals "CheckWarn? RC" '1' "$?"
}

test_power9_corestotallow_ok() {

    #arrange
    LIB_PLATF_CPU='POWER9 (architected), altivec supported'
    LIB_PLATF_CPU_SOCKETS=8
    LIB_PLATF_CPU_CORESPERSOCKET=12
    LIB_PLATF_CPU_THREADSPERCORE=8

    #act
    check_1260_cpu_smthreading_ibmpower

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_power9_corestotalhigh_warning() {

    #arrange
    LIB_PLATF_CPU='POWER9 (architected), altivec supported'
    LIB_PLATF_CPU_SOCKETS=8
    LIB_PLATF_CPU_CORESPERSOCKET=14
    LIB_PLATF_CPU_THREADSPERCORE=8

    #act
    check_1260_cpu_smthreading_ibmpower

    #assert
    assertEquals "CheckWarn? RC" '1' "$?"
}

test_power9_corestotalhigh_ok() {

    #arrange
    LIB_PLATF_CPU='POWER9 (architected), altivec supported'
    LIB_PLATF_CPU_SOCKETS=8
    LIB_PLATF_CPU_CORESPERSOCKET=14
    LIB_PLATF_CPU_THREADSPERCORE=4

    #act
    check_1260_cpu_smthreading_ibmpower

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_power10_threadspercore_warning() {

    #arrange
    LIB_PLATF_CPU='POWER10 (architected), altivec supported'
    LIB_PLATF_CPU_SOCKETS=1
    LIB_PLATF_CPU_CORESPERSOCKET=1
    LIB_PLATF_CPU_THREADSPERCORE=8

    #act
    check_1260_cpu_smthreading_ibmpower

    #assert
    assertEquals "CheckWarn? RC" '1' "$?"
}

test_power10_threadspercore_ok() {

    #arrange
    LIB_PLATF_CPU='POWER10 (architected), altivec supported'
    LIB_PLATF_CPU_SOCKETS=1
    LIB_PLATF_CPU_CORESPERSOCKET=1
    LIB_PLATF_CPU_THREADSPERCORE=4

    #act
    check_1260_cpu_smthreading_ibmpower

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

# test_template() {

#     #arrange
#     LIB_PLATF_CPU=
#     LIB_PLATF_CPU_SOCKETS=1
#     LIB_PLATF_CPU_CORESPERSOCKET=1
#     LIB_PLATF_CPU_THREADSPERCORE=1

#     #act
#     check_1260_cpu_smthreading_ibmpower

#     #assert
#     assertEquals "CheckError? RC" '2' "$?"
#     assertEquals "CheckOk? RC" '0' "$?"
#     assertEquals "CheckWarn? RC" '1' "$?"
# }


oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/1260_cpu_smthreading_ibmpower.check
    source "${PROGRAM_DIR}/../../lib/check/1260_cpu_smthreading_ibmpower.check"

}

# oneTimeTearDown
setUp() {

    LIB_PLATF_CPU_SOCKETS=
    LIB_PLATF_CPU_CORESPERSOCKET=
    LIB_PLATF_CPU_THREADSPERCORE=
    LIB_PLATF_CPU=

}
# tearDown

#Import Libraries
# - order is important - sourcing shunit triggers testing
# - that's also the reason, why it could not be done during oneTimeSetup

#Load and run shUnit2
#shellcheck source=../shunit2
source "${PROGRAM_DIR}/../shunit2"

#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
[[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
readonly PROGRAM_DIR

#mock PREREQUISITE functions
LIB_FUNC_IS_IBMPOWER() { return 0 ; }

LIB_FUNC_STRINGCONTAIN() { [[ -z "${1##*"$2"*}" ]] && [[ -z "$2" || -n "$1" ]]; }

# still to mock for tests
# LIB_PLATF_CPU_SOCKETS=
# LIB_PLATF_CPU_CORESPERSOCKET=
# LIB_PLATF_CPU_THREADSPERCORE=
# LIB_PLATF_POWER_PLATFORM_BASE=''

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

test_powerX_nothandled_error() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWERX'
    LIB_PLATF_CPU_SOCKETS=8
    LIB_PLATF_CPU_CORESPERSOCKET=10
    LIB_PLATF_CPU_THREADSPERCORE=8

    #act
    check_1260_cpu_smthreading_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_power9_corestotallow_smt4_ok() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'
    LIB_PLATF_CPU_SOCKETS=8
    LIB_PLATF_CPU_CORESPERSOCKET=10
    LIB_PLATF_CPU_THREADSPERCORE=4

    #act
    check_1260_cpu_smthreading_ibmpower

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_power9_corestotalhigh_smt4_ok() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'
    LIB_PLATF_CPU_SOCKETS=8
    LIB_PLATF_CPU_CORESPERSOCKET=12
    LIB_PLATF_CPU_THREADSPERCORE=4

    #act
    check_1260_cpu_smthreading_ibmpower

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_power9_corestotallow_smt8_ok() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'
    LIB_PLATF_CPU_SOCKETS=8
    LIB_PLATF_CPU_CORESPERSOCKET=10
    LIB_PLATF_CPU_THREADSPERCORE=8

    #act
    check_1260_cpu_smthreading_ibmpower

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_power9_corestotalhigh_smt8_ok() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'
    LIB_PLATF_CPU_SOCKETS=8
    LIB_PLATF_CPU_CORESPERSOCKET=12
    LIB_PLATF_CPU_THREADSPERCORE=8

    #act
    check_1260_cpu_smthreading_ibmpower

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_power10_threadspercore_smt4_ok() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER10'
    LIB_PLATF_CPU_SOCKETS=1
    LIB_PLATF_CPU_CORESPERSOCKET=1
    LIB_PLATF_CPU_THREADSPERCORE=4

    #act
    check_1260_cpu_smthreading_ibmpower

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_power10_threadspercore_warning() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER10'
    LIB_PLATF_CPU_SOCKETS=1
    LIB_PLATF_CPU_CORESPERSOCKET=1
    LIB_PLATF_CPU_THREADSPERCORE=8

    #act
    check_1260_cpu_smthreading_ibmpower

    #assert
    assertEquals "CheckWarn? RC" '1' "$?"
}


# test_template() {

#     #arrange
#     LIB_PLATF_POWER_PLATFORM_BASE=
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
    LIB_PLATF_POWER_PLATFORM_BASE=

}
# tearDown

#Import Libraries
# - order is important - sourcing shunit triggers testing
# - that's also the reason, why it could not be done during oneTimeSetup

#Load and run shUnit2
#shellcheck source=../shunit2
source "${PROGRAM_DIR}/../shunit2"

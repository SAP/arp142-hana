#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
readonly PROGRAM_DIR

#mock PREREQUISITE functions
LIB_FUNC_IS_INTEL() { return 0 ; }
LIB_FUNC_IS_BARE_METAL() { return 0 ; }

# still to mock for tests
# LIB_PLATF_CPU_SOCKETS=
# LIB_PLATF_CPU_THREADSPERCORE=
# LIB_PLATF_NAME=
# LIB_PLATF_CPU_MODELID=
# LIB_PLATF_CPU_STEPID=

test_precondition_cpusockets_unknown() {

    #arrange
    LIB_PLATF_CPU_SOCKETS=

    #act
    check_1250_cpu_hyperthreading_intel

    #assert
    assertEquals "CheckWarn? RC" '1' "$?"
}


test_precondition_cputhreads_unknown() {

    #arrange
    LIB_PLATF_CPU_SOCKETS=4
    LIB_PLATF_CPU_THREADSPERCORE=

    #act
    check_1250_cpu_hyperthreading_intel

    #assert
    assertEquals "CheckWarn? RC" '1' "$?"
}

test_socket8_HToff_warning() {

    #arrange
    LIB_PLATF_CPU_SOCKETS=8
    LIB_PLATF_CPU_THREADSPERCORE=1

    #act
    check_1250_cpu_hyperthreading_intel

    #assert
    assertEquals "CheckWarn? RC" '1' "$?"
}

test_socket8_HTon_ok() {

    #arrange
    LIB_PLATF_CPU_SOCKETS=8
    LIB_PLATF_CPU_THREADSPERCORE=2

    #act
    check_1250_cpu_hyperthreading_intel

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_socket16_HTon_error() {

    #arrange
    LIB_PLATF_CPU_SOCKETS=16
    LIB_PLATF_CPU_THREADSPERCORE=2

    #act
    check_1250_cpu_hyperthreading_intel

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_socket16_HToff_ok() {

    #arrange
    LIB_PLATF_CPU_SOCKETS=16
    LIB_PLATF_CPU_THREADSPERCORE=1

    #act
    check_1250_cpu_hyperthreading_intel

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_SDFlex_SKL_socket12_HToff_warning() {

    #arrange
    LIB_PLATF_CPU_SOCKETS=12
    LIB_PLATF_CPU_THREADSPERCORE=1
    LIB_PLATF_NAME='Superdome Flex'
    LIB_PLATF_CPU_MODELID=85
    LIB_PLATF_CPU_STEPID=4

    #act
    check_1250_cpu_hyperthreading_intel

    #assert
    assertEquals "CheckWarn? RC" '1' "$?"
}

test_SDFlex_CLX_socket12_HTon_ok() {

    #arrange
    LIB_PLATF_CPU_SOCKETS=12
    LIB_PLATF_CPU_THREADSPERCORE=2
    LIB_PLATF_NAME='Superdome Flex'
    LIB_PLATF_CPU_MODELID=85
    LIB_PLATF_CPU_STEPID=7

    #act
    check_1250_cpu_hyperthreading_intel

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_SDFlex_SKL_socket20_HToff_ok() {

    #arrange
    LIB_PLATF_CPU_SOCKETS=20
    LIB_PLATF_CPU_THREADSPERCORE=1
    LIB_PLATF_NAME='Superdome Flex'
    LIB_PLATF_CPU_MODELID=85
    LIB_PLATF_CPU_STEPID=4

    #act
    check_1250_cpu_hyperthreading_intel

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_SDFlex_CLX_socket20_HTon_error() {

    #arrange
    LIB_PLATF_CPU_SOCKETS=20
    LIB_PLATF_CPU_THREADSPERCORE=2
    LIB_PLATF_NAME='Superdome Flex'
    LIB_PLATF_CPU_MODELID=85
    LIB_PLATF_CPU_STEPID=7

    #act
    check_1250_cpu_hyperthreading_intel

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_SDFlex_nonSKL_socket12_HTon_error() {

    #arrange
    LIB_PLATF_CPU_SOCKETS=12
    LIB_PLATF_CPU_THREADSPERCORE=2
    LIB_PLATF_NAME='Superdome Flex'
    LIB_PLATF_CPU_MODELID=85
    LIB_PLATF_CPU_STEPID=3

    #act
    check_1250_cpu_hyperthreading_intel

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_SDFlex_nonSKL_socket12_HToff_ok() {

    #arrange
    LIB_PLATF_CPU_SOCKETS=12
    LIB_PLATF_CPU_THREADSPERCORE=1
    LIB_PLATF_NAME='Superdome Flex'
    LIB_PLATF_CPU_MODELID=85
    LIB_PLATF_CPU_STEPID=3

    #act
    check_1250_cpu_hyperthreading_intel

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

# test_template() {

#     #arrange
#     LIB_PLATF_CPU_SOCKETS=4
#     LIB_PLATF_CPU_THREADSPERCORE=1
#     LIB_PLATF_NAME=
#     LIB_PLATF_CPU_MODELID=
#     LIB_PLATF_CPU_STEPID=

#     #act
#     check_1250_cpu_hyperthreading_intel

#     #assert
#     assertEquals "CheckError? RC" '2' "$?"
#     assertEquals "CheckOk? RC" '0' "$?"
#     assertEquals "CheckWarn? RC" '1' "$?"
# }


oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/1250_cpu_hyperthreading_intel.check
    source "${PROGRAM_DIR}/../../lib/check/1250_cpu_hyperthreading_intel.check"

}

# oneTimeTearDown
setUp() {

    LIB_PLATF_CPU_SOCKETS=
    LIB_PLATF_CPU_THREADSPERCORE=
    LIB_PLATF_NAME=
    LIB_PLATF_CPU_MODELID=
    LIB_PLATF_CPU_STEPID=

}
# tearDown

#Import Libraries
# - order is important - sourcing shunit triggers testing
# - that's also the reason, why it could not be done during oneTimeSetup

#Load and run shUnit2
#shellcheck source=../shunit2
source "${PROGRAM_DIR}/../shunit2"

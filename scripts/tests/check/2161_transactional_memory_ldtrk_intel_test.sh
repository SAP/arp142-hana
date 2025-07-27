#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
readonly PROGRAM_DIR

#mock PREREQUISITE functions
LIB_FUNC_IS_INTEL() { return 0 ; }

# still to mock for tests
# OS_VERSION
cpuflags=''

grep() {

     case "$*" in
        *'cpuinfo')     # fake grep * /proc/cpuinfo
                        printf "%s\n" "${cpuflags[@]}" ;;

        *)              command grep "$@" ;; # shunit2 requires grep
    esac
}

test_tsxldtrk_notsupported() {

    #arrange
    LIB_PLATF_CPU_MODELID=142

    #act
    check_2161_transactional_memory_ldtrk_intel

    #assert
    assertEquals "CheckSkipped? RC" '3' "$?"
}

test_tsx_and_tsxldtrk_available() {

    #arrange
    LIB_PLATF_CPU_MODELID=143
    cpuflags=()
    cpuflags+=('rtm')
    cpuflags+=('tsxldtrk')

    #act
    check_2161_transactional_memory_ldtrk_intel

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}


test_tsx_available_but_ldtrk_not() {

    #arrange
    LIB_PLATF_CPU_MODELID=143
    cpuflags=()
    cpuflags+=('rtm')

    #act
    check_2161_transactional_memory_ldtrk_intel

    #assert
    assertEquals "CheckWarn? RC" '1' "$?"
}

test_tsx_not_available_but_ldtrk_is() {

    #arrange
    LIB_PLATF_CPU_MODELID=143
    cpuflags=()
    cpuflags+=('tsxldtrk')

    #act
    check_2161_transactional_memory_ldtrk_intel

    #assert
    assertEquals "CheckWarn? RC" '1' "$?"
}

oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/2161_transactional_memory_ldtrk_intel.check
    source "${PROGRAM_DIR}/../../lib/check/2161_transactional_memory_ldtrk_intel.check"

}

# oneTimeTearDown
setUp() {

    LIB_PLATF_CPU_MODELID=

}
# tearDown

#Import Libraries
# - order is important - sourcing shunit triggers testing
# - that's also the reason, why it could not be done during oneTimeSetup

#Load and run shUnit2
#shellcheck source=../shunit2
source "${PROGRAM_DIR}/../shunit2"

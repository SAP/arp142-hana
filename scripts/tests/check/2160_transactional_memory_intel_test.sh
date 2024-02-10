#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
readonly PROGRAM_DIR

#mock PREREQUISITE functions
LIB_FUNC_IS_INTEL() { return 0 ; }
LIB_FUNC_IS_RHEL() { return 0 ; }
LIB_FUNC_IS_VIRT_VMWARE() { { return "${_vmware_rc}" ; } }

# still to mock for tests
# OS_VERSION
declare -i _grep_cpuinfo_rc
declare -i _grep_cmdline_rc

grep() {

     case "$*" in
        *'cpuinfo')     return "${_grep_cpuinfo_rc}" ;;

        *'cmdline')     return "${_grep_cmdline_rc}" ;;

        *)              command grep "$@" ;; # shunit2 requires grep
    esac
}

OS_VERSION=''

test_tsx_available() {

    #arrange
    OS_VERSION='7.*'
    _grep_cpuinfo_rc=0

    #act
    check_2160_transactional_memory_intel

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_tsx_available_vmware() {

    #arrange
    OS_VERSION='7.*'
    _grep_cpuinfo_rc=0
    _vmware_rc=0

    #act
    check_2160_transactional_memory_intel

    #assert
    assertEquals "CheckWarn? RC" '1' "$?"
}

test_tsx_not_available_tsxon_not_required() {

    #arrange
    OS_VERSION='7.*'
    _grep_cpuinfo_rc=1

    #act
    check_2160_transactional_memory_intel

    #assert
    assertEquals "CheckWarn? RC" '1' "$?"
}

test_tsx_not_available_tsxon_required_and_specified() {

    #arrange
    OS_VERSION='8.4'
    _grep_cpuinfo_rc=1
    _grep_cmdline_rc=0

    #act
    check_2160_transactional_memory_intel

    #assert
    assertEquals "CheckWarn? RC" '1' "$?"
}

test_tsx_not_available_tsxon_required_not_specified() {

    #arrange
    OS_VERSION='8.4'
    _grep_cpuinfo_rc=1
    _grep_cmdline_rc=1

    #act
    check_2160_transactional_memory_intel

    #assert
    assertEquals "CheckWarn? RC" '1' "$?"
}

oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/2160_transactional_memory_intel.check
    source "${PROGRAM_DIR}/../../lib/check/2160_transactional_memory_intel.check"

}

# oneTimeTearDown
setUp() {

    OS_VERSION=
    _grep_cpuinfo_rc=0
    _grep_cmdline_rc=0
    _vmware_rc=1

}
# tearDown

#Import Libraries
# - order is important - sourcing shunit triggers testing
# - that's also the reason, why it could not be done during oneTimeSetup

#Load and run shUnit2
#shellcheck source=../shunit2
source "${PROGRAM_DIR}/../shunit2"

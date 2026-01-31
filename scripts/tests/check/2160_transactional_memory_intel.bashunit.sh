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
declare -i _grep_cpuinfo_rc=0
_grep_cmdline=''
_vmware_rc=1

# Mock functions
LIB_FUNC_IS_INTEL() { return 0 ; }
LIB_FUNC_IS_RHEL() { return 0 ; }
LIB_FUNC_IS_VIRT_VMWARE() { return "${_vmware_rc}" ; }
LIB_FUNC_IS_CLOUD_AMAZON() { return 1 ; }

grep() {

    case "$*" in
        *'cpuinfo')     # fake grep -qs 'flags.*tsx*' /proc/cpuinfo
                        return "${_grep_cpuinfo_rc}" ;;

        *'cmdline')     #fake $(grep -osE 'tsx=(on|auto)' /proc/cmdline)
                        printf "%s\n" "${_grep_cmdline}" ;;

        *)              command grep "$@" ;; # bashunit requires grep
    esac
}


function test_tsx_available() {

    #arrange
    OS_VERSION='7.*'
    _grep_cpuinfo_rc=0

    #act
    check_2160_transactional_memory_intel

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for TSX available"
    fi
}

function test_tsx_available_vmware() {

    #arrange
    OS_VERSION='7.*'
    _grep_cpuinfo_rc=0
    _vmware_rc=0

    #act
    check_2160_transactional_memory_intel

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for TSX available on VMware"
    fi
}

function test_tsx_not_available_tsxon_not_required() {

    #arrange
    OS_VERSION='7.*'
    _grep_cpuinfo_rc=1

    #act
    check_2160_transactional_memory_intel

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for TSX not available, tsx=on not required"
    fi
}

function test_tsx_not_available_tsxon_required_and_specified() {

    #arrange
    OS_VERSION='8.4'
    _grep_cpuinfo_rc=1
    _grep_cmdline='tsx=on'

    #act
    check_2160_transactional_memory_intel

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for TSX not available, tsx=on required and specified"
    fi
}

function test_tsx_not_available_tsxon_required_not_specified() {

    #arrange
    OS_VERSION='8.4'
    _grep_cpuinfo_rc=1
    _grep_cmdline=''

    #act
    check_2160_transactional_memory_intel

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for TSX not available, tsx=on required not specified"
    fi
}


function set_up_before_script() {

    # Disable errexit - bashunit enables it but sourced files may return non-zero
    set +eE

    # Skip if already loaded (bashunit runs all tests in same session)
    [[ -n "${_2160_test_loaded:-}" ]] && return 0
    _2160_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/2160_transactional_memory_intel.check
    source "${PROGRAM_DIR}/../../lib/check/2160_transactional_memory_intel.check"

}

function set_up() {

    OS_VERSION=''
    _grep_cpuinfo_rc=0
    _grep_cmdline=''
    _vmware_rc=1

}

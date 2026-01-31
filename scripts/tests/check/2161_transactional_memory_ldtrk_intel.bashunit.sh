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
LIB_PLATF_CPU_MODELID=0
cpuflags=()

# Mock functions
LIB_FUNC_IS_INTEL() { return 0 ; }

grep() {

    case "$*" in
        *'cpuinfo')     # fake grep * /proc/cpuinfo
                        printf "%s\n" "${cpuflags[@]}" ;;

        *)              command grep "$@" ;; # bashunit requires grep
    esac
}


function test_tsxldtrk_notsupported() {

    #arrange
    LIB_PLATF_CPU_MODELID=142

    #act
    check_2161_transactional_memory_ldtrk_intel

    #assert
    if [[ $? -ne 3 ]]; then
        bashunit::fail "Expected RC=3 (skipped) for tsxldtrk not supported"
    fi
}

function test_tsx_and_tsxldtrk_available() {

    #arrange
    LIB_PLATF_CPU_MODELID=143
    cpuflags=()
    cpuflags+=('rtm')
    cpuflags+=('tsxldtrk')

    #act
    check_2161_transactional_memory_ldtrk_intel

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for TSX and tsxldtrk available"
    fi
}

function test_tsx_available_but_ldtrk_not() {

    #arrange
    LIB_PLATF_CPU_MODELID=143
    cpuflags=()
    cpuflags+=('rtm')

    #act
    check_2161_transactional_memory_ldtrk_intel

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for TSX available but ldtrk not"
    fi
}

function test_tsx_not_available_but_ldtrk_is() {

    #arrange
    LIB_PLATF_CPU_MODELID=143
    cpuflags=()
    cpuflags+=('tsxldtrk')

    #act
    check_2161_transactional_memory_ldtrk_intel

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for TSX not available but ldtrk is"
    fi
}


function set_up_before_script() {

    # Disable errexit - bashunit enables it but sourced files may return non-zero
    set +eE

    # Skip if already loaded (bashunit runs all tests in same session)
    [[ -n "${_2161_test_loaded:-}" ]] && return 0
    _2161_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/2161_transactional_memory_ldtrk_intel.check
    source "${PROGRAM_DIR}/../../lib/check/2161_transactional_memory_ldtrk_intel.check"

}

function set_up() {

    LIB_PLATF_CPU_MODELID=0
    cpuflags=()

}

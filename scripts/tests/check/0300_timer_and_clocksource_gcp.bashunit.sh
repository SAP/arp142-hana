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
TEST_CURRENT_CLOCKSOURCE=''
TEST_AVAILABLE_CLOCKSOURCE=''

# Mock functions
LIB_FUNC_IS_INTEL() { return 0 ; }
LIB_FUNC_IS_VIRT_MICROSOFT() { return 1 ; }
LIB_FUNC_IS_CLOUD_GOOGLE() { return 0 ; }
LIB_FUNC_IS_CLOUD_AMAZON() { return 1 ; }
LIB_FUNC_IS_VIRT_KVM() { return 0 ; }

grep() {
    #we fake <(grep -e '^flags' -m1 /proc/cpuinfo |
            #  grep -E -e 'constant_tsc|nonstop_tsc|rdtscp' -o)
    case "$*" in
        '-e ^flags'* )  : ;;

        '-E -e constant_tsc'* )
                        : ;;

        *)              command grep "$@" ;; # bashunit requires grep
    esac
}


function test_correct_clocksource() {

    #arrange
    TEST_CURRENT_CLOCKSOURCE='kvm-clock'
    TEST_AVAILABLE_CLOCKSOURCE='tsc kvm-clock'

    #act
    check_0300_timer_and_clocksource_intel

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for correct clocksource"
    fi
}

function test_all_cpu_flags_available_and_wrong_clocksource() {

    #arrange
    TEST_CURRENT_CLOCKSOURCE='xen'
    TEST_AVAILABLE_CLOCKSOURCE='kvm-clock tsc'

    #act
    check_0300_timer_and_clocksource_intel

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for wrong clocksource"
    fi
}


function set_up_before_script() {

    # Disable errexit - bashunit enables it but sourced files may return non-zero
    set +eE

    # Skip if already loaded (bashunit runs all tests in same session)
    [[ -n "${_0300_gcp_test_loaded:-}" ]] && return 0
    _0300_gcp_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/0300_timer_and_clocksource_intel.check
    source "${PROGRAM_DIR}/../../lib/check/0300_timer_and_clocksource_intel.check"

}

function set_up() {

    # Reset mock variables
    TEST_CURRENT_CLOCKSOURCE=''
    TEST_AVAILABLE_CLOCKSOURCE=''

}

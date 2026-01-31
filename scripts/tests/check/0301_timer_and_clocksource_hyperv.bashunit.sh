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

# Mock functions
LIB_FUNC_IS_VIRT_MICROSOFT() { return 0 ; }


function test_reco_clock() {

    #arrange
    TEST_CURRENT_CLOCKSOURCE='hyperv_clocksource_tsc_page'

    #act
    check_0301_timer_and_clocksource_hyperv

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for recommended clocksource"
    fi
}

function test_wrong_clocksource() {

    #arrange
    TEST_CURRENT_CLOCKSOURCE='acpi_pm'

    #act
    check_0301_timer_and_clocksource_hyperv

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for wrong clocksource"
    fi
}


function set_up_before_script() {

    # Disable errexit - bashunit enables it but sourced files may return non-zero
    set +eE

    # Skip if already loaded (bashunit runs all tests in same session)
    [[ -n "${_0301_test_loaded:-}" ]] && return 0
    _0301_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/0301_timer_and_clocksource_hyperv.check
    source "${PROGRAM_DIR}/../../lib/check/0301_timer_and_clocksource_hyperv.check"

}

function set_up() {

    # Reset mock variables
    TEST_CURRENT_CLOCKSOURCE=''

}

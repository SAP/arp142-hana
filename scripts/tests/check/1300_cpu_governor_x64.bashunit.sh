#!/usr/bin/env bash
# shellcheck disable=SC2329
#------------------------------------------------------------------
# bashunit tests for 1300_cpu_governor_x64 check
# Tests Intel CPU frequency scaling governor configuration
#------------------------------------------------------------------
set -u

if [[ -z "${PROGRAM_DIR:-}" ]]; then
    PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
    [[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
fi

# Mock variables - array of CPU governors found on system
TEST_govs=()

# Mock functions
LIB_FUNC_IS_INTEL() { return 0; }
LIB_FUNC_IS_BARE_METAL() { return 0; }

#------------------------------------------------------------------
# Helper function: Assert check was processed (RC != 99)
#------------------------------------------------------------------
assert_check_processed() {
    local rc=$1
    local context="${2:-}"
    assert_not_equals 99 "${rc}" "Check must be processed${context:+ in }${context}"
}

#------------------------------------------------------------------
# Test precondition: Non-Intel systems should skip
#------------------------------------------------------------------
function test_precondition_non_intel_skipped() {

    #arrange
    LIB_FUNC_IS_INTEL() { return 1; }
    TEST_govs=('performance')

    #act
    check_1300_cpu_governor_x64
    local rc=$?

    #assert
    assert_exit_code 3 "Expected RC=3 (skipped) on non-Intel systems" "${rc}"
    assert_true true
}

#------------------------------------------------------------------
# Test precondition: Virtualized systems should skip
#------------------------------------------------------------------
function test_precondition_virtualized_skipped() {

    #arrange

    LIB_FUNC_IS_INTEL() { return 0; }
    LIB_FUNC_IS_BARE_METAL() { return 1; }
    TEST_govs=('performance')

    #act
    check_1300_cpu_governor_x64
    local rc=$?

    #assert
    assert_exit_code 3 "Expected RC=3 (skipped) on virtualized systems" "${rc}"
    assert_true true
}

#------------------------------------------------------------------
# Test case: No governors found - should warn
#------------------------------------------------------------------
function test_no_governors_found_warns() {

    #arrange
    LIB_FUNC_IS_INTEL() { return 0; }
    LIB_FUNC_IS_BARE_METAL() { return 0; }
    TEST_govs=()

    #act
    check_1300_cpu_governor_x64
    local rc=$?

    #assert
    assert_check_processed ${rc} "no governors"
    assert_exit_code 1 "Expected RC=1 (warning) when no governors found" "${rc}"
    assert_true true
}

#------------------------------------------------------------------
# Test case: Single governor set to "performance" - should pass
#------------------------------------------------------------------
function test_single_governor_performance_ok() {

    #arrange
    LIB_FUNC_IS_INTEL() { return 0; }
    LIB_FUNC_IS_BARE_METAL() { return 0; }
    TEST_govs=('performance')

    #act
    check_1300_cpu_governor_x64
    local rc=$?

    #assert
    assert_check_processed ${rc} "single performance governor"
    assert_exit_code 0 "Expected RC=0 (ok) when governor is performance" "${rc}"
    assert_true true
}

#------------------------------------------------------------------
# Test case: Single governor set to "powersave" - should warn
#------------------------------------------------------------------
function test_single_governor_powersave_warns() {

    #arrange
    LIB_FUNC_IS_INTEL() { return 0; }
    LIB_FUNC_IS_BARE_METAL() { return 0; }
    TEST_govs=('powersave')

    #act
    check_1300_cpu_governor_x64
    local rc=$?

    #assert
    assert_check_processed ${rc} "single powersave governor"
    assert_exit_code 1 "Expected RC=1 (warning) when governor is powersave" "${rc}"
    assert_true true
}

#------------------------------------------------------------------
# Test case: Single governor set to "schedutil" - should warn
#------------------------------------------------------------------
function test_single_governor_schedutil_warns() {

    #arrange
    LIB_FUNC_IS_INTEL() { return 0; }
    LIB_FUNC_IS_BARE_METAL() { return 0; }
    TEST_govs=('schedutil')

    #act
    check_1300_cpu_governor_x64
    local rc=$?

    #assert
    assert_check_processed ${rc} "single schedutil governor"
    assert_exit_code 1 "Expected RC=1 (warning) when governor is schedutil" "${rc}"
    assert_true true
}

#------------------------------------------------------------------
# Test case: Multiple governors detected - should warn
#------------------------------------------------------------------
function test_multiple_governors_warns() {

    #arrange
    LIB_FUNC_IS_INTEL() { return 0; }
    LIB_FUNC_IS_BARE_METAL() { return 0; }
    TEST_govs=('performance' 'powersave')

    #act
    check_1300_cpu_governor_x64
    local rc=$?

    #assert
    assert_check_processed ${rc} "multiple governors"
    assert_exit_code 1 "Expected RC=1 (warning) when multiple governors detected" "${rc}"
    assert_true true
}

#------------------------------------------------------------------
# Setup function: Load check and stubs before all tests
#------------------------------------------------------------------
function set_up_before_script() {

    set +eE

    # Guard to prevent re-loading in same bashunit session
    [[ -n "${_1300_test_loaded:-}" ]] && return 0
    _1300_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/1300_cpu_governor_x64.check
    source "${PROGRAM_DIR}/../../lib/check/1300_cpu_governor_x64.check"
}

#------------------------------------------------------------------
# Setup function: Reset state before each test
#------------------------------------------------------------------
function set_up() {

    TEST_govs=()

    LIB_FUNC_IS_INTEL() { return 0; }
    LIB_FUNC_IS_BARE_METAL() { return 0; }
}

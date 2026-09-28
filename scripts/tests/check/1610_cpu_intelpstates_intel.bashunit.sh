#!/usr/bin/env bash
# shellcheck disable=SC2329
set -u

if [[ -z "${PROGRAM_DIR:-}" ]]; then
    PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
    [[ "${PROGRAM_DIR}" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
fi

TEST_intel_pstate_status='active'
TEST_intel_pstate_no_turbo=0
TEST_intel_pstate_max_perf_pct=100

LIB_FUNC_IS_INTEL() { return 0; }
LIB_FUNC_IS_BARE_METAL() { return 0; }

assert_check_processed() {
    local rc=$1
    local context="${2:-}"
    assert_not_equals 99 "${rc}" "Check must be processed${context:+ in }${context}"
}

function test_non_intel_skipped() {
    LIB_FUNC_IS_INTEL() { return 1; }

    check_1610_cpu_intelpstates_intel
    local rc=$?

    assert_check_processed "${rc}" "non-Intel environment"
    assert_exit_code 3 'Expected RC=3 (skipped) on non-Intel systems' "${rc}"
}

function test_virtualized_skipped() {
    LIB_FUNC_IS_BARE_METAL() { return 1; }

    check_1610_cpu_intelpstates_intel
    local rc=$?

    assert_check_processed "${rc}" "virtualized environment"
    assert_exit_code 3 'Expected RC=3 (skipped) on virtualized systems' "${rc}"
}

function test_inactive_driver_skipped() {
    TEST_intel_pstate_status='passive'

    check_1610_cpu_intelpstates_intel
    local rc=$?

    assert_check_processed "${rc}" "inactive intel_pstate driver"
    assert_exit_code 3 'Expected RC=3 (skipped) when intel_pstate is not active' "${rc}"
}

function test_recommended_parameters_ok() {
    check_1610_cpu_intelpstates_intel
    local rc=$?

    assert_check_processed "${rc}" "recommended intel_pstate parameters"
    assert_exit_code 0 'Expected RC=0 (ok) for recommended intel_pstate parameters' "${rc}"
}

function test_no_turbo_enabled_warns() {
    TEST_intel_pstate_no_turbo=1

    check_1610_cpu_intelpstates_intel
    local rc=$?

    assert_check_processed "${rc}" "no_turbo enabled"
    assert_exit_code 1 'Expected RC=1 (warning) when no_turbo is enabled' "${rc}"
}

function test_reduced_maximum_performance_warns() {
    TEST_intel_pstate_max_perf_pct=90

    check_1610_cpu_intelpstates_intel
    local rc=$?

    assert_check_processed "${rc}" "reduced maximum performance"
    assert_exit_code 1 'Expected RC=1 (warning) when max_perf_pct is below 100' "${rc}"
}

function set_up_before_script() {
    set +eE

    [[ -n "${_1610_test_loaded:-}" ]] && return 0
    _1610_test_loaded=true

    source "${PROGRAM_DIR}/../saphana-logger-stubs"
    source "${PROGRAM_DIR}/../../lib/check/1610_cpu_intelpstates_intel.check"
}

function set_up() {
    TEST_intel_pstate_status='active'
    TEST_intel_pstate_no_turbo=0
    TEST_intel_pstate_max_perf_pct=100

    LIB_FUNC_IS_INTEL() { return 0; }
    LIB_FUNC_IS_BARE_METAL() { return 0; }
}
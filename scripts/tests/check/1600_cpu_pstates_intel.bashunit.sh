#!/usr/bin/env bash
# shellcheck disable=SC2329
set -u

if [[ -z "${PROGRAM_DIR:-}" ]]; then
    PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
    [[ "${PROGRAM_DIR}" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
fi

TEST_scaling_driver=''
TEST_hwp_enabled=false

LIB_FUNC_IS_INTEL() { return 0; }
LIB_FUNC_IS_BARE_METAL() { return 0; }

assert_check_processed() {
    local rc=$1
    local context="${2:-}"
    assert_not_equals 99 "${rc}" "Check must be processed${context:+ in }${context}"
}

function test_non_intel_skipped() {
    LIB_FUNC_IS_INTEL() { return 1; }

    check_1600_cpu_pstates_intel
    local rc=$?

    assert_check_processed "${rc}" "non-Intel environment"
    assert_exit_code 3 'Expected RC=3 (skipped) on non-Intel systems' "${rc}"
}

function test_virtualized_skipped() {
    LIB_FUNC_IS_BARE_METAL() { return 1; }

    check_1600_cpu_pstates_intel
    local rc=$?

    assert_check_processed "${rc}" "virtualized environment"
    assert_exit_code 3 'Expected RC=3 (skipped) on virtualized systems' "${rc}"
}

function test_active_intel_pstate_without_hwp_ok() {
    TEST_scaling_driver='intel_pstate'
    TEST_hwp_enabled=false

    check_1600_cpu_pstates_intel
    local rc=$?

    assert_check_processed "${rc}" "active intel_pstate without HWP"
    assert_exit_code 0 'Expected RC=0 (ok) for active intel_pstate' "${rc}"
}

function test_passive_intel_pstate_warns() {
    TEST_scaling_driver='intel_cpufreq'

    check_1600_cpu_pstates_intel
    local rc=$?

    assert_check_processed "${rc}" "passive intel_pstate"
    assert_exit_code 1 'Expected RC=1 (warning) for passive intel_pstate' "${rc}"
}

function test_missing_driver_warns() {
    TEST_scaling_driver=''

    check_1600_cpu_pstates_intel
    local rc=$?

    assert_check_processed "${rc}" "missing driver"
    assert_exit_code 1 'Expected RC=1 (warning) when no scaling driver is loaded' "${rc}"
}

function test_other_driver_warns() {
    TEST_scaling_driver='acpi-cpufreq'

    check_1600_cpu_pstates_intel
    local rc=$?

    assert_check_processed "${rc}" "other driver"
    assert_exit_code 1 'Expected RC=1 (warning) for a non-Intel scaling driver' "${rc}"
}

function set_up_before_script() {
    set +eE

    [[ -n "${_1600_test_loaded:-}" ]] && return 0
    _1600_test_loaded=true

    source "${PROGRAM_DIR}/../saphana-logger-stubs"
    source "${PROGRAM_DIR}/../../lib/check/1600_cpu_pstates_intel.check"
}

function set_up() {
    TEST_scaling_driver=''
    TEST_hwp_enabled=false

    LIB_FUNC_IS_INTEL() { return 0; }
    LIB_FUNC_IS_BARE_METAL() { return 0; }
}
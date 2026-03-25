#!/usr/bin/env bash
#------------------------------------------------------------------
# bashunit migration notes:
# 1. PROGRAM_DIR not readonly - bashunit runs all tests in same session
# 2. Guard check skips if already loaded to avoid readonly variable conflicts
#------------------------------------------------------------------
set -u      # treat unset variables as an error

if [[ -z "${PROGRAM_DIR:-}" ]]; then
    PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
    [[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
fi

function test_os_override_sles_valid() {
    # Test valid SLES override

    export SAPHANA_CHECK_OS_OVERRIDE='SLES:15.5'

    # Test in subshell to avoid affecting global state
    local result
    result=$(
        unset LIB_LINUX_RELEASE
        source "${PROGRAM_DIR}/../bin/lib_linux_release" 2>&1 >/dev/null
        echo "${OS_NAME}|${OS_VERSION}"
    )

    local os_name="${result%%|*}"
    local os_version="${result##*|}"

    assert_equals 'Linux SLES' "${os_name}"
    assert_equals '15.5' "${os_version}"

    unset SAPHANA_CHECK_OS_OVERRIDE
}

function test_os_override_rhel_valid() {
    # Test valid RHEL override

    export SAPHANA_CHECK_OS_OVERRIDE='RHEL:9.2'

    # Test in subshell to avoid affecting global state
    local result
    result=$(
        unset LIB_LINUX_RELEASE
        source "${PROGRAM_DIR}/../bin/lib_linux_release" 2>&1 >/dev/null
        echo "${OS_NAME}|${OS_VERSION}"
    )

    local os_name="${result%%|*}"
    local os_version="${result##*|}"

    assert_equals 'Linux RHEL' "${os_name}"
    assert_equals '9.2' "${os_version}"

    unset SAPHANA_CHECK_OS_OVERRIDE
}

function test_os_override_ols_valid() {
    # Test valid Oracle Linux override

    export SAPHANA_CHECK_OS_OVERRIDE='OLS:8.6'

    # Test in subshell to avoid affecting global state
    local result
    result=$(
        unset LIB_LINUX_RELEASE
        source "${PROGRAM_DIR}/../bin/lib_linux_release" 2>&1 >/dev/null
        echo "${OS_NAME}|${OS_VERSION}"
    )

    local os_name="${result%%|*}"
    local os_version="${result##*|}"

    assert_equals 'Linux OLS' "${os_name}"
    assert_equals '8.6' "${os_version}"

    unset SAPHANA_CHECK_OS_OVERRIDE
}

function test_os_override_invalid_format_missing_colon() {
    # Test invalid format without colon

    export SAPHANA_CHECK_OS_OVERRIDE='SLES15.5'

    # This should exit with error code 2, so we need to test in a subshell
    local _rc=0
    (
        unset LIB_LINUX_RELEASE
        source "${PROGRAM_DIR}/../bin/lib_linux_release" 2>/dev/null
    ) || _rc=$?

    assert_equals 2 "${_rc}"

    unset SAPHANA_CHECK_OS_OVERRIDE
}

function test_os_override_invalid_format_wrong_distribution() {
    # Test invalid distribution name

    export SAPHANA_CHECK_OS_OVERRIDE='Ubuntu:22.04'

    # This should exit with error code 2
    local _rc=0
    (
        unset LIB_LINUX_RELEASE
        source "${PROGRAM_DIR}/../bin/lib_linux_release" 2>/dev/null
    ) || _rc=$?

    assert_equals 2 "${_rc}"

    unset SAPHANA_CHECK_OS_OVERRIDE
}

function test_os_override_invalid_format_bad_version() {
    # Test invalid version format (missing minor version)

    export SAPHANA_CHECK_OS_OVERRIDE='SLES:15'

    # This should exit with error code 2
    local _rc=0
    (
        unset LIB_LINUX_RELEASE
        source "${PROGRAM_DIR}/../bin/lib_linux_release" 2>/dev/null
    ) || _rc=$?

    assert_equals 2 "${_rc}"

    unset SAPHANA_CHECK_OS_OVERRIDE
}

function test_os_override_invalid_format_extra_fields() {
    # Test invalid format with extra fields

    export SAPHANA_CHECK_OS_OVERRIDE='SLES:15.5:extra'

    # This should exit with error code 2
    local _rc=0
    (
        unset LIB_LINUX_RELEASE
        source "${PROGRAM_DIR}/../bin/lib_linux_release" 2>/dev/null
    ) || _rc=$?

    assert_equals 2 "${_rc}"

    unset SAPHANA_CHECK_OS_OVERRIDE
}

function test_os_override_valid_formats_various() {
    # Test various valid version formats

    local -a valid_overrides=(
        'SLES:12.5'
        'SLES:15.7'
        'RHEL:7.9'
        'RHEL:8.0'
        'RHEL:9.99'
        'RHEL:10.0'
        'OLS:7.9'
        'OLS:8.10'
    )

    for override in "${valid_overrides[@]}"; do
        export SAPHANA_CHECK_OS_OVERRIDE="${override}"

        # Reload lib_linux_release with override
        local _rc=0
        (
            unset LIB_LINUX_RELEASE
            source "${PROGRAM_DIR}/../bin/lib_linux_release" 2>/dev/null
        ) || _rc=$?

        assert_equals 0 "${_rc}"
    done

    unset SAPHANA_CHECK_OS_OVERRIDE
}

function test_os_override_no_override() {
    # Test that without override, normal detection works

    unset SAPHANA_CHECK_OS_OVERRIDE

    # Reload lib_linux_release without override
    # Note: This will actually detect the real OS, so we just verify it doesn't crash
    local _rc=0
    (
        unset LIB_LINUX_RELEASE
        source "${PROGRAM_DIR}/../bin/lib_linux_release" 2>/dev/null
        # Just verify the variables are set
        [[ -n "${OS_NAME}" ]] || exit 1
        [[ -n "${OS_VERSION}" ]] || exit 1
    ) || _rc=$?

    assert_equals 0 "${_rc}"
}

function set_up_before_script() {

    # Store original values to restore later
    ORIGINAL_OS_NAME="${OS_NAME:-}"
    ORIGINAL_OS_VERSION="${OS_VERSION:-}"
    ORIGINAL_OS_LEVEL="${OS_LEVEL:-}"

    #shellcheck source=./saphana-logger-stubs
    source "${PROGRAM_DIR}/./saphana-logger-stubs"

}

function tear_down_after_script() {
    # Restore original values
    OS_NAME="${ORIGINAL_OS_NAME}"
    OS_VERSION="${ORIGINAL_OS_VERSION}"
    OS_LEVEL="${ORIGINAL_OS_LEVEL}"

    unset SAPHANA_CHECK_OS_OVERRIDE
}

# set_up - runs before each test
function set_up() {
    # Ensure clean state for each test
    unset SAPHANA_CHECK_OS_OVERRIDE
}

# tear_down - runs after each test
function tear_down() {
    # Clean up
    unset SAPHANA_CHECK_OS_OVERRIDE
}

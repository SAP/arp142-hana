#!/usr/bin/env bash
set -u      # treat unset variables as an error

PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
[[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
readonly PROGRAM_DIR

testOSOverride_SLES_Valid() {
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

    assertEquals "OS_NAME should be Linux SLES" 'Linux SLES' "${os_name}"
    assertEquals "OS_VERSION should be 15.5" '15.5' "${os_version}"

    unset SAPHANA_CHECK_OS_OVERRIDE
}

testOSOverride_RHEL_Valid() {
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

    assertEquals "OS_NAME should be Linux RHEL" 'Linux RHEL' "${os_name}"
    assertEquals "OS_VERSION should be 9.2" '9.2' "${os_version}"

    unset SAPHANA_CHECK_OS_OVERRIDE
}

testOSOverride_OLS_Valid() {
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

    assertEquals "OS_NAME should be Linux OLS" 'Linux OLS' "${os_name}"
    assertEquals "OS_VERSION should be 8.6" '8.6' "${os_version}"

    unset SAPHANA_CHECK_OS_OVERRIDE
}

testOSOverride_InvalidFormat_MissingColon() {
    # Test invalid format without colon

    export SAPHANA_CHECK_OS_OVERRIDE='SLES15.5'

    # This should exit with error code 2, so we need to test in a subshell
    local _rc=0
    (
        unset LIB_LINUX_RELEASE
        source "${PROGRAM_DIR}/../bin/lib_linux_release" 2>/dev/null
    ) || _rc=$?

    assertEquals "Invalid format should exit with code 2" 2 ${_rc}

    unset SAPHANA_CHECK_OS_OVERRIDE
}

testOSOverride_InvalidFormat_WrongDistribution() {
    # Test invalid distribution name

    export SAPHANA_CHECK_OS_OVERRIDE='Ubuntu:22.04'

    # This should exit with error code 2
    local _rc=0
    (
        unset LIB_LINUX_RELEASE
        source "${PROGRAM_DIR}/../bin/lib_linux_release" 2>/dev/null
    ) || _rc=$?

    assertEquals "Invalid distribution should exit with code 2" 2 ${_rc}

    unset SAPHANA_CHECK_OS_OVERRIDE
}

testOSOverride_InvalidFormat_BadVersion() {
    # Test invalid version format (missing minor version)

    export SAPHANA_CHECK_OS_OVERRIDE='SLES:15'

    # This should exit with error code 2
    local _rc=0
    (
        unset LIB_LINUX_RELEASE
        source "${PROGRAM_DIR}/../bin/lib_linux_release" 2>/dev/null
    ) || _rc=$?

    assertEquals "Invalid version format should exit with code 2" 2 ${_rc}

    unset SAPHANA_CHECK_OS_OVERRIDE
}

testOSOverride_InvalidFormat_ExtraFields() {
    # Test invalid format with extra fields

    export SAPHANA_CHECK_OS_OVERRIDE='SLES:15.5:extra'

    # This should exit with error code 2
    local _rc=0
    (
        unset LIB_LINUX_RELEASE
        source "${PROGRAM_DIR}/../bin/lib_linux_release" 2>/dev/null
    ) || _rc=$?

    assertEquals "Extra fields should exit with code 2" 2 ${_rc}

    unset SAPHANA_CHECK_OS_OVERRIDE
}

testOSOverride_ValidFormats_Various() {
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

        assertEquals "Override ${override} should be valid" 0 ${_rc}
    done

    unset SAPHANA_CHECK_OS_OVERRIDE
}

testOSOverride_NoOverride() {
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

    assertEquals "Without override, normal detection should work" 0 ${_rc}
}

oneTimeSetUp () {

    # Store original values to restore later
    ORIGINAL_OS_NAME="${OS_NAME:-}"
    ORIGINAL_OS_VERSION="${OS_VERSION:-}"
    ORIGINAL_OS_LEVEL="${OS_LEVEL:-}"

    #shellcheck source=./saphana-logger-stubs
    source "${PROGRAM_DIR}/./saphana-logger-stubs"

}

oneTimeTearDown() {
    # Restore original values
    OS_NAME="${ORIGINAL_OS_NAME}"
    OS_VERSION="${ORIGINAL_OS_VERSION}"
    OS_LEVEL="${ORIGINAL_OS_LEVEL}"

    unset SAPHANA_CHECK_OS_OVERRIDE
}

# setUp - runs before each test
setUp() {
    # Ensure clean state for each test
    unset SAPHANA_CHECK_OS_OVERRIDE
}

# tearDown - runs after each test
tearDown() {
    # Clean up
    unset SAPHANA_CHECK_OS_OVERRIDE
}

#Import Libraries
# - order is important - sourcing shunit triggers testing
# - that's also the reason, why it could not be done during oneTimeSetup

#shellcheck source=./shunit2
source "${PROGRAM_DIR}/shunit2"

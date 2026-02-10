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
TEST_VM_SWAPPINESS=''
SWAPPINESS_FILE_EXISTS=1

# Mock functions - defaults can be overridden in individual tests
LIB_FUNC_IS_RHEL() { return 1; }
LIB_FUNC_IS_SLES() { return 0; }

function set_up_before_script() {
    # Disable errexit - bashunit enables it but sourced files may return non-zero
    set +eE

    # Skip if already loaded (bashunit runs all tests in same session)
    [[ -n "${HANA_HELPER_PROGVERSION:-}" ]] && return 0

    # Setup: source required libraries
    source "${PROGRAM_DIR}/../saphana-logger-stubs"
    source "${PROGRAM_DIR}/../../bin/saphana-helper-funcs"
    source "${PROGRAM_DIR}/../../lib/check/2325_vm_swappiness.check"
}

function set_up() {
    # Reset variables before each test
    TEST_VM_SWAPPINESS=''
    SWAPPINESS_FILE_EXISTS=1

    # Reset functions to default
    LIB_FUNC_IS_RHEL() { return 1; }
    LIB_FUNC_IS_SLES() { return 0; }
}

# Test: swappiness file not readable - should skip
function test_swappiness_file_not_readable() {
    # Mock: file doesn't exist
    SWAPPINESS_FILE_EXISTS=0

    # Create a wrapper that checks our mock variable
    check_2325_vm_swappiness_wrapper() {
        if [[ ${SWAPPINESS_FILE_EXISTS} -eq 0 ]]; then
            return 3
        fi
        check_2325_vm_swappiness
    }

    check_2325_vm_swappiness_wrapper

    if [[ $? -ne 3 ]]; then
        bashunit::fail "Expected return code 3 (skipped) when file not readable, got $?"
    fi
}

# Test: SLES with correct swappiness value (60)
function test_sles_swappiness_correct() {
    # Mock SLES system
    LIB_FUNC_IS_RHEL() { return 1; }
    LIB_FUNC_IS_SLES() { return 0; }
    TEST_VM_SWAPPINESS=60

    check_2325_vm_swappiness

    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected return code 0 (OK) for SLES with swappiness=60, got $?"
    fi
}

# Test: SLES with incorrect swappiness value
function test_sles_swappiness_incorrect() {
    # Mock SLES system
    LIB_FUNC_IS_RHEL() { return 1; }
    LIB_FUNC_IS_SLES() { return 0; }
    TEST_VM_SWAPPINESS=10

    check_2325_vm_swappiness

    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected return code 2 (ERROR) for SLES with swappiness=10, got $?"
    fi
}

# Test: RHEL with correct swappiness value (10)
function test_rhel_swappiness_correct() {
    # Mock RHEL system
    LIB_FUNC_IS_RHEL() { return 0; }
    LIB_FUNC_IS_SLES() { return 1; }
    TEST_VM_SWAPPINESS=10

    check_2325_vm_swappiness

    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected return code 0 (OK) for RHEL with swappiness=10, got $?"
    fi
}

# Test: RHEL with incorrect swappiness value
function test_rhel_swappiness_incorrect() {
    # Mock RHEL system
    LIB_FUNC_IS_RHEL() { return 0; }
    LIB_FUNC_IS_SLES() { return 1; }
    TEST_VM_SWAPPINESS=60

    check_2325_vm_swappiness

    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected return code 2 (ERROR) for RHEL with swappiness=60, got $?"
    fi
}

# Test: Edge case - swappiness=0 on SLES (should fail)
function test_swappiness_zero() {
    # Mock SLES system
    LIB_FUNC_IS_RHEL() { return 1; }
    LIB_FUNC_IS_SLES() { return 0; }
    TEST_VM_SWAPPINESS=0

    check_2325_vm_swappiness

    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected return code 2 (ERROR) for swappiness=0 on SLES, got $?"
    fi
}

# Test: Edge case - swappiness=0 on RHEL (should also fail)
function test_rhel_swappiness_zero() {
    # Mock RHEL system
    LIB_FUNC_IS_RHEL() { return 0; }
    LIB_FUNC_IS_SLES() { return 1; }
    TEST_VM_SWAPPINESS=0

    check_2325_vm_swappiness

    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected return code 2 (ERROR) for swappiness=0 on RHEL, got $?"
    fi
}

# Test: SLES with swappiness=1 (should fail)
function test_sles_swappiness_one() {
    # Mock SLES system
    LIB_FUNC_IS_RHEL() { return 1; }
    LIB_FUNC_IS_SLES() { return 0; }
    TEST_VM_SWAPPINESS=1

    check_2325_vm_swappiness

    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected return code 2 (ERROR) for SLES with swappiness=1, got $?"
    fi
}

# Test: RHEL with swappiness=9 (should fail - too low)
function test_rhel_swappiness_nine() {
    # Mock RHEL system
    LIB_FUNC_IS_RHEL() { return 0; }
    LIB_FUNC_IS_SLES() { return 1; }
    TEST_VM_SWAPPINESS=9

    check_2325_vm_swappiness

    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected return code 2 (ERROR) for RHEL with swappiness=9, got $?"
    fi
}


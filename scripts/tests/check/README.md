# Unit Tests for Check Functions

This directory contains bashunit tests for individual check functions.

## Creating a New Test File

Use the template file `_TEMPLATE.bashunit.sh.template` as a starting point:
```bash
cp _TEMPLATE.bashunit.sh.template NNNN_check_name.bashunit.sh
```

## Test Coverage Report

Run the coverage report to see which checks are missing tests:
```bash
bash ../check-coverage-report.sh              # Full report
bash ../check-coverage-report.sh --untested-only  # Only list untested checks
```

## Critical Rules

### 0. ALWAYS Test for RC=99 (Unprocessed Check)

**RC=99 means "check logic never reached a conclusion"** - this is a BUG!

The 2325_vm_swappiness bug was caused by check logic that silently skipped RHEL systems,
returning the default RC=99 instead of properly executing the check.

**Every test MUST verify the check was actually processed:**
```bash
# Helper function (included in template)
assert_check_processed() {
    local rc=$1
    local context="${2:-}"
    if [[ ${rc} -eq 99 ]]; then
        bashunit::fail "RC=99 (unprocessed) - check logic did not reach a conclusion${context:+ in }${context}"
    fi
}

# Usage in tests
function test_rhel_check_executes() {
    LIB_FUNC_IS_RHEL() { return 0; }
    check_NNNN_check_name
    local rc=$?
    
    # CRITICAL: Always check this first!
    assert_check_processed ${rc} "RHEL"
}
```

**Runtime Detection:** The main script (`saphana-check.sh`) now logs warnings when checks return RC=99
and displays an "Unproc" (unprocessed) counter in the summary.

### 1. Use a Test-Specific Guard Variable

**WRONG** - This will break other tests:
```bash
[[ -n "${HANA_HELPER_PROGVERSION:-}" ]] && return 0
```

**CORRECT** - Use a unique guard for each test file:
```bash
[[ -n "${_NNNN_check_name_test_loaded:-}" ]] && return 0
_NNNN_check_name_test_loaded=true
```

The `HANA_HELPER_PROGVERSION` variable is set globally by `saphana-helper-funcs`. If you use it as your guard, subsequent test files won't load their check functions because the guard will trigger an early return.

### 2. Don't Source `saphana-helper-funcs`

Most tests don't need to source `saphana-helper-funcs` because:
- The functions you need (`LIB_FUNC_IS_RHEL`, `LIB_FUNC_IS_SLES`, etc.) should be mocked anyway
- Sourcing it sets `HANA_HELPER_PROGVERSION` which affects other tests

Only source these files:
```bash
source "${PROGRAM_DIR}/../saphana-logger-stubs"
source "${PROGRAM_DIR}/../../lib/check/NNNN_check_name.check"
```

### 3. Define Mock Functions at Script Level

Define your mock functions at the top of the file, outside any function:
```bash
# Mock functions
LIB_FUNC_IS_RHEL() { return 1; }
LIB_FUNC_IS_SLES() { return 0; }
```

Then reset them in `set_up()` if individual tests need different behavior.

### 4. Use TEST_ Variables for Mocking File Reads

If your check reads from `/proc` or other system files, add a `TEST_` variable pattern in the check itself:
```bash
# In the check file
if [[ -z ${TEST_MY_VALUE:-} ]]; then
    _value=$(</proc/sys/some/file)
else
    _value="${TEST_MY_VALUE}"
fi
```

## Running Tests

```bash
# Run all check tests
bash ./bashunit ./check/*.bashunit.sh

# Run a specific test
bash ./bashunit ./check/NNNN_check_name.bashunit.sh

# Run multiple specific tests (to verify no cross-test interference)
bash ./bashunit ./check/your_test.bashunit.sh ./check/another_test.bashunit.sh
```

## Test Structure

```bash
#!/usr/bin/env bash
set -u

# 1. PROGRAM_DIR setup
if [[ -z "${PROGRAM_DIR:-}" ]]; then
    PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
    [[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
fi

# 2. Test-specific guard (CRITICAL!)
[[ -n "${_NNNN_test_loaded:-}" ]] && return 0
_NNNN_test_loaded=true

# 3. Mock variables
TEST_SOME_VALUE=''

# 4. Mock functions
LIB_FUNC_IS_RHEL() { return 1; }

# 5. set_up_before_script - runs once before all tests
function set_up_before_script() {
    set +eE
    source "${PROGRAM_DIR}/../saphana-logger-stubs"
    source "${PROGRAM_DIR}/../../lib/check/NNNN_check.check"
}

# 6. set_up - runs before each test
function set_up() {
    TEST_SOME_VALUE=''
    LIB_FUNC_IS_RHEL() { return 1; }
}

# 7. Test functions
function test_something() {
    # arrange
    TEST_SOME_VALUE='expected'
    
    # act
    check_NNNN_check
    local rc=$?
    
    # assert - ALWAYS check RC != 99 first!
    assert_check_processed ${rc}
    if [[ ${rc} -ne 0 ]]; then
        bashunit::fail "Expected RC=0"
    fi
}
```

## Mandatory Tests for Dual-Platform Checks

If your check supports both SLES and RHEL, you MUST include tests for both platforms:

```bash
function test_sles_check_executes() {
    LIB_FUNC_IS_RHEL() { return 1; }
    LIB_FUNC_IS_SLES() { return 0; }
    TEST_VALUE='sles_value'
    
    check_NNNN_check
    local rc=$?
    
    assert_check_processed ${rc} "SLES"
    # Additional assertions...
}

function test_rhel_check_executes() {
    LIB_FUNC_IS_RHEL() { return 0; }
    LIB_FUNC_IS_SLES() { return 1; }
    TEST_VALUE='rhel_value'
    
    check_NNNN_check
    local rc=$?
    
    assert_check_processed ${rc} "RHEL"
    # Additional assertions...
}
```

This ensures both code paths are exercised and prevents silent failures like the 2325_vm_swappiness bug.

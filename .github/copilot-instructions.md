# SAP HANA Checks - AI Coding Agent Instructions

## Project Overview
This is a comprehensive Bash-based OS validation suite for SAP HANA environments, supporting SLES and RHEL on Intel x64 and IBM Power architectures. The tool performs read-only system checks against SAP recommendations without modifying the system.

## Architecture & Core Components

### Check Framework Structure
- **Main runner**: `scripts/bin/saphana-check.sh` - Central orchestrator with shflags-based CLI
- **Individual checks**: `scripts/lib/check/*.check` - Each check is a self-contained Bash function
- **Check sets**: `scripts/lib/checkset/*.checkset` - Platform-specific check collections (e.g., `SLESonX64only.checkset`)
- **Helper libraries**: `scripts/bin/saphana-helper-funcs` - Common functions prefixed with `LIB_`
- **Logging system**: `scripts/bin/saphana-logger` - Structured logging with levels and color support

### Check Function Pattern
Every check follows this strict pattern in `scripts/lib/check/NNNN_description.check`:
```bash
function check_NNNN_description {
    logTrace "<${BASH_SOURCE[0]}:${FUNCNAME[*]}>"
    local -i _retval=99  # Default: not applicable

    # MODIFICATION SECTION>> (SAP Notes, thresholds)
    local -r sapnote='#1234567'
    # MODIFICATION SECTION<<

    # PRECONDITIONS (OS version, architecture checks)
    if ! LIB_FUNC_IS_SLES; then
        logCheckSkipped "CHECK does not apply"
        _retval=3
    fi

    # CHECK LOGIC
    if [[ ${_retval} -eq 99 ]]; then
        # Actual validation logic
        if [[ condition_met ]]; then
            logCheckOk "Description (SAP Note ${sapnote}) (details)"
            _retval=0
        else
            logCheckError "Description (SAP Note ${sapnote}) (details)"
            _retval=2
        fi
    fi

    logDebug "<${BASH_SOURCE[0]}:${FUNCNAME[0]}> # RC=${_retval}"
    return ${_retval}
}
```

### Return Code Convention
- `0`: Check passed (OK)
- `1`: Check failed with warning
- `2`: Check failed with error
- `3`: Check skipped (not applicable)
- `99`: Internal state (not applicable/unprocessed)

### Platform Detection Functions
Use these helper functions for platform-specific logic (defined across `saphana-helper-funcs` and `lib_*` files):

**OS detection** (in `lib_linux_release`):
- `LIB_FUNC_IS_SLES` / `LIB_FUNC_IS_RHEL` / `LIB_FUNC_IS_OLS` - OS family
- `LIB_FUNC_IS_SLES4SAP` / `LIB_FUNC_IS_RHEL4SAP` - SAP-specific variants

**Architecture** (in `saphana-helper-funcs`):
- `LIB_FUNC_IS_INTEL` / `LIB_FUNC_IS_AMD` / `LIB_FUNC_IS_X64` / `LIB_FUNC_IS_IBMPOWER`

**Virtualization**:
- `LIB_FUNC_IS_BARE_METAL`
- `LIB_FUNC_IS_VIRT_VMWARE` / `LIB_FUNC_IS_VIRT_XEN` / `LIB_FUNC_IS_VIRT_KVM` / `LIB_FUNC_IS_VIRT_MICROSOFT`
- `LIB_FUNC_IS_NUTANIX_AHV`

**Cloud providers**:
- `LIB_FUNC_IS_CLOUD_AMAZON` / `LIB_FUNC_IS_CLOUD_MICROSOFT` / `LIB_FUNC_IS_CLOUD_GOOGLE`
- `LIB_FUNC_IS_CLOUD_IBM` / `LIB_FUNC_IS_CLOUD_ALIBABA` / `LIB_FUNC_IS_CLOUD_HUAWEI`
- `LIB_FUNC_IS_CLOUD_SAPCC`

**Utilities**:
- `LIB_FUNC_IS_ROOT` - Permission check
- `LIB_FUNC_IS_NVM_PMEM` - NVM/PMEM detection
- `LIB_FUNC_COMPARE_VERSIONS` - Version comparison (returns 0=equal, 1=first higher, 2=second higher)
- `LIB_FUNC_VALIDATE_OS` - OS validation
- `LIB_FUNC_NORMALIZE_KERNEL` / `LIB_FUNC_NORMALIZE_KERNELn` - Kernel version normalization
- `LIB_FUNC_NORMALIZE_RPM` / `LIB_FUNC_NORMALIZE_RPMn` - RPM version normalization
- `LIB_FUNC_TRIM` / `LIB_FUNC_TRIM_LEFT` / `LIB_FUNC_TRIM_RIGHT` - String trimming
- `LIB_FUNC_STRINGCONTAIN` - String containment check
- `LIB_FUNC_CHECK_CHECK_SECURITY` - Check file security validation

## Development Workflows

### Adding New Checks
1. Create `scripts/lib/check/NNNN_description.check` following the pattern above
2. Add the check ID to relevant checksets in `scripts/lib/checkset/`
3. Create unit test in `scripts/tests/check/NNNN_description.bashunit.sh`
4. Test with: `./saphana-check.sh -c NNNN`

### Testing Framework
- **Unit tests**: Uses bashunit framework in `scripts/tests/`
- **Test runner**: `scripts/tests/bashunit` executes all bashunit tests (`*.bashunit.sh`)
- **Mocking**: Tests use `saphana-logger-stubs` for logging functions
- **CI**: Tests run in GitHub Actions

### Running Tests
```bash
cd scripts/tests
bash ./bashunit ./*.bashunit.sh            # All bashunit tests
bash ./bashunit ./check/*.bashunit.sh      # Only check tests
```

### bashunit Test Pattern for Check Functions
Tests for check functions use bashunit conventions. **CRITICAL**: The guard variable goes inside `set_up_before_script()` and uses the format `_NNNN_test_loaded` (abbreviated, NOT the full check name):
```bash
#!/usr/bin/env bash
set -u

if [[ -z "${PROGRAM_DIR:-}" ]]; then
    PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
    [[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
fi

# Mock variables for testing
TEST_SOME_VALUE=''

# Mock functions (do NOT source saphana-helper-funcs)
LIB_FUNC_IS_RHEL() { return 1; }
LIB_FUNC_IS_SLES() { return 0; }

# Test functions are defined BEFORE set_up_before_script
function test_example_case() {
    #arrange
    TEST_SOME_VALUE='expected'

    #act
    check_NNNN_check_name

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0"
    fi
    assert_true true
}

function set_up_before_script() {
    set +eE

    # CRITICAL: Guard inside set_up_before_script! Use _NNNN_test_loaded format
    # Do NOT use HANA_HELPER_PROGVERSION - it breaks other tests
    [[ -n "${_NNNN_test_loaded:-}" ]] && return 0
    _NNNN_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/NNNN_check_name.check
    source "${PROGRAM_DIR}/../../lib/check/NNNN_check_name.check"
}

function set_up() {
    TEST_SOME_VALUE=''
    LIB_FUNC_IS_RHEL() { return 1; }
    LIB_FUNC_IS_SLES() { return 0; }
}
```

**IMPORTANT — Risky test prevention**: bashunit 0.34.1+ flags tests as "risky" when no assertion is registered. Since `bashunit::fail` only counts when it fires (on failure), every test function must end with `assert_true true` to register a passing assertion on the happy path.

**Why test-specific guards matter**: bashunit runs all test files in the same session. Using `HANA_HELPER_PROGVERSION` as a guard causes subsequent test files to skip loading their check functions, breaking those tests.

**assert_check_processed helper** (defined in `_TEMPLATE.bashunit.sh.template`): Use this in tests to catch RC=99 (unprocessed) bugs early:
```bash
assert_check_processed() {
    local rc=$1
    local context="${2:-}"
    if [[ ${rc} -eq 99 ]]; then
        bashunit::fail "RC=99 (unprocessed) - check logic did not reach a conclusion${context:+ in }${context}"
    fi
}
```

See `scripts/tests/check/README.md` and `scripts/tests/check/_TEMPLATE.bashunit.sh.template` for detailed guidance.

### Code Quality Standards
- **ShellCheck**: Configured via `.shellcheckrc` (enabled: `avoid-nullary-conditions`, `useless-use-of-cat`, `avoid-negated-conditions`; `external-sources=true`)
- **Formatting**: Uses shfmt with `--indent 4 -ci -sr -kp`
- **Style**: bashate validation with exceptions for E006, E043, E010

### CI/CD Pipeline (GitHub Actions)
- **CI** (`CI.yml`): Runs on all pushes and PRs to `main`. Steps:
  - ShellCheck on `scripts/bin/saphana-*`, `scripts/bin/lib*`, and all `*.check` files
  - bashunit tests with JUnit XML reports (uploaded as artifacts)
  - bashate code format checking
  - shfmt format checking (non-blocking, uses `|| true`)
- **CD** (`CD.yml`): Triggered on version tags. Creates RPM, tar.xz, and tar.gz release artifacts with checksums.

### Available Checksets
Platform-specific check collections in `scripts/lib/checkset/`:
- `SLESonX64only.checkset` - SLES on Intel/AMD x86_64
- `RHELonX64only.checkset` - RHEL on Intel/AMD x86_64
- `SLESonPoweronly.checkset` - SLES on IBM Power
- `RHELonPoweronly.checkset` - RHEL on IBM Power

### Execution Modes
- `./saphana-check.sh` - All checks
- `./saphana-check.sh -c 0800` - Single check by ID
- `./saphana-check.sh -c 08*` - Pattern matching
- `./saphana-check.sh -C SLESonX64only` - Platform-specific checkset
- Logging levels: `-v` (verbose), `-d` (debug), `-t` (trace)

## Key Conventions

### SAP Note References
Always include SAP Note numbers in MODIFICATION SECTION and log messages:
```bash
local -r sapnote='#1944799'
logCheckError "Description (SAP Note ${sapnote}) (current: ${value}, expected: ${expected})"
```

### Version Handling
Use `LIB_FUNC_COMPARE_VERSIONS` for all version comparisons - handles complex version strings and returns standardized codes (0=equal, 1=first higher, 2=second higher).

### Naming Conventions
- Check files: `NNNN_description.check` (4-digit category + underscore_description)
- Categories: 0xxx=OS, 1xxx=CPU, 2xxx=Memory, 3xxx=Network, 5xxx=I/O, 7xxx=HA, 8xxx=HANA-specific
- Functions: `check_NNNN_description` matching filename
- Library functions: `LIB_FUNC_*` prefix for shared utilities

This framework prioritizes reliability, platform compatibility, and comprehensive system validation following SAP's infrastructure requirements.
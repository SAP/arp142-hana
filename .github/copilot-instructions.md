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
Use these helper functions for platform-specific logic:
- `LIB_FUNC_IS_SLES` / `LIB_FUNC_IS_RHEL` - OS detection
- `LIB_FUNC_IS_INTEL` / `LIB_FUNC_IS_IBMPOWER` - Architecture detection
- `LIB_FUNC_IS_ROOT` - Permission check
- `LIB_FUNC_COMPARE_VERSIONS` - Version comparison utility

## Development Workflows

### Adding New Checks
1. Create `scripts/lib/check/NNNN_description.check` following the pattern above
2. Add the check ID to relevant checksets in `scripts/lib/checkset/`
3. Create unit test in `scripts/tests/check/NNNN_description_test.sh`
4. Test with: `./saphana-check.sh -c NNNN`

### Testing Framework
- **Unit tests**: Uses shunit2 framework in `scripts/tests/`
- **Test runner**: `scripts/tests/test_runner` executes all tests
- **Mocking**: Tests use `saphana-logger-stubs` for logging functions
- **CI**: Tests run in GitHub Actions with `SHUNIT_COLOR=always`

### Running Tests
```bash
cd scripts/tests
./test_runner                              # All tests
./test_runner -t "check/*_test.sh"        # Only check tests
```

### Code Quality Standards
- **ShellCheck**: Configured via `.shellcheckrc` with specific rules enabled
- **Formatting**: Uses shfmt with `--indent 4 -ci -sr -kp`
- **Style**: bashate validation with exceptions for E006, E043, E010

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
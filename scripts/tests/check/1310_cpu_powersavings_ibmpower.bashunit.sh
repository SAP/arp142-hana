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
LIB_PLATF_POWER_POWERMODE=''
LIB_PLATF_POWER_PLATFORM_BASE=''
RETURN_POWER_POWERMODE=''
_is_ibmpower=0

# Override path used by check to a non-existing file by default so the
# fallback (lparcfg-derived LIB_PLATF_POWER_POWERMODE) logic is exercised.
path_to_value_desc='/nonexistent/saphana-check/value_desc'

# Mock functions
LIB_FUNC_IS_IBMPOWER() { return "${_is_ibmpower}" ; }

# Trim helper used by the check (mock to avoid sourcing helper-funcs)
LIB_FUNC_TRIM() {
    local s="$1"
    # strip leading and trailing whitespace
    s="${s#"${s%%[![:space:]]*}"}"
    s="${s%"${s##*[![:space:]]}"}"
    printf '%s' "${s}"
}

# Mock the transform function
LIB_FUNC_TRANSFORM_POWER_POWERMODE() {
    local powermode="$1"

    if [[ "${LIB_PLATF_POWER_PLATFORM_BASE:-}" =~ POWER(11|10|9) ]]; then
        case "${powermode}" in
            '0001')  powermode='Maximum Performance' ;;
            '0002')  powermode='None' ;;
            '0003')  powermode='Static' ;;
            '0004')  powermode='Dynamic Performance' ;;
            *)       powermode='Unknown';;
        esac
    else
        powermode='Unknown'
    fi

    printf -v RETURN_POWER_POWERMODE '%s' "${powermode}"
}


# ========================================
# PRECONDITION TESTS
# ========================================

function test_precondition_not_ibmpower_skipped() {

    #arrange
    _is_ibmpower=1
    LIB_PLATF_POWER_PLATFORM_BASE='POWER10'
    LIB_PLATF_POWER_POWERMODE='0002000200020002'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    if [[ $? -ne 3 ]]; then
        bashunit::fail "Expected RC=3 (skipped) for non-IBM Power"
    fi
    assert_true true
}

function test_precondition_powermode_unknown() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER10'
    LIB_PLATF_POWER_POWERMODE=

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for unknown power mode"
    fi
    assert_true true
}

# ========================================
# POWER11 TESTS
# ========================================

function test_power11_maximum_performance_ok() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER11'
    LIB_PLATF_POWER_POWERMODE='0001000100010001'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for POWER11 ambiguous mode 0001"
    fi
    assert_true true
}

function test_power11_maximum_performance_system_diff_partition_ok() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER11'
    LIB_PLATF_POWER_POWERMODE='0001000100010002'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for POWER11 ambiguous system mode 0001 with different partition mode"
    fi
    assert_true true
}

function test_power11_none_error() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER11'
    LIB_PLATF_POWER_POWERMODE='0002000200020002'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for POWER11 None mode"
    fi
    assert_true true
}

function test_power11_static_error() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER11'
    LIB_PLATF_POWER_POWERMODE='0003000300030003'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for POWER11 Static mode"
    fi
    assert_true true
}

function test_power11_dynamic_performance_error() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER11'
    LIB_PLATF_POWER_POWERMODE='0004000400040004'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for POWER11 Dynamic Performance"
    fi
    assert_true true
}

function test_power11_unknown_mode_error() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER11'
    LIB_PLATF_POWER_POWERMODE='00ff00ff00ff00ff'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for POWER11 unknown mode"
    fi
    assert_true true
}

# ========================================
# POWER10 TESTS
# ========================================

function test_power10_maximum_performance_ok() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER10'
    LIB_PLATF_POWER_POWERMODE='0001000100010001'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for POWER10 ambiguous mode 0001"
    fi
    assert_true true
}

function test_power10_none_error() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER10'
    LIB_PLATF_POWER_POWERMODE='0002000200020002'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for POWER10 None mode"
    fi
    assert_true true
}

function test_power10_dynamic_performance_error() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER10'
    LIB_PLATF_POWER_POWERMODE='0004000400040004'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for POWER10 Dynamic Performance"
    fi
    assert_true true
}

function test_power10_static_error() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER10'
    LIB_PLATF_POWER_POWERMODE='0003000300030003'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for POWER10 Static mode"
    fi
    assert_true true
}

function test_power10_unknown_mode_error() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER10'
    LIB_PLATF_POWER_POWERMODE='00ff00ff00ff00ff'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for POWER10 unknown mode"
    fi
    assert_true true
}

function test_power10_system_partition_mode_diff_ok() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER10'
    LIB_PLATF_POWER_POWERMODE='0001000100010002'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for POWER10 ambiguous system mode 0001 with different partition mode"
    fi
    assert_true true
}

# ========================================
# POWER9 TESTS
# ========================================

function test_power9_maximum_performance_ok() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'
    LIB_PLATF_POWER_POWERMODE='0001000100010001'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for POWER9 ambiguous mode 0001"
    fi
    assert_true true
}

function test_power9_none_error() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'
    LIB_PLATF_POWER_POWERMODE='0002000200020002'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for POWER9 None mode"
    fi
    assert_true true
}

function test_power9_dynamic_performance_error() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'
    LIB_PLATF_POWER_POWERMODE='0004000400040004'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for POWER9 Dynamic Performance"
    fi
    assert_true true
}

function test_power9_static_error() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'
    LIB_PLATF_POWER_POWERMODE='0003000300030003'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for POWER9 Static mode"
    fi
    assert_true true
}

function test_power9_unknown_mode_error() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'
    LIB_PLATF_POWER_POWERMODE='00ff00ff00ff00ff'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for POWER9 unknown mode"
    fi
    assert_true true
}

function test_power9_system_partition_mode_diff_ok() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'
    LIB_PLATF_POWER_POWERMODE='0001000100010004'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for POWER9 ambiguous system mode 0001 with different partition mode"
    fi
    assert_true true
}

# ========================================
# EDGE CASE TESTS
# ========================================

function test_real_world_mixed_mode_power10() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER10'
    LIB_PLATF_POWER_POWERMODE='0002000200020004'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for POWER10 mixed mode"
    fi
    assert_true true
}

function test_real_world_mixed_mode_power9() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'
    LIB_PLATF_POWER_POWERMODE='0004000400040002'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for POWER9 mixed mode"
    fi
    assert_true true
}

function test_system_mode_invalid_partition_valid_power10() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER10'
    LIB_PLATF_POWER_POWERMODE='0003000300030001'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for POWER10 invalid system mode"
    fi
    assert_true true
}

function test_system_mode_valid_partition_invalid_power11() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER11'
    LIB_PLATF_POWER_POWERMODE='0001000100010003'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for POWER11 ambiguous system mode 0001"
    fi
    assert_true true
}


# ========================================
# value_desc INTERFACE TESTS (preferred)
# /sys/firmware/papr/energy_scale_info/1/value_desc
# ========================================

function test_value_desc_maximum_performance_ok() {

    #arrange
    local tmpfile
    tmpfile="$(mktemp)"
    printf 'Maximum Performance' > "${tmpfile}"
    path_to_value_desc="${tmpfile}"
    # No POWERMODE / PLATFORM_BASE needed - preferred interface wins
    LIB_PLATF_POWER_POWERMODE=
    LIB_PLATF_POWER_PLATFORM_BASE=

    #act
    check_1310_cpu_powersavings_ibmpower
    local rc=$?

    #cleanup
    rm -f "${tmpfile}"

    #assert
    if [[ ${rc} -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for value_desc='Maximum Performance' (got RC=${rc})"
    fi
    assert_true true
}

function test_value_desc_maximum_performance_with_whitespace_ok() {

    #arrange
    local tmpfile
    tmpfile="$(mktemp)"
    # value_desc files typically have a trailing newline; also test surrounding whitespace
    printf '  Maximum Performance  \n' > "${tmpfile}"
    path_to_value_desc="${tmpfile}"

    #act
    check_1310_cpu_powersavings_ibmpower
    local rc=$?

    #cleanup
    rm -f "${tmpfile}"

    #assert
    if [[ ${rc} -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for value_desc with trailing newline/whitespace (got RC=${rc})"
    fi
    assert_true true
}

function test_value_desc_dynamic_performance_error() {

    #arrange
    local tmpfile
    tmpfile="$(mktemp)"
    printf 'Dynamic Performance\n' > "${tmpfile}"
    path_to_value_desc="${tmpfile}"

    #act
    check_1310_cpu_powersavings_ibmpower
    local rc=$?

    #cleanup
    rm -f "${tmpfile}"

    #assert
    if [[ ${rc} -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for value_desc='Dynamic Performance' (got RC=${rc})"
    fi
    assert_true true
}

function test_value_desc_empty_error() {

    #arrange
    local tmpfile
    tmpfile="$(mktemp)"
    : > "${tmpfile}"
    path_to_value_desc="${tmpfile}"

    #act
    check_1310_cpu_powersavings_ibmpower
    local rc=$?

    #cleanup
    rm -f "${tmpfile}"

    #assert
    if [[ ${rc} -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for empty value_desc file (got RC=${rc})"
    fi
    assert_true true
}

function test_value_desc_takes_precedence_over_lparcfg() {

    #arrange - lparcfg says Maximum Performance, but value_desc says otherwise
    local tmpfile
    tmpfile="$(mktemp)"
    printf 'Static\n' > "${tmpfile}"
    path_to_value_desc="${tmpfile}"
    LIB_PLATF_POWER_PLATFORM_BASE='POWER11'
    LIB_PLATF_POWER_POWERMODE='0001000100010001'   # would be OK via fallback

    #act
    check_1310_cpu_powersavings_ibmpower
    local rc=$?

    #cleanup
    rm -f "${tmpfile}"

    #assert - value_desc must win, so RC=2
    if [[ ${rc} -ne 2 ]]; then
        bashunit::fail "Expected RC=2 - value_desc must take precedence over lparcfg fallback (got RC=${rc})"
    fi
    assert_true true
}

function test_value_desc_missing_uses_lparcfg_fallback_ok() {

    #arrange - non-existing value_desc path; lparcfg says Maximum Performance
    path_to_value_desc='/nonexistent/saphana-check/value_desc'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER10'
    LIB_PLATF_POWER_POWERMODE='0001000100010001'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) - fallback 0001 is ambiguous when value_desc file is missing"
    fi
    assert_true true
}


function set_up_before_script() {

    # Disable errexit - bashunit enables it but sourced files may return non-zero
    set +eE

    # Skip if already loaded (bashunit runs all tests in same session)
    [[ -n "${_1310_test_loaded:-}" ]] && return 0
    _1310_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/1310_cpu_powersavings_ibmpower.check
    source "${PROGRAM_DIR}/../../lib/check/1310_cpu_powersavings_ibmpower.check"

}

function set_up() {

    # Reset mock variables
    LIB_PLATF_POWER_POWERMODE=
    LIB_PLATF_POWER_PLATFORM_BASE=
    RETURN_POWER_POWERMODE=
    _is_ibmpower=0
    # Default to a non-existing path so fallback logic is exercised
    path_to_value_desc='/nonexistent/saphana-check/value_desc'

}

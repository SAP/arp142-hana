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

# Mock functions
LIB_FUNC_IS_IBMPOWER() { return "${_is_ibmpower}" ; }

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
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for POWER11 maximum performance"
    fi
}

function test_power11_maximum_performance_system_diff_partition_ok() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER11'
    LIB_PLATF_POWER_POWERMODE='0001000100010002'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for POWER11 system diff partition"
    fi
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
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for POWER10 maximum performance"
    fi
}

function test_power10_none_ok() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER10'
    LIB_PLATF_POWER_POWERMODE='0002000200020002'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for POWER10 None mode"
    fi
}

function test_power10_dynamic_performance_ok() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER10'
    LIB_PLATF_POWER_POWERMODE='0004000400040004'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for POWER10 Dynamic Performance"
    fi
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
}

function test_power10_system_partition_mode_diff_ok() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER10'
    LIB_PLATF_POWER_POWERMODE='0001000100010002'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for POWER10 system/partition diff"
    fi
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
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for POWER9 maximum performance"
    fi
}

function test_power9_none_ok() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'
    LIB_PLATF_POWER_POWERMODE='0002000200020002'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for POWER9 None mode"
    fi
}

function test_power9_dynamic_performance_ok() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'
    LIB_PLATF_POWER_POWERMODE='0004000400040004'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for POWER9 Dynamic Performance"
    fi
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
}

function test_power9_system_partition_mode_diff_ok() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'
    LIB_PLATF_POWER_POWERMODE='0001000100010004'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for POWER9 system/partition diff"
    fi
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
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for POWER10 mixed mode"
    fi
}

function test_real_world_mixed_mode_power9() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'
    LIB_PLATF_POWER_POWERMODE='0004000400040002'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for POWER9 mixed mode"
    fi
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
}

function test_system_mode_valid_partition_invalid_power11() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER11'
    LIB_PLATF_POWER_POWERMODE='0001000100010003'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for POWER11 valid system mode"
    fi
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

}

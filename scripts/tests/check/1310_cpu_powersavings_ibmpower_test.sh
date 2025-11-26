#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
[[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
readonly PROGRAM_DIR

#mock PREREQUISITE functions
LIB_FUNC_IS_IBMPOWER() { return 0 ; }

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

# Variables to mock
# LIB_PLATF_POWER_POWERMODE=
# LIB_PLATF_POWER_PLATFORM_BASE=
# RETURN_POWER_POWERMODE=

# ========================================
# PRECONDITION TESTS
# ========================================

test_precondition_not_ibmpower_skipped() {

    #arrange
    LIB_FUNC_IS_IBMPOWER() { return 1 ; }
    LIB_PLATF_POWER_PLATFORM_BASE='POWER10'
    LIB_PLATF_POWER_POWERMODE='0002000200020002'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    assertEquals "CheckSkipped? RC" '3' "$?"

    #cleanup
    # shellcheck disable=SC2329
    LIB_FUNC_IS_IBMPOWER() { return 0 ; }
}

test_precondition_powermode_unknown() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER10'
    LIB_PLATF_POWER_POWERMODE=

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

# ========================================
# POWER11 TESTS
# ========================================

test_power11_maximum_performance_ok() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER11'
    LIB_PLATF_POWER_POWERMODE='0001000100010001'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_power11_maximum_performance_system_diff_partition_ok() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER11'
    LIB_PLATF_POWER_POWERMODE='0001000100010002'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_power11_none_error() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER11'
    LIB_PLATF_POWER_POWERMODE='0002000200020002'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_power11_static_error() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER11'
    LIB_PLATF_POWER_POWERMODE='0003000300030003'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_power11_dynamic_performance_error() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER11'
    LIB_PLATF_POWER_POWERMODE='0004000400040004'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_power11_unknown_mode_error() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER11'
    LIB_PLATF_POWER_POWERMODE='00ff00ff00ff00ff'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

# ========================================
# POWER10 TESTS
# ========================================

test_power10_maximum_performance_ok() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER10'
    LIB_PLATF_POWER_POWERMODE='0001000100010001'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_power10_none_ok() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER10'
    LIB_PLATF_POWER_POWERMODE='0002000200020002'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_power10_dynamic_performance_ok() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER10'
    LIB_PLATF_POWER_POWERMODE='0004000400040004'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_power10_static_error() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER10'
    LIB_PLATF_POWER_POWERMODE='0003000300030003'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_power10_unknown_mode_error() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER10'
    LIB_PLATF_POWER_POWERMODE='00ff00ff00ff00ff'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_power10_system_partition_mode_diff_ok() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER10'
    LIB_PLATF_POWER_POWERMODE='0001000100010002'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

# ========================================
# POWER9 TESTS
# ========================================

test_power9_maximum_performance_ok() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'
    LIB_PLATF_POWER_POWERMODE='0001000100010001'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_power9_none_ok() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'
    LIB_PLATF_POWER_POWERMODE='0002000200020002'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_power9_dynamic_performance_ok() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'
    LIB_PLATF_POWER_POWERMODE='0004000400040004'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_power9_static_error() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'
    LIB_PLATF_POWER_POWERMODE='0003000300030003'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_power9_unknown_mode_error() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'
    LIB_PLATF_POWER_POWERMODE='00ff00ff00ff00ff'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_power9_system_partition_mode_diff_ok() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'
    LIB_PLATF_POWER_POWERMODE='0001000100010004'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

# ========================================
# EDGE CASE TESTS
# ========================================

test_real_world_mixed_mode_power10() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER10'
    LIB_PLATF_POWER_POWERMODE='0002000200020004'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_real_world_mixed_mode_power9() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'
    LIB_PLATF_POWER_POWERMODE='0004000400040002'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_system_mode_invalid_partition_valid_power10() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER10'
    LIB_PLATF_POWER_POWERMODE='0003000300030001'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_system_mode_valid_partition_invalid_power11() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER11'
    LIB_PLATF_POWER_POWERMODE='0001000100010003'

    #act
    check_1310_cpu_powersavings_ibmpower

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

# ========================================
# SETUP AND TEARDOWN
# ========================================

oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/1310_cpu_powersavings_ibmpower.check
    source "${PROGRAM_DIR}/../../lib/check/1310_cpu_powersavings_ibmpower.check"

}

# oneTimeTearDown

setUp() {

    LIB_PLATF_POWER_POWERMODE=
    LIB_PLATF_POWER_PLATFORM_BASE=
    RETURN_POWER_POWERMODE=

}

# tearDown

#Import Libraries
# - order is important - sourcing shunit triggers testing
# - that's also the reason, why it could not be done during oneTimeSetup

#Load and run shUnit2
#shellcheck source=../shunit2
source "${PROGRAM_DIR}/../shunit2"

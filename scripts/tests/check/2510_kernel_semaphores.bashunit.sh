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
path_to_kernel_sem=''

# Mock functions
LIB_FUNC_IS_RHEL() { return 1 ; }


function test_recommended_values() {

    #arrange
    echo "32000 1024000000 500 32000" > "${PROGRAM_DIR}/mock_kernel_sem"
    path_to_kernel_sem="${PROGRAM_DIR}/mock_kernel_sem"

    #act
    check_2510_kernel_semaphores

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for recommended values"
    fi
}

function test_semmsl_too_low() {

    #arrange
    echo "16000 1024000000 500 32000" > "${PROGRAM_DIR}/mock_kernel_sem"
    path_to_kernel_sem="${PROGRAM_DIR}/mock_kernel_sem"

    #act
    check_2510_kernel_semaphores

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for SEMMSL too low"
    fi
}

function test_semmns_too_low() {

    #arrange
    echo "32000 512000000 500 32000" > "${PROGRAM_DIR}/mock_kernel_sem"
    path_to_kernel_sem="${PROGRAM_DIR}/mock_kernel_sem"

    #act
    check_2510_kernel_semaphores

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for SEMMNS too low"
    fi
}

function test_semopm_too_low() {

    #arrange
    echo "32000 1024000000 250 32000" > "${PROGRAM_DIR}/mock_kernel_sem"
    path_to_kernel_sem="${PROGRAM_DIR}/mock_kernel_sem"

    #act
    check_2510_kernel_semaphores

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for SEMOPM too low"
    fi
}

function test_semmni_too_low() {

    #arrange
    echo "32000 1024000000 500 16000" > "${PROGRAM_DIR}/mock_kernel_sem"
    path_to_kernel_sem="${PROGRAM_DIR}/mock_kernel_sem"

    #act
    check_2510_kernel_semaphores

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for SEMMNI too low"
    fi
}

function test_multiple_values_too_low() {

    #arrange
    echo "16000 512000000 250 16000" > "${PROGRAM_DIR}/mock_kernel_sem"
    path_to_kernel_sem="${PROGRAM_DIR}/mock_kernel_sem"

    #act
    check_2510_kernel_semaphores

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for multiple values too low"
    fi
}

function test_all_values_higher_than_recommended() {

    #arrange
    echo "64000 2048000000 1000 64000" > "${PROGRAM_DIR}/mock_kernel_sem"
    path_to_kernel_sem="${PROGRAM_DIR}/mock_kernel_sem"

    #act
    check_2510_kernel_semaphores

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for all values higher than recommended"
    fi
}

function test_semmsl_higher() {

    #arrange
    echo "64000 1024000000 500 32000" > "${PROGRAM_DIR}/mock_kernel_sem"
    path_to_kernel_sem="${PROGRAM_DIR}/mock_kernel_sem"

    #act
    check_2510_kernel_semaphores

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for SEMMSL higher"
    fi
}

function test_semmns_higher() {

    #arrange
    echo "32000 2048000000 500 32000" > "${PROGRAM_DIR}/mock_kernel_sem"
    path_to_kernel_sem="${PROGRAM_DIR}/mock_kernel_sem"

    #act
    check_2510_kernel_semaphores

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for SEMMNS higher"
    fi
}

function test_mixed_some_low_some_ok() {

    #arrange
    echo "32000 512000000 500 16000" > "${PROGRAM_DIR}/mock_kernel_sem"
    path_to_kernel_sem="${PROGRAM_DIR}/mock_kernel_sem"

    #act
    check_2510_kernel_semaphores

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for mixed some low some ok"
    fi
}

function test_insufficient_parameters() {

    #arrange
    echo "32000 1024000000 500" > "${PROGRAM_DIR}/mock_kernel_sem"
    path_to_kernel_sem="${PROGRAM_DIR}/mock_kernel_sem"

    #act
    check_2510_kernel_semaphores

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for insufficient parameters"
    fi
}

function test_boundary_values_exact_match() {

    #arrange
    echo "32000 1024000000 500 32000" > "${PROGRAM_DIR}/mock_kernel_sem"
    path_to_kernel_sem="${PROGRAM_DIR}/mock_kernel_sem"

    #act
    check_2510_kernel_semaphores

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for boundary values exact match"
    fi
}

function test_boundary_values_one_above() {

    #arrange
    echo "32001 1024000001 501 32001" > "${PROGRAM_DIR}/mock_kernel_sem"
    path_to_kernel_sem="${PROGRAM_DIR}/mock_kernel_sem"

    #act
    check_2510_kernel_semaphores

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for boundary values one above"
    fi
}

function test_boundary_values_one_below() {

    #arrange
    echo "31999 1023999999 499 31999" > "${PROGRAM_DIR}/mock_kernel_sem"
    path_to_kernel_sem="${PROGRAM_DIR}/mock_kernel_sem"

    #act
    check_2510_kernel_semaphores

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for boundary values one below"
    fi
}


function set_up_before_script() {

    # Disable errexit - bashunit enables it but sourced files may return non-zero
    set +eE

    # Skip if already loaded (bashunit runs all tests in same session)
    [[ -n "${_2510_test_loaded:-}" ]] && return 0
    _2510_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/2510_kernel_semaphores.check
    source "${PROGRAM_DIR}/../../lib/check/2510_kernel_semaphores.check"

}

function set_up() {

    # Default path - can be overridden by individual tests
    path_to_kernel_sem="/proc/sys/kernel/sem"
    echo "32000 1024000000 500 32000" > "${PROGRAM_DIR}/mock_kernel_sem"

}

function tear_down() {

    rm -f "${PROGRAM_DIR}/mock_kernel_sem"

}

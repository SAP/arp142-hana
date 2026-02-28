#!/usr/bin/env bash
#------------------------------------------------------------------
# bashunit tests for check_3020_tcp_window_scaling
#------------------------------------------------------------------
set -u

if [[ -z "${PROGRAM_DIR:-}" ]]; then
    PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
    [[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
fi

# Guard to prevent double-loading
[[ -n "${_3020_tcp_window_scaling_test_loaded:-}" ]] && return 0
_3020_tcp_window_scaling_test_loaded=true

# Mock variables
mock_tcp_window_scaling=1
mock_tcp_rmem="4096    87380   16777216"
mock_tcp_wmem="4096    16384   16777216"
mock_rmem_max=16777216
mock_wmem_max=16777216

# Create mock proc directory structure
create_mock_files() {
    mkdir -p "${PROGRAM_DIR}/mock_proc/sys/net/ipv4"
    mkdir -p "${PROGRAM_DIR}/mock_proc/sys/net/core"
    echo "${mock_tcp_window_scaling}" > "${PROGRAM_DIR}/mock_proc/sys/net/ipv4/tcp_window_scaling"
    echo "${mock_tcp_rmem}" > "${PROGRAM_DIR}/mock_proc/sys/net/ipv4/tcp_rmem"
    echo "${mock_tcp_wmem}" > "${PROGRAM_DIR}/mock_proc/sys/net/ipv4/tcp_wmem"
    echo "${mock_rmem_max}" > "${PROGRAM_DIR}/mock_proc/sys/net/core/rmem_max"
    echo "${mock_wmem_max}" > "${PROGRAM_DIR}/mock_proc/sys/net/core/wmem_max"
}

setup_test() {
    create_mock_files
    export path_to_tcp_window_scaling="${PROGRAM_DIR}/mock_proc/sys/net/ipv4/tcp_window_scaling"
    export path_to_tcp_rmem="${PROGRAM_DIR}/mock_proc/sys/net/ipv4/tcp_rmem"
    export path_to_tcp_wmem="${PROGRAM_DIR}/mock_proc/sys/net/ipv4/tcp_wmem"
    export path_to_rmem_max="${PROGRAM_DIR}/mock_proc/sys/net/core/rmem_max"
    export path_to_wmem_max="${PROGRAM_DIR}/mock_proc/sys/net/core/wmem_max"
}

function set_up_before_script() {
    set +eE
    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"
    #shellcheck source=../../lib/check/3020_tcp_window_scaling.check
    source "${PROGRAM_DIR}/../../lib/check/3020_tcp_window_scaling.check"
}

function set_up() {
    # Reset mock variables to good defaults
    mock_tcp_window_scaling=1
    mock_tcp_rmem="4096    87380   16777216"
    mock_tcp_wmem="4096    16384   16777216"
    mock_rmem_max=16777216
    mock_wmem_max=16777216
}

function tear_down_after_script() {
    rm -rf "${PROGRAM_DIR}/mock_proc"
}

#------------------------------------------------------------------
# Test: All values correct - should return RC=0
#------------------------------------------------------------------
function test_all_values_correct() {
    #arrange
    mock_tcp_window_scaling=1
    mock_tcp_rmem="4096    87380   16777216"
    mock_tcp_wmem="4096    16384   16777216"
    mock_rmem_max=16777216
    mock_wmem_max=16777216
    setup_test

    #act
    check_3020_tcp_window_scaling
    local rc=$?

    #assert
    if [[ ${rc} -ne 0 ]]; then
        bashunit::fail "Expected RC=0 for all correct values, got RC=${rc}"
    fi
}

#------------------------------------------------------------------
# Test: tcp_window_scaling disabled - should return RC=2
#------------------------------------------------------------------
function test_window_scaling_disabled() {
    #arrange
    mock_tcp_window_scaling=0
    mock_tcp_rmem="4096    87380   16777216"
    mock_tcp_wmem="4096    16384   16777216"
    mock_rmem_max=16777216
    mock_wmem_max=16777216
    setup_test

    #act
    check_3020_tcp_window_scaling
    local rc=$?

    #assert
    if [[ ${rc} -ne 2 ]]; then
        bashunit::fail "Expected RC=2 for window_scaling disabled, got RC=${rc}"
    fi
}

#------------------------------------------------------------------
# Test: tcp_rmem max too low - should return RC=2
#------------------------------------------------------------------
function test_tcp_rmem_max_too_low() {
    #arrange
    mock_tcp_window_scaling=1
    mock_tcp_rmem="4096    87380   6291456"    # max is 6291456 < 16777216
    mock_tcp_wmem="4096    16384   16777216"
    mock_rmem_max=16777216
    mock_wmem_max=16777216
    setup_test

    #act
    check_3020_tcp_window_scaling
    local rc=$?

    #assert
    if [[ ${rc} -ne 2 ]]; then
        bashunit::fail "Expected RC=2 for tcp_rmem max too low, got RC=${rc}"
    fi
}

#------------------------------------------------------------------
# Test: tcp_wmem max too low - should return RC=2
#------------------------------------------------------------------
function test_tcp_wmem_max_too_low() {
    #arrange
    mock_tcp_window_scaling=1
    mock_tcp_rmem="4096    87380   16777216"
    mock_tcp_wmem="4096    16384   4194304"    # max is 4194304 < 16777216
    mock_rmem_max=16777216
    mock_wmem_max=16777216
    setup_test

    #act
    check_3020_tcp_window_scaling
    local rc=$?

    #assert
    if [[ ${rc} -ne 2 ]]; then
        bashunit::fail "Expected RC=2 for tcp_wmem max too low, got RC=${rc}"
    fi
}

#------------------------------------------------------------------
# Test: core rmem_max too low - should return RC=2
#------------------------------------------------------------------
function test_core_rmem_max_too_low() {
    #arrange
    mock_tcp_window_scaling=1
    mock_tcp_rmem="4096    87380   16777216"
    mock_tcp_wmem="4096    16384   16777216"
    mock_rmem_max=212992    # too low
    mock_wmem_max=16777216
    setup_test

    #act
    check_3020_tcp_window_scaling
    local rc=$?

    #assert
    if [[ ${rc} -ne 2 ]]; then
        bashunit::fail "Expected RC=2 for core rmem_max too low, got RC=${rc}"
    fi
}

#------------------------------------------------------------------
# Test: core wmem_max too low - should return RC=2
#------------------------------------------------------------------
function test_core_wmem_max_too_low() {
    #arrange
    mock_tcp_window_scaling=1
    mock_tcp_rmem="4096    87380   16777216"
    mock_tcp_wmem="4096    16384   16777216"
    mock_rmem_max=16777216
    mock_wmem_max=212992    # too low
    setup_test

    #act
    check_3020_tcp_window_scaling
    local rc=$?

    #assert
    if [[ ${rc} -ne 2 ]]; then
        bashunit::fail "Expected RC=2 for core wmem_max too low, got RC=${rc}"
    fi
}

#------------------------------------------------------------------
# Test: Values higher than recommended - should return RC=0
#------------------------------------------------------------------
function test_values_higher_than_recommended() {
    #arrange
    mock_tcp_window_scaling=1
    mock_tcp_rmem="4096    87380   33554432"   # higher than 16777216
    mock_tcp_wmem="4096    16384   33554432"   # higher than 16777216
    mock_rmem_max=33554432
    mock_wmem_max=33554432
    setup_test

    #act
    check_3020_tcp_window_scaling
    local rc=$?

    #assert
    if [[ ${rc} -ne 0 ]]; then
        bashunit::fail "Expected RC=0 for values higher than recommended, got RC=${rc}"
    fi
}

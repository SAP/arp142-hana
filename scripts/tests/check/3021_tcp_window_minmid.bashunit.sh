#!/usr/bin/env bash
#------------------------------------------------------------------
# bashunit tests for check_3021_tcp_window_minmid
#------------------------------------------------------------------
set -u

if [[ -z "${PROGRAM_DIR:-}" ]]; then
    PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
    [[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
fi

# Guard to prevent double-loading
[[ -n "${_3021_tcp_window_minmid_test_loaded:-}" ]] && return 0
_3021_tcp_window_minmid_test_loaded=true

# Mock variables
mock_tcp_rmem="4096    131072   16777216"
mock_tcp_wmem="4096    16384   16777216"
OS_LEVEL="5.4.0-default"
is_ibmpower=1
LIB_FUNC_NORMALIZE_KERNEL_RETURN=""

# Mock functions
LIB_FUNC_IS_IBMPOWER() { return ${is_ibmpower}; }
LIB_FUNC_NORMALIZE_KERNEL() { LIB_FUNC_NORMALIZE_KERNEL_RETURN="${1%%-*}"; }
LIB_FUNC_COMPARE_VERSIONS() {
    # Simplified version comparison: returns 0 if equal, 1 if first higher, 2 if second higher
    local v1="$1" v2="$2"
    if [[ "$v1" == "$v2" ]]; then return 0; fi
    local higher
    higher=$(printf '%s\n%s' "$v1" "$v2" | sort -V | tail -1)
    if [[ "$higher" == "$v1" ]]; then return 1; else return 2; fi
}

# Create mock proc directory structure
create_mock_files() {
    mkdir -p "${PROGRAM_DIR}/mock_proc/sys/net/ipv4"
    echo "${mock_tcp_rmem}" > "${PROGRAM_DIR}/mock_proc/sys/net/ipv4/tcp_rmem"
    echo "${mock_tcp_wmem}" > "${PROGRAM_DIR}/mock_proc/sys/net/ipv4/tcp_wmem"
}

setup_test() {
    create_mock_files
    export path_to_tcp_rmem="${PROGRAM_DIR}/mock_proc/sys/net/ipv4/tcp_rmem"
    export path_to_tcp_wmem="${PROGRAM_DIR}/mock_proc/sys/net/ipv4/tcp_wmem"
    export OS_LEVEL
}

function set_up_before_script() {
    set +eE
    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"
    #shellcheck source=../../lib/check/3021_tcp_window_minmid.check
    source "${PROGRAM_DIR}/../../lib/check/3021_tcp_window_minmid.check"
}

function set_up() {
    # Reset mock variables to good defaults for modern kernel on Intel
    mock_tcp_rmem="4096    131072   16777216"
    mock_tcp_wmem="4096    16384   16777216"
    OS_LEVEL="5.4.0-default"
    is_ibmpower=1    # 1 = not IBM Power (return failure)
}

function tear_down_after_script() {
    rm -rf "${PROGRAM_DIR}/mock_proc"
}

#------------------------------------------------------------------
# Test: Modern kernel with correct MIN/MID values - should return RC=0
#------------------------------------------------------------------
function test_modern_kernel_correct_values() {
    #arrange
    OS_LEVEL="5.4.0-default"    # kernel >= 4.20
    mock_tcp_rmem="4096    131072   16777216"   # MIN=4096, MID=131072
    mock_tcp_wmem="4096    16384   16777216"    # MIN=4096, MID=16384
    is_ibmpower=1
    setup_test

    #act
    check_3021_tcp_window_minmid
    local rc=$?

    #assert
    if [[ ${rc} -ne 0 ]]; then
        bashunit::fail "Expected RC=0 for modern kernel with correct values, got RC=${rc}"
    fi
}

#------------------------------------------------------------------
# Test: Older kernel (< 4.20) with correct MIN/MID values - should return RC=0
#------------------------------------------------------------------
function test_older_kernel_correct_values() {
    #arrange
    OS_LEVEL="4.12.0-default"   # kernel < 4.20
    mock_tcp_rmem="4096    87380   16777216"    # MIN=4096, MID=87380 (old default)
    mock_tcp_wmem="4096    16384   16777216"    # MIN=4096, MID=16384
    is_ibmpower=1
    setup_test

    #act
    check_3021_tcp_window_minmid
    local rc=$?

    #assert
    if [[ ${rc} -ne 0 ]]; then
        bashunit::fail "Expected RC=0 for older kernel with correct values, got RC=${rc}"
    fi
}

#------------------------------------------------------------------
# Test: Wrong rmem MIN/MID values - should return RC=1
#------------------------------------------------------------------
function test_wrong_rmem_minmid() {
    #arrange
    OS_LEVEL="5.4.0-default"
    mock_tcp_rmem="8192    65536   16777216"    # Wrong MIN and MID
    mock_tcp_wmem="4096    16384   16777216"
    is_ibmpower=1
    setup_test

    #act
    check_3021_tcp_window_minmid
    local rc=$?

    #assert
    if [[ ${rc} -ne 1 ]]; then
        bashunit::fail "Expected RC=1 for wrong rmem MIN/MID, got RC=${rc}"
    fi
}

#------------------------------------------------------------------
# Test: Wrong wmem MIN/MID values - should return RC=1
#------------------------------------------------------------------
function test_wrong_wmem_minmid() {
    #arrange
    OS_LEVEL="5.4.0-default"
    mock_tcp_rmem="4096    131072   16777216"
    mock_tcp_wmem="8192    32768   16777216"    # Wrong MIN and MID
    is_ibmpower=1
    setup_test

    #act
    check_3021_tcp_window_minmid
    local rc=$?

    #assert
    if [[ ${rc} -ne 1 ]]; then
        bashunit::fail "Expected RC=1 for wrong wmem MIN/MID, got RC=${rc}"
    fi
}

#------------------------------------------------------------------
# Test: IBM Power old kernel (< 4.10) with 64K page size values
#------------------------------------------------------------------
function test_ibmpower_old_kernel_correct_values() {
    #arrange
    OS_LEVEL="4.4.0-default"    # kernel < 4.10
    mock_tcp_rmem="65536    87380   16777216"   # 64K page size MIN
    mock_tcp_wmem="65536    16384   16777216"   # 64K page size MIN
    is_ibmpower=0    # 0 = is IBM Power
    setup_test

    #act
    check_3021_tcp_window_minmid
    local rc=$?

    #assert
    if [[ ${rc} -ne 0 ]]; then
        bashunit::fail "Expected RC=0 for IBM Power old kernel with 64K page values, got RC=${rc}"
    fi
}

#------------------------------------------------------------------
# Test: IBM Power modern kernel with standard values
#------------------------------------------------------------------
function test_ibmpower_modern_kernel_correct_values() {
    #arrange
    OS_LEVEL="5.4.0-default"    # kernel >= 4.20
    mock_tcp_rmem="4096    131072   16777216"
    mock_tcp_wmem="4096    16384   16777216"
    is_ibmpower=0    # 0 = is IBM Power
    setup_test

    #act
    check_3021_tcp_window_minmid
    local rc=$?

    #assert
    if [[ ${rc} -ne 0 ]]; then
        bashunit::fail "Expected RC=0 for IBM Power modern kernel with standard values, got RC=${rc}"
    fi
}

#------------------------------------------------------------------
# Test: Both rmem and wmem wrong - should return RC=1
#------------------------------------------------------------------
function test_both_minmid_wrong() {
    #arrange
    OS_LEVEL="5.4.0-default"
    mock_tcp_rmem="8192    65536   16777216"    # Wrong
    mock_tcp_wmem="8192    32768   16777216"    # Wrong
    is_ibmpower=1
    setup_test

    #act
    check_3021_tcp_window_minmid
    local rc=$?

    #assert
    if [[ ${rc} -ne 1 ]]; then
        bashunit::fail "Expected RC=1 for both MIN/MID wrong, got RC=${rc}"
    fi
}

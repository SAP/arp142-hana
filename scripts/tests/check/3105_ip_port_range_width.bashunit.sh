#!/usr/bin/env bash
#------------------------------------------------------------------
# bashunit tests for check_3105_ip_port_range_width
#
# Check logic: net.ipv4.ip_local_port_range width (upper - lower)
# must be >= 40000 to pass.
#------------------------------------------------------------------
set -u

if [[ -z "${PROGRAM_DIR:-}" ]]; then
    PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
    [[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
fi

# Mock variables
mock_port_range='40000 64999'

# Helper: write mock file and export path
setup_test() {
    mkdir -p "${PROGRAM_DIR}/mock_proc/sys/net/ipv4"
    echo "${mock_port_range}" > "${PROGRAM_DIR}/mock_proc/sys/net/ipv4/ip_local_port_range"
    export path_to_ip_local_port_range="${PROGRAM_DIR}/mock_proc/sys/net/ipv4/ip_local_port_range"
}

assert_check_processed() {
    local rc=$1
    local context="${2:-}"
    if [[ ${rc} -eq 99 ]]; then
        bashunit::fail "RC=99 (unprocessed) - check logic did not reach a conclusion${context:+ in }${context}"
    fi
}

function test_range_width_exactly_40000_passes() {
    #arrange  lower=10000 upper=50000  width=40000
    mock_port_range='10000 50000'
    setup_test

    #act
    check_3105_ip_port_range_width
    local rc=$?

    #assert
    assert_check_processed ${rc} "width exactly 40000"
    if [[ ${rc} -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for width=40000, got RC=${rc}"
    fi
    assert_true true
}

function test_range_width_above_40000_passes() {
    #arrange  lower=32768 upper=60999  width=28231 -- wait, 60999-32768=28231 < 40000
    # Use lower=20000 upper=65000 width=45000
    mock_port_range='20000 65000'
    setup_test

    #act
    check_3105_ip_port_range_width
    local rc=$?

    #assert
    assert_check_processed ${rc} "width 45000 > 40000"
    if [[ ${rc} -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for width=45000, got RC=${rc}"
    fi
    assert_true true
}

function test_typical_sap_range_9000_65499_passes() {
    #arrange  lower=9000 upper=65499  width=56499 >= 40000
    mock_port_range='9000 65499'
    setup_test

    #act
    check_3105_ip_port_range_width
    local rc=$?

    #assert
    assert_check_processed ${rc} "SAP recommended range 9000-65499"
    if [[ ${rc} -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for SAP recommended range 9000-65499 (width=56499), got RC=${rc}"
    fi
    assert_true true
}

function test_range_width_below_40000_warns() {
    #arrange  lower=32768 upper=60999  width=28231 < 40000
    mock_port_range='32768 60999'
    setup_test

    #act
    check_3105_ip_port_range_width
    local rc=$?

    #assert
    assert_check_processed ${rc} "width 28231 < 40000"
    if [[ ${rc} -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for width=28231, got RC=${rc}"
    fi
    assert_true true
}

function test_range_width_just_under_40000_warns() {
    #arrange  lower=0 upper=39999  width=39999 < 40000
    mock_port_range='0 39999'
    setup_test

    #act
    check_3105_ip_port_range_width
    local rc=$?

    #assert
    assert_check_processed ${rc} "width 39999 just under 40000"
    if [[ ${rc} -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for width=39999, got RC=${rc}"
    fi
    assert_true true
}

function test_default_linux_range_32768_60999_warns() {
    #arrange  Linux default: lower=32768 upper=60999  width=28231 < 40000
    mock_port_range='32768	60999'
    setup_test

    #act
    check_3105_ip_port_range_width
    local rc=$?

    #assert
    assert_check_processed ${rc} "Linux default range 32768-60999"
    if [[ ${rc} -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for Linux default range 32768-60999 (width=28231), got RC=${rc}"
    fi
    assert_true true
}

function set_up_before_script() {
    set +eE

    [[ -n "${_3105_test_loaded:-}" ]] && return 0
    _3105_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/3105_ip_port_range_width.check
    source "${PROGRAM_DIR}/../../lib/check/3105_ip_port_range_width.check"
}

function set_up() {
    mock_port_range='40000 64999'
    unset path_to_ip_local_port_range
}

function tear_down_after_script() {
    rm -f "${PROGRAM_DIR}/mock_proc/sys/net/ipv4/ip_local_port_range"
}

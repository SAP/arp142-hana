#!/usr/bin/env bash
#------------------------------------------------------------------
# bashunit test for check_3411_network_tuning_azure
#------------------------------------------------------------------
set -u

if [[ -z "${PROGRAM_DIR:-}" ]]; then
    PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
    [[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
fi

# CRITICAL: Use a test-specific guard variable
[[ -n "${_3411_network_tuning_azure_test_loaded:-}" ]] && return 0
_3411_network_tuning_azure_test_loaded=true

# Mock functions
LIB_FUNC_IS_CLOUD_MICROSOFT() { return 0 ; }


function set_up_before_script() {

    set +eE

    [[ -n "${_3411_test_sourced:-}" ]] && return 0
    _3411_test_sourced=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/3411_network_tuning_azure.check
    source "${PROGRAM_DIR}/../../lib/check/3411_network_tuning_azure.check"
}

function set_up() {
    LIB_FUNC_IS_CLOUD_MICROSOFT() { return 0 ; }

    # Override paths for testing using temp files
    path_to_tcp_congestion_control="${PROGRAM_DIR}/.tmp_tcp_congestion_control"
    path_to_default_qdisc="${PROGRAM_DIR}/.tmp_default_qdisc"
    path_to_tcp_frto="${PROGRAM_DIR}/.tmp_tcp_frto"
    path_to_netdev_budget="${PROGRAM_DIR}/.tmp_netdev_budget"

    echo -n "bbr" > "${path_to_tcp_congestion_control}"
    echo -n "fq" > "${path_to_default_qdisc}"
    echo -n "0" > "${path_to_tcp_frto}"
    echo -n "1000" > "${path_to_netdev_budget}"
}

function tear_down() {
    rm -f "${PROGRAM_DIR}/.tmp_tcp_congestion_control" \
          "${PROGRAM_DIR}/.tmp_default_qdisc" \
          "${PROGRAM_DIR}/.tmp_tcp_frto" \
          "${PROGRAM_DIR}/.tmp_netdev_budget"
}

function test_all_ok() {

    #act
    check_3411_network_tuning_azure
    local rc=$?

    #assert
    if [[ ${rc} -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok), got RC=${rc}"
    fi
    assert_true true
}

function test_wrong_congestion_control_warning() {

    #arrange
    echo -n "cubic" > "${path_to_tcp_congestion_control}"

    #act
    check_3411_network_tuning_azure
    local rc=$?

    #assert
    if [[ ${rc} -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning), got RC=${rc}"
    fi
    assert_true true
}

function test_wrong_qdisc_warning() {

    #arrange
    echo -n "pfifo_fast" > "${path_to_default_qdisc}"

    #act
    check_3411_network_tuning_azure
    local rc=$?

    #assert
    if [[ ${rc} -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning), got RC=${rc}"
    fi
    assert_true true
}

function test_wrong_tcp_frto_warning() {

    #arrange
    echo -n "2" > "${path_to_tcp_frto}"

    #act
    check_3411_network_tuning_azure
    local rc=$?

    #assert
    if [[ ${rc} -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning), got RC=${rc}"
    fi
    assert_true true
}

function test_wrong_netdev_budget_warning() {

    #arrange
    echo -n "300" > "${path_to_netdev_budget}"

    #act
    check_3411_network_tuning_azure
    local rc=$?

    #assert
    if [[ ${rc} -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning), got RC=${rc}"
    fi
    assert_true true
}

function test_netdev_budget_higher_ok() {

    #arrange
    echo -n "2000" > "${path_to_netdev_budget}"

    #act
    check_3411_network_tuning_azure
    local rc=$?

    #assert
    if [[ ${rc} -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for netdev_budget >= recommended, got RC=${rc}"
    fi
    assert_true true
}

function test_not_azure_skip() {

    #arrange
    LIB_FUNC_IS_CLOUD_MICROSOFT() { return 1 ; }

    #act
    check_3411_network_tuning_azure
    local rc=$?

    #assert
    if [[ ${rc} -ne 3 ]]; then
        bashunit::fail "Expected RC=3 (skip) for non-Azure, got RC=${rc}"
    fi
    assert_true true
}

function test_all_wrong_warning() {

    #arrange
    echo -n "cubic" > "${path_to_tcp_congestion_control}"
    echo -n "pfifo_fast" > "${path_to_default_qdisc}"
    echo -n "2" > "${path_to_tcp_frto}"
    echo -n "300" > "${path_to_netdev_budget}"

    #act
    check_3411_network_tuning_azure
    local rc=$?

    #assert
    if [[ ${rc} -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) when all settings are wrong, got RC=${rc}"
    fi
    assert_true true
}

#!/usr/bin/env bash
#------------------------------------------------------------------
# bashunit migration: 5210_io_nvme_parameter_hyperscaler_test.sh
# Tests for NVMe I/O timeout parameter check on hyperscalers
#------------------------------------------------------------------
set -u

if [[ -z "${PROGRAM_DIR:-}" ]]; then
    PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
    [[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
fi

# Guard to avoid reloading
[[ -n "${_5210_io_nvme_test_loaded:-}" ]] && return 0
_5210_io_nvme_test_loaded=true

# Variables to control cloud platform simulation
is_amazon_cloud=1
is_microsoft_cloud=1

#mock PREREQUISITE functions
LIB_FUNC_IS_CLOUD_AMAZON() { return ${is_amazon_cloud} ; }
LIB_FUNC_IS_CLOUD_MICROSOFT() { return ${is_microsoft_cloud} ; }

function test_not_on_hyperscaler() {
    #arrange
    is_amazon_cloud=1
    is_microsoft_cloud=1

    #act
    check_5210_io_nvme_parameter_hyperscaler
    local rc=$?

    #assert
    if [[ "$rc" != '3' ]]; then
        bashunit::fail "Expected CheckSkip RC=3 but got RC=$rc"
    fi
}

function test_on_amazon_cloud() {
    #arrange
    is_amazon_cloud=0
    is_microsoft_cloud=1
    echo "240" > "${PROGRAM_DIR}/mock_nvme_timeout_5210"
    path_to_nvme_timeout="${PROGRAM_DIR}/mock_nvme_timeout_5210"

    #act
    check_5210_io_nvme_parameter_hyperscaler
    local rc=$?

    #assert
    if [[ "$rc" != '0' ]]; then
        bashunit::fail "Expected CheckOk RC=0 but got RC=$rc"
    fi
}

function test_on_microsoft_cloud() {
    #arrange
    is_amazon_cloud=1
    is_microsoft_cloud=0
    echo "240" > "${PROGRAM_DIR}/mock_nvme_timeout_5210"
    path_to_nvme_timeout="${PROGRAM_DIR}/mock_nvme_timeout_5210"

    #act
    check_5210_io_nvme_parameter_hyperscaler
    local rc=$?

    #assert
    if [[ "$rc" != '0' ]]; then
        bashunit::fail "Expected CheckOk RC=0 but got RC=$rc"
    fi
}

function test_nvme_timeout_file_not_found() {
    #arrange
    is_amazon_cloud=0
    is_microsoft_cloud=1
    path_to_nvme_timeout="${PROGRAM_DIR}/nonexistent_nvme_timeout"

    #act
    check_5210_io_nvme_parameter_hyperscaler
    local rc=$?

    #assert
    if [[ "$rc" != '3' ]]; then
        bashunit::fail "Expected CheckSkip RC=3 but got RC=$rc"
    fi
}

function test_recommended_value_exact_match() {
    #arrange
    is_amazon_cloud=0
    is_microsoft_cloud=1
    echo "240" > "${PROGRAM_DIR}/mock_nvme_timeout_5210"
    path_to_nvme_timeout="${PROGRAM_DIR}/mock_nvme_timeout_5210"

    #act
    check_5210_io_nvme_parameter_hyperscaler
    local rc=$?

    #assert
    if [[ "$rc" != '0' ]]; then
        bashunit::fail "Expected CheckOk RC=0 but got RC=$rc"
    fi
}

function test_value_higher_than_recommended() {
    #arrange
    is_amazon_cloud=0
    is_microsoft_cloud=1
    echo "300" > "${PROGRAM_DIR}/mock_nvme_timeout_5210"
    path_to_nvme_timeout="${PROGRAM_DIR}/mock_nvme_timeout_5210"

    #act
    check_5210_io_nvme_parameter_hyperscaler
    local rc=$?

    #assert
    if [[ "$rc" != '0' ]]; then
        bashunit::fail "Expected CheckOk RC=0 but got RC=$rc"
    fi
}

function test_value_lower_than_recommended() {
    #arrange
    is_amazon_cloud=0
    is_microsoft_cloud=1
    echo "200" > "${PROGRAM_DIR}/mock_nvme_timeout_5210"
    path_to_nvme_timeout="${PROGRAM_DIR}/mock_nvme_timeout_5210"

    #act
    check_5210_io_nvme_parameter_hyperscaler
    local rc=$?

    #assert
    if [[ "$rc" != '2' ]]; then
        bashunit::fail "Expected CheckError RC=2 but got RC=$rc"
    fi
}

function test_boundary_value_one_below() {
    #arrange
    is_amazon_cloud=0
    is_microsoft_cloud=1
    echo "239" > "${PROGRAM_DIR}/mock_nvme_timeout_5210"
    path_to_nvme_timeout="${PROGRAM_DIR}/mock_nvme_timeout_5210"

    #act
    check_5210_io_nvme_parameter_hyperscaler
    local rc=$?

    #assert
    if [[ "$rc" != '2' ]]; then
        bashunit::fail "Expected CheckError RC=2 but got RC=$rc"
    fi
}

function test_boundary_value_one_above() {
    #arrange
    is_amazon_cloud=0
    is_microsoft_cloud=1
    echo "241" > "${PROGRAM_DIR}/mock_nvme_timeout_5210"
    path_to_nvme_timeout="${PROGRAM_DIR}/mock_nvme_timeout_5210"

    #act
    check_5210_io_nvme_parameter_hyperscaler
    local rc=$?

    #assert
    if [[ "$rc" != '0' ]]; then
        bashunit::fail "Expected CheckOk RC=0 but got RC=$rc"
    fi
}

function test_empty_file() {
    #arrange
    is_amazon_cloud=0
    is_microsoft_cloud=1
    echo "" > "${PROGRAM_DIR}/mock_nvme_timeout_5210"
    path_to_nvme_timeout="${PROGRAM_DIR}/mock_nvme_timeout_5210"

    #act
    check_5210_io_nvme_parameter_hyperscaler
    local rc=$?

    #assert
    if [[ "$rc" != '2' ]]; then
        bashunit::fail "Expected CheckError RC=2 but got RC=$rc"
    fi
}

function test_zero_value() {
    #arrange
    is_amazon_cloud=0
    is_microsoft_cloud=1
    echo "0" > "${PROGRAM_DIR}/mock_nvme_timeout_5210"
    path_to_nvme_timeout="${PROGRAM_DIR}/mock_nvme_timeout_5210"

    #act
    check_5210_io_nvme_parameter_hyperscaler
    local rc=$?

    #assert
    if [[ "$rc" != '2' ]]; then
        bashunit::fail "Expected CheckError RC=2 but got RC=$rc"
    fi
}

function test_value_with_whitespace() {
    #arrange
    is_amazon_cloud=0
    is_microsoft_cloud=1
    echo " 240 " > "${PROGRAM_DIR}/mock_nvme_timeout_5210"
    path_to_nvme_timeout="${PROGRAM_DIR}/mock_nvme_timeout_5210"

    #act
    check_5210_io_nvme_parameter_hyperscaler
    local rc=$?

    #assert
    if [[ "$rc" != '0' ]]; then
        bashunit::fail "Expected CheckOk RC=0 but got RC=$rc"
    fi
}

function test_very_large_value() {
    #arrange
    is_amazon_cloud=0
    is_microsoft_cloud=1
    echo "999999" > "${PROGRAM_DIR}/mock_nvme_timeout_5210"
    path_to_nvme_timeout="${PROGRAM_DIR}/mock_nvme_timeout_5210"

    #act
    check_5210_io_nvme_parameter_hyperscaler
    local rc=$?

    #assert
    if [[ "$rc" != '0' ]]; then
        bashunit::fail "Expected CheckOk RC=0 but got RC=$rc"
    fi
}

function test_microsoft_cloud_with_low_value() {
    #arrange
    is_amazon_cloud=1
    is_microsoft_cloud=0
    echo "100" > "${PROGRAM_DIR}/mock_nvme_timeout_5210"
    path_to_nvme_timeout="${PROGRAM_DIR}/mock_nvme_timeout_5210"

    #act
    check_5210_io_nvme_parameter_hyperscaler
    local rc=$?

    #assert
    if [[ "$rc" != '2' ]]; then
        bashunit::fail "Expected CheckError RC=2 but got RC=$rc"
    fi
}

function set_up_before_script() {
    set +eE

    [[ -n "${HANA_HELPER_PROGVERSION:-}" ]] && return 0

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/5210_io_nvme_parameter_hyperscaler.check
    source "${PROGRAM_DIR}/../../lib/check/5210_io_nvme_parameter_hyperscaler.check"
}

function set_up() {
    # Default path - can be overridden by individual tests
    path_to_nvme_timeout="/sys/module/nvme_core/parameters/io_timeout"
    is_amazon_cloud=1
    is_microsoft_cloud=1

    # Clean up any existing mock files
    rm -f "${PROGRAM_DIR}/mock_nvme_timeout_5210"
}

function tear_down_after_script() {
    rm -f "${PROGRAM_DIR}/mock_nvme_timeout_5210"
}

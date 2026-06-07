#!/usr/bin/env bash
#------------------------------------------------------------------
# bashunit migration: 5200_io_nvme_module_hyperscaler_test.sh
# Tests for NVMe module loaded check on hyperscalers
#------------------------------------------------------------------
set -u

if [[ -z "${PROGRAM_DIR:-}" ]]; then
    PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
    [[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
fi

# Variables to control cloud platform simulation
is_amazon_cloud=1
is_microsoft_cloud=1
is_google_cloud=1

#mock PREREQUISITE functions
LIB_FUNC_IS_CLOUD_AMAZON() { return ${is_amazon_cloud} ; }
LIB_FUNC_IS_CLOUD_MICROSOFT() { return ${is_microsoft_cloud} ; }
LIB_FUNC_IS_CLOUD_GOOGLE() { return ${is_google_cloud} ; }

function test_not_on_hyperscaler() {
    #arrange
    is_amazon_cloud=1
    is_microsoft_cloud=1
    is_google_cloud=1

    #act
    check_5200_io_nvme_enabled_hyperscaler
    local rc=$?

    #assert
    if [[ "$rc" != '3' ]]; then
        bashunit::fail "Expected CheckSkip RC=3 but got RC=$rc"
    fi
    assert_true true
}

function test_on_hyperscaler_module_loaded() {
    #arrange
    is_microsoft_cloud=0
    mkdir -p "${PROGRAM_DIR}/mock_nvme_module_5200"
    path_to_nvme_module="${PROGRAM_DIR}/mock_nvme_module_5200"

    #act
    check_5200_io_nvme_enabled_hyperscaler
    local rc=$?

    #assert
    if [[ "$rc" != '0' ]]; then
        bashunit::fail "Expected CheckOk RC=0 but got RC=$rc"
    fi
    assert_true true
}

function test_on_hyperscaler_module_not_loaded() {
    #arrange
    is_microsoft_cloud=0
    path_to_nvme_module="${PROGRAM_DIR}/nonexistent_nvme_module_5200"

    #act
    check_5200_io_nvme_enabled_hyperscaler
    local rc=$?

    #assert
    if [[ "$rc" != '1' ]]; then
        bashunit::fail "Expected CheckWarning RC=1 but got RC=$rc"
    fi
    assert_true true
}

function set_up_before_script() {
    set +eE

    [[ -n "${_5200_test_loaded:-}" ]] && return 0
    _5200_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/5200_io_nvme_enabled_hyperscaler.check
    source "${PROGRAM_DIR}/../../lib/check/5200_io_nvme_enabled_hyperscaler.check"
}

function set_up() {
    # Default path - can be overridden by individual tests
    path_to_nvme_module="/sys/module/nvme_core"
    is_amazon_cloud=1
    is_microsoft_cloud=1
    is_google_cloud=1

    # Clean up any existing mock directories
    rm -rf "${PROGRAM_DIR}/mock_nvme_module_5200"
}

function tear_down_after_script() {
    rm -rf "${PROGRAM_DIR}/mock_nvme_module_5200"
}

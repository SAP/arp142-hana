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
LIB_PLATF_NAME=''
TEST_LIB_FUNC_IS_VIRT_MICROSOFT=0

# Mock functions
LIB_FUNC_IS_CLOUD_MICROSOFT() { return 0 ; }

LIB_FUNC_IS_VIRT_MICROSOFT() {
    return "${TEST_LIB_FUNC_IS_VIRT_MICROSOFT}"
}


function test_VM_not_supported() {

    #arrange
    LIB_PLATF_NAME='Standard_M64s_xx'
    TEST_LIB_FUNC_IS_VIRT_MICROSOFT=0

    #act
    check_0101_supported_instances_azure

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for unsupported VM"
    fi
}

function test_VM_supported() {

    #arrange
    LIB_PLATF_NAME='Standard_M64s'
    TEST_LIB_FUNC_IS_VIRT_MICROSOFT=0

    #act
    check_0101_supported_instances_azure

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for supported VM"
    fi
}

function test_VM_supported_uppercase() {

    #arrange
    LIB_PLATF_NAME='Standard_M64MS'
    TEST_LIB_FUNC_IS_VIRT_MICROSOFT=0

    #act
    check_0101_supported_instances_azure

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for supported VM (uppercase)"
    fi
}

function test_BareMetal_not_supported() {

    #arrange
    LIB_PLATF_NAME='Standard_S384xX'
    TEST_LIB_FUNC_IS_VIRT_MICROSOFT=1

    #act
    check_0101_supported_instances_azure

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for unsupported BareMetal"
    fi
}

function test_BareMetal_supported() {

    #arrange
    LIB_PLATF_NAME='Standard_S384xm'
    TEST_LIB_FUNC_IS_VIRT_MICROSOFT=1

    #act
    check_0101_supported_instances_azure

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for supported BareMetal"
    fi
}


function set_up_before_script() {

    # Disable errexit - bashunit enables it but sourced files may return non-zero
    set +eE

    # Skip if already loaded (bashunit runs all tests in same session)
    [[ -n "${_0101_test_loaded:-}" ]] && return 0
    _0101_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/0101_supported_instances_azure.check
    source "${PROGRAM_DIR}/../../lib/check/0101_supported_instances_azure.check"

}

function set_up() {

    # Reset mock variables
    LIB_PLATF_NAME=
    TEST_LIB_FUNC_IS_VIRT_MICROSOFT=0

}

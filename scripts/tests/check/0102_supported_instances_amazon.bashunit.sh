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
TEST_LIB_FUNC_IS_VIRT_KVM=0

# Mock functions
LIB_FUNC_IS_CLOUD_AMAZON() { return 0 ; }

LIB_FUNC_IS_VIRT_KVM() {
    return "${TEST_LIB_FUNC_IS_VIRT_KVM}"
}

LIB_FUNC_IS_VIRT_XEN() {
    return "${TEST_LIB_FUNC_IS_VIRT_KVM}"
}


function test_VM_not_supported() {

    #arrange
    LIB_PLATF_NAME='t2.micro'
    TEST_LIB_FUNC_IS_VIRT_KVM=0

    #act
    check_0102_supported_instances_amazon

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for unsupported VM"
    fi
    assert_true true
}

function test_VM_previous_generation() {

    #arrange
    LIB_PLATF_NAME='r3.8xlarge'
    TEST_LIB_FUNC_IS_VIRT_KVM=0

    #act
    check_0102_supported_instances_amazon

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for previous generation VM"
    fi
    assert_true true
}

function test_VM_previous_generation_r4() {

    #arrange
    LIB_PLATF_NAME='r4.16xlarge'
    TEST_LIB_FUNC_IS_VIRT_KVM=0

    #act
    check_0102_supported_instances_amazon

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for previous generation VM r4"
    fi
    assert_true true
}

function test_VM_supported() {

    #arrange
    LIB_PLATF_NAME='x1.32xlarge'
    TEST_LIB_FUNC_IS_VIRT_KVM=0

    #act
    check_0102_supported_instances_amazon

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for supported VM"
    fi
    assert_true true
}

function test_BareMetal_not_supported() {

    #arrange
    LIB_PLATF_NAME='x-18tb1.metal'
    TEST_LIB_FUNC_IS_VIRT_KVM=1

    #act
    check_0102_supported_instances_amazon

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for unsupported BareMetal"
    fi
    assert_true true
}

function test_BareMetal_supported() {

    #arrange
    LIB_PLATF_NAME='u-18tb1.metal'
    TEST_LIB_FUNC_IS_VIRT_KVM=1

    #act
    check_0102_supported_instances_amazon

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for supported BareMetal"
    fi
    assert_true true
}


function set_up_before_script() {

    # Disable errexit - bashunit enables it but sourced files may return non-zero
    set +eE

    # Skip if already loaded (bashunit runs all tests in same session)
    [[ -n "${_0102_test_loaded:-}" ]] && return 0
    _0102_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/0102_supported_instances_amazon.check
    source "${PROGRAM_DIR}/../../lib/check/0102_supported_instances_amazon.check"

}

function set_up() {

    # Reset mock variables
    LIB_PLATF_NAME=
    TEST_LIB_FUNC_IS_VIRT_KVM=0

}

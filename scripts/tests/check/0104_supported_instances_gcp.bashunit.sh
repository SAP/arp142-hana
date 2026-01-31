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
LIB_FUNC_IS_CLOUD_GOOGLE() { return 0 ; }

LIB_FUNC_IS_VIRT_KVM() {
    return "${TEST_LIB_FUNC_IS_VIRT_KVM}"
}


function test_VM_not_supported() {

    #arrange
    LIB_PLATF_NAME='m1-megamem-12'
    TEST_LIB_FUNC_IS_VIRT_KVM=0

    #act
    check_0104_supported_instances_gcp

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for unsupported VM"
    fi
}

function test_VM_supported() {

    #arrange
    LIB_PLATF_NAME='m2-ultramem-208'
    TEST_LIB_FUNC_IS_VIRT_KVM=0

    #act
    check_0104_supported_instances_gcp

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for supported VM"
    fi
}

function test_BareMetal_not_supported() {

    #arrange
    LIB_PLATF_NAME='o0-ultramem-001-metal'
    TEST_LIB_FUNC_IS_VIRT_KVM=1

    #act
    check_0104_supported_instances_gcp

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for unsupported BareMetal"
    fi
}

function test_BareMetal_supported() {

    #arrange
    LIB_PLATF_NAME='o2-ultramem-896-metal'
    TEST_LIB_FUNC_IS_VIRT_KVM=1

    #act
    check_0104_supported_instances_gcp

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for supported BareMetal"
    fi
}


function set_up_before_script() {

    # Disable errexit - bashunit enables it but sourced files may return non-zero
    set +eE

    # Skip if already loaded (bashunit runs all tests in same session)
    [[ -n "${_0104_test_loaded:-}" ]] && return 0
    _0104_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/0104_supported_instances_gcp.check
    source "${PROGRAM_DIR}/../../lib/check/0104_supported_instances_gcp.check"

}

function set_up() {

    # Reset mock variables
    LIB_PLATF_NAME=
    TEST_LIB_FUNC_IS_VIRT_KVM=0

}

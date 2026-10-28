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

assert_check_processed() {
    local rc=$1
    local context="${2:-}"
    assert_not_equals 99 "${rc}" "Check must be processed${context:+ in }${context}"
}

function test_VM_not_supported() {

    #arrange
    LIB_PLATF_NAME='Standard_E64s_v3'
    TEST_LIB_FUNC_IS_VIRT_MICROSOFT=0

    #act
    local rc=0
    check_0101_supported_instances_azure || rc=$?

    #assert
    assert_check_processed "${rc}" 'unsupported Broadwell VM'
    assert_exit_code 2 'Expected RC=2 (error) for unsupported Broadwell VM' "${rc}"
}

function test_VM_supported() {

    #arrange
    LIB_PLATF_NAME='Standard_M64s'
    TEST_LIB_FUNC_IS_VIRT_MICROSOFT=0

    #act
    local rc=0
    check_0101_supported_instances_azure || rc=$?

    #assert
    assert_check_processed "${rc}" 'supported VM'
    assert_exit_code 0 'Expected RC=0 (ok) for supported VM' "${rc}"
}

function test_VM_supported_uppercase() {

    #arrange
    LIB_PLATF_NAME='Standard_M64MS'
    TEST_LIB_FUNC_IS_VIRT_MICROSOFT=0

    #act
    local rc=0
    check_0101_supported_instances_azure || rc=$?

    #assert
    assert_check_processed "${rc}" 'uppercase supported VM'
    assert_exit_code 0 'Expected RC=0 (ok) for supported VM (uppercase)' "${rc}"
}

function test_BareMetal_not_supported() {

    #arrange
    LIB_PLATF_NAME='Standard_S384'
    TEST_LIB_FUNC_IS_VIRT_MICROSOFT=1

    #act
    local rc=0
    check_0101_supported_instances_azure || rc=$?

    #assert
    assert_check_processed "${rc}" 'unsupported Broadwell bare metal'
    assert_exit_code 2 'Expected RC=2 (error) for unsupported Broadwell bare metal' "${rc}"
}

function test_BareMetal_supported() {

    #arrange
    LIB_PLATF_NAME='Standard_S448ma'
    TEST_LIB_FUNC_IS_VIRT_MICROSOFT=1

    #act
    local rc=0
    check_0101_supported_instances_azure || rc=$?

    #assert
    assert_check_processed "${rc}" 'supported bare metal'
    assert_exit_code 0 'Expected RC=0 (ok) for supported BareMetal' "${rc}"
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

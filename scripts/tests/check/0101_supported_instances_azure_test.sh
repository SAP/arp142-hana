#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
[[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
readonly PROGRAM_DIR

#mock PREREQUISITE functions
LIB_FUNC_IS_CLOUD_MICROSOFT() { return 0 ; }

LIB_FUNC_IS_VIRT_MICROSOFT() {
    return "${TEST_LIB_FUNC_IS_VIRT_MICROSOFT}"
}

LIB_PLATF_NAME=''
declare -i TEST_LIB_FUNC_IS_VIRT_MICROSOFT

test_VM_not_supported() {

    #arrange
    LIB_PLATF_NAME='Standard_M64s_xx'
    TEST_LIB_FUNC_IS_VIRT_MICROSOFT=0

    #act
    check_0101_supported_instances_azure

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_VM_supported() {

    #arrange
    LIB_PLATF_NAME='Standard_M64s'
    TEST_LIB_FUNC_IS_VIRT_MICROSOFT=0

    #act
    check_0101_supported_instances_azure

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_VM_supported_uppercase() {

    #arrange
    LIB_PLATF_NAME='Standard_M64MS'
    TEST_LIB_FUNC_IS_VIRT_MICROSOFT=0

    #act
    check_0101_supported_instances_azure

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_BareMetal_not_supported() {

    #arrange
    LIB_PLATF_NAME='Standard_S384xX'
    TEST_LIB_FUNC_IS_VIRT_MICROSOFT=1

    #act
    check_0101_supported_instances_azure

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_BareMetal_supported() {

    #arrange
    LIB_PLATF_NAME='Standard_S384xm'
    TEST_LIB_FUNC_IS_VIRT_MICROSOFT=1

    #act
    check_0101_supported_instances_azure

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/0101_supported_instances_azure.check
    source "${PROGRAM_DIR}/../../lib/check/0101_supported_instances_azure.check"

}

# oneTimeTearDown

setUp() {

    LIB_PLATF_NAME=
    TEST_LIB_FUNC_IS_VIRT_MICROSOFT=

}

# tearDown

#Import Libraries
# - order is important - sourcing shunit triggers testing
# - that's also the reason, why it could not be done during oneTimeSetup

#Load and run shUnit2
#shellcheck source=../shunit2
source "${PROGRAM_DIR}/../shunit2"

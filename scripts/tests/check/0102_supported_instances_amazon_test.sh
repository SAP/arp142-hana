#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
[[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
readonly PROGRAM_DIR

#mock PREREQUISITE functions
LIB_FUNC_IS_CLOUD_AMAZON() { return 0 ; }

LIB_FUNC_IS_VIRT_KVM() {
    return "${TEST_LIB_FUNC_IS_VIRT_KVM}"
}

LIB_FUNC_IS_VIRT_XEN() {
    return "${TEST_LIB_FUNC_IS_VIRT_KVM}"
}

LIB_PLATF_NAME=''
declare -i TEST_LIB_FUNC_IS_VIRT_KVM

test_VM_not_supported() {

    #arrange
    LIB_PLATF_NAME='r3.8xlarge'
    TEST_LIB_FUNC_IS_VIRT_KVM=0

    #act
    check_0102_supported_instances_amazon

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_VM_supported() {

    #arrange
    LIB_PLATF_NAME='x1.32xlarge'
    TEST_LIB_FUNC_IS_VIRT_KVM=0

    #act
    check_0102_supported_instances_amazon

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_BareMetal_not_supported() {

    #arrange
    LIB_PLATF_NAME='x-18tb1.metal'
    TEST_LIB_FUNC_IS_VIRT_KVM=1

    #act
    check_0102_supported_instances_amazon

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_BareMetal_supported() {

    #arrange
    LIB_PLATF_NAME='u-18tb1.metal'
    TEST_LIB_FUNC_IS_VIRT_KVM=1

    #act
    check_0102_supported_instances_amazon

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/0102_supported_instances_amazon.check
    source "${PROGRAM_DIR}/../../lib/check/0102_supported_instances_amazon.check"

}

# oneTimeTearDown

setUp() {

    LIB_PLATF_NAME=
    TEST_LIB_FUNC_IS_VIRT_KVM=

}

# tearDown

#Import Libraries
# - order is important - sourcing shunit triggers testing
# - that's also the reason, why it could not be done during oneTimeSetup

#Load and run shUnit2
#shellcheck source=../shunit2
source "${PROGRAM_DIR}/../shunit2"

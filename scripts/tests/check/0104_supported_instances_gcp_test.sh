#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
readonly PROGRAM_DIR

#mock PREREQUISITE functions
LIB_FUNC_IS_CLOUD_GOOGLE() { return 0 ; }

LIB_FUNC_IS_VIRT_KVM() {
    return "${TEST_LIB_FUNC_IS_VIRT_KVM}"
}

LIB_PLATF_NAME=''
declare -i TEST_LIB_FUNC_IS_VIRT_KVM

test_VM_not_supported() {

    #arrange
    LIB_PLATF_NAME='m1-megamem-12'
    TEST_LIB_FUNC_IS_VIRT_KVM=0

    #act
    check_0104_supported_instances_gcp

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_VM_supported() {

    #arrange
    LIB_PLATF_NAME='m2-ultramem-208'
    TEST_LIB_FUNC_IS_VIRT_KVM=0

    #act
    check_0104_supported_instances_gcp

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_BareMetal_not_supported() {

    #arrange
    LIB_PLATF_NAME='o0-ultramem-001-metal'
    TEST_LIB_FUNC_IS_VIRT_KVM=1

    #act
    check_0104_supported_instances_gcp

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_BareMetal_supported() {

    #arrange
    LIB_PLATF_NAME='o2-ultramem-896-metal'
    TEST_LIB_FUNC_IS_VIRT_KVM=1

    #act
    check_0104_supported_instances_gcp

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/0104_supported_instances_gcp.check
    source "${PROGRAM_DIR}/../../lib/check/0104_supported_instances_gcp.check"

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

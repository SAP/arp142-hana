#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
readonly PROGRAM_DIR

#mock PREREQUISITE functions
LIB_FUNC_IS_CLOUD_MICROSOFT() { return 0 ; }
LIB_FUNC_IS_SLES() { return 0 ; }

OS_LEVEL=''

test_kernel-azure_not_supported() {

    #arrange
    OS_LEVEL='4.12.14-122.103-azure'

    #act
    check_0013_os_kernel_sles_azure

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_kernel-default_supported() {

    #arrange
    OS_LEVEL='4.12.14-122.103-default'

    #act
    check_0013_os_kernel_sles_azure

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/0013_os_kernel_sles_azure.check
    source "${PROGRAM_DIR}/../../lib/check/0013_os_kernel_sles_azure.check"

}

# oneTimeTearDown

setUp() {

    OS_LEVEL=

}

# tearDown

#Import Libraries
# - order is important - sourcing shunit triggers testing
# - that's also the reason, why it could not be done during oneTimeSetup

#Load and run shUnit2
#shellcheck source=../shunit2
source "${PROGRAM_DIR}/../shunit2"

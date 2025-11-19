#!/usr/bin/env bash
set -u      # treat unset variables as an error

PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
[[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
readonly PROGRAM_DIR

testValidateOS_SLES_Supported() {
    # Test supported SLES versions

    OS_NAME='Linux SLES'
    OS_VERSION='15.5'
    LIB_FUNC_VALIDATE_OS
    assertEquals "SLES 15.5 should be supported" 0 $?

    OS_VERSION='15.7'
    LIB_FUNC_VALIDATE_OS
    assertEquals "SLES 15.7 should be supported" 0 $?

    OS_VERSION='12.5'
    LIB_FUNC_VALIDATE_OS
    assertEquals "SLES 12.5 should be supported" 0 $?
}

testValidateOS_SLES_EOL() {
    # Test EOL SLES versions

    OS_NAME='Linux SLES'
    OS_VERSION='11.4'
    LIB_FUNC_VALIDATE_OS
    assertEquals "SLES 11.4 should return EOL" 1 $?

    OS_VERSION='12.4'
    LIB_FUNC_VALIDATE_OS
    assertEquals "SLES 12.4 should return EOL" 1 $?

    OS_VERSION='15.2'
    LIB_FUNC_VALIDATE_OS
    assertEquals "SLES 15.2 should return EOL" 1 $?
}

testValidateOS_RHEL_Supported() {
    # Test supported RHEL versions

    OS_NAME='Linux RHEL'
    OS_VERSION='9.2'
    LIB_FUNC_VALIDATE_OS
    assertEquals "RHEL 9.2 should be supported" 0 $?

    OS_VERSION='8.6'
    LIB_FUNC_VALIDATE_OS
    assertEquals "RHEL 8.6 should be supported" 0 $?

    OS_VERSION='7.9'
    LIB_FUNC_VALIDATE_OS
    assertEquals "RHEL 7.9 should be supported" 0 $?
}

testValidateOS_RHEL_EOL() {
    # Test EOL RHEL versions

    OS_NAME='Linux RHEL'
    OS_VERSION='7.8'
    LIB_FUNC_VALIDATE_OS
    assertEquals "RHEL 7.8 should return EOL" 1 $?

    OS_VERSION='6.10'
    LIB_FUNC_VALIDATE_OS
    assertEquals "RHEL 6.10 should return EOL" 1 $?
}

testValidateOS_UnsupportedDistribution() {
    # Test unsupported distributions
    OS_NAME='Linux OLS'
    OS_VERSION='9.6'
    LIB_FUNC_VALIDATE_OS
    assertEquals "OLS should be unsupported" 2 $?

    OS_NAME='Linux Ubuntu'
    OS_VERSION='22.04'
    LIB_FUNC_VALIDATE_OS
    assertEquals "Ubuntu should be unsupported" 2 $?

    OS_NAME='Linux CentOS'
    OS_VERSION='8.0'
    LIB_FUNC_VALIDATE_OS
    assertEquals "CentOS should be unsupported" 2 $?

    OS_NAME='Linux UNKNOWN'
    OS_VERSION='0.0'
    LIB_FUNC_VALIDATE_OS
    assertEquals "Linux UNKNOWN should be unsupported" 2 $?
}

testValidateOS_FutureVersions() {
    # Test future/unknown versions - should allow with warning

    OS_NAME='Linux SLES'
    OS_VERSION='16.0'
    LIB_FUNC_VALIDATE_OS
    assertEquals "SLES 16.0 (future) should be allowed" 0 $?

    OS_NAME='Linux RHEL'
    OS_VERSION='10.0'
    LIB_FUNC_VALIDATE_OS
    assertEquals "RHEL 10.0 (future) should be allowed" 0 $?
}

oneTimeSetUp () {

    # prevent loading of original libraries
    # shellcheck disable=SC2034
    LIB_LINUX_RELEASE='dont load'
    # shellcheck disable=SC2034
    LIB_PLATF_x86_64_RELEASE='dont load'
    # shellcheck disable=SC2034
    LIB_PLATF_POWER_RELEASE='dont load'

    declare -i LIB_PLATF_RAM_MIB_PHYS=1024
    declare -i LIB_PLATF_RAM_MiB_AVAILABLE=1024
    declare -i LIB_PLATF_RAM_KiB_AVAILABLE=1024

    # Set up stub functions for distribution detection
    LIB_FUNC_IS_SLES() {
        [[ "${OS_NAME}" == 'Linux SLES' ]] && return 0
        return 1
    }

    LIB_FUNC_IS_RHEL() {
        [[ "${OS_NAME}" == 'Linux RHEL' ]] && return 0
        return 1
    }

    #shellcheck source=./saphana-logger-stubs
    source "${PROGRAM_DIR}/./saphana-logger-stubs"

    #shellcheck source=../bin/saphana-helper-funcs
    source "${PROGRAM_DIR}/../bin/saphana-helper-funcs"

}

# oneTimeTearDown
# setUp
# tearDown

#Import Libraries
# - order is important - sourcing shunit triggers testing
# - that's also the reason, why it could not be done during oneTimeSetup

#shellcheck source=./shunit2
source "${PROGRAM_DIR}/shunit2"

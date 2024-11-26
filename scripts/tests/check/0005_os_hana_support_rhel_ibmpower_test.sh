#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
readonly PROGRAM_DIR

#mock PREREQUISITE functions
LIB_FUNC_IS_IBMPOWER() { return 0 ; }
LIB_FUNC_IS_RHEL() { return 0 ; }
LIB_FUNC_IS_CLOUD_IBM() { return "${IBMCLOUD_RC}" ; }

LIB_PLATF_ARCHITECTURE=''
LIB_PLATF_POWER_PLATFORM_BASE=''
OS_VERSION=''
IBMCLOUD_RC=

test_bigendian_not_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64'

    #act
    check_0005_os_hana_support_rhel_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_power7_not_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER7'

    #act
    check_0005_os_hana_support_rhel_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_power8_rhel_not_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER8'
    OS_VERSION='8.0'

    #act
    check_0005_os_hana_support_rhel_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_power8_rhel_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER8'
    OS_VERSION='7.9'

    #act
    check_0005_os_hana_support_rhel_ibmpower

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_power9_rhel_not_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'
    OS_VERSION='7.9'

    #act
    check_0005_os_hana_support_rhel_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_power9_rhel_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'
    OS_VERSION='8.8'

    #act
    check_0005_os_hana_support_rhel_ibmpower

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_power10_rhel_not_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER10'
    OS_VERSION='7.9'

    #act
    check_0005_os_hana_support_rhel_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_power10_rhel_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER10'
    OS_VERSION='8.4'

    #act
    check_0005_os_hana_support_rhel_ibmpower

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_powerX_not_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWERx'

    #act
    check_0005_os_hana_support_rhel_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_architecture_not_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc65le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'

    #act
    check_0005_os_hana_support_rhel_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_environment_not_handled() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER90'
    OS_VERSION='8.2'

    #act
    check_0005_os_hana_support_rhel_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_rhel_not_handled() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'
    OS_VERSION='8.9'

    #act
    check_0005_os_hana_support_rhel_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_ibmcloud_power9_rhel_not_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'
    OS_VERSION='7.9'
    IBMCLOUD_RC=0

    #act
    check_0005_os_hana_support_rhel_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_ibmcloud_power9_rhel_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'
    OS_VERSION='8.10'
    IBMCLOUD_RC=0

    #act
    check_0005_os_hana_support_rhel_ibmpower

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_ibmcloud_power10_rhel_not_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER10'
    OS_VERSION='7.9'
    IBMCLOUD_RC=0

    #act
    check_0005_os_hana_support_rhel_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_ibmcloud_power10_rhel_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER10'
    OS_VERSION='9.4'
    IBMCLOUD_RC=0

    #act
    check_0005_os_hana_support_rhel_ibmpower

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}


oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/0005_os_hana_support_rhel_ibmpower.check
    source "${PROGRAM_DIR}/../../lib/check/0005_os_hana_support_rhel_ibmpower.check"

}

# oneTimeTearDown

setUp() {

    LIB_PLATF_ARCHITECTURE=
    LIB_PLATF_POWER_PLATFORM_BASE=
    OS_VERSION=
    IBMCLOUD_RC=1

}
# tearDown

#Import Libraries
# - order is important - sourcing shunit triggers testing
# - that's also the reason, why it could not be done during oneTimeSetup

#Load and run shUnit2
#shellcheck source=../shunit2
source "${PROGRAM_DIR}/../shunit2"

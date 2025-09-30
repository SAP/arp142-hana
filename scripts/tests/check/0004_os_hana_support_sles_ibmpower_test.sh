#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
readonly PROGRAM_DIR

#mock PREREQUISITE functions
LIB_FUNC_IS_IBMPOWER() { return 0 ; }
LIB_FUNC_IS_SLES() { return 0 ; }
LIB_FUNC_IS_CLOUD_IBM() { return "${IBMCLOUD_RC}" ; }

LIB_PLATF_ARCHITECTURE=''
LIB_PLATF_POWER_PLATFORM_BASE=''
OS_VERSION=''
IBMCLOUD_RC=

test_power7_bigendian_sles_not_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER7'
    OS_VERSION='11.3'

    #act
    check_0004_os_hana_support_sles_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_power9_bigendian_not_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'

    #act
    check_0004_os_hana_support_sles_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_power7_littleendian_sles_not_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER7'
    OS_VERSION='11.4'

    #act
    check_0004_os_hana_support_sles_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_power8_littleendian_sles_not_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER8'
    OS_VERSION='12.5'

    #act
    check_0004_os_hana_support_sles_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_power9_littleendian_sles_not_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'
    OS_VERSION='12.2'

    #act
    check_0004_os_hana_support_sles_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_power9_littleendian_sles_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'
    OS_VERSION='15.6'

    #act
    check_0004_os_hana_support_sles_ibmpower

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_power10_littleendian_sles_not_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER10'
    OS_VERSION='12.2'

    #act
    check_0004_os_hana_support_sles_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_power10_littleendian_sles_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER10'
    OS_VERSION='15.5'

    #act
    check_0004_os_hana_support_sles_ibmpower

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_powerX_not_supported() {

    #arrange
    LIB_PLATF_POWER_PLATFORM_BASE='POWER6'

    #act
    check_0004_os_hana_support_sles_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_architecture_not_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc65le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'

    #act
    check_0004_os_hana_support_sles_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_environment_not_handled() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER90'
    OS_VERSION='15.3'

    #act
    check_0004_os_hana_support_sles_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_sles_not_handled() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'
    OS_VERSION='15.9'

    #act
    check_0004_os_hana_support_sles_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_ibmcloud_power9_littleendian_sles_not_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'
    OS_VERSION='12.4'
    IBMCLOUD_RC=0

    #act
    check_0004_os_hana_support_sles_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_ibmcloud_power9_littleendian_sles_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER9'
    OS_VERSION='15.5'
    IBMCLOUD_RC=0

    #act
    check_0004_os_hana_support_sles_ibmpower

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_ibmcloud_power10_littleendian_sles_not_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER10'
    OS_VERSION='12.5'
    IBMCLOUD_RC=0

    #act
    check_0004_os_hana_support_sles_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_ibmcloud_power10_littleendian_sles_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_POWER_PLATFORM_BASE='POWER10'
    OS_VERSION='15.6'
    IBMCLOUD_RC=0

    #act
    check_0004_os_hana_support_sles_ibmpower

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}


oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/0004_os_hana_support_sles_ibmpower.check
    source "${PROGRAM_DIR}/../../lib/check/0004_os_hana_support_sles_ibmpower.check"

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

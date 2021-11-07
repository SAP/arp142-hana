#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
readonly PROGRAM_DIR

#mock PREREQUISITE functions
LIB_FUNC_IS_IBMPOWER() { return 0 ; }
LIB_FUNC_IS_RHEL() { return 0 ; }

LIB_PLATF_ARCHITECTURE=''
LIB_PLATF_CPU=''
OS_VERSION=''

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
    LIB_PLATF_CPU='POWER7 (architected), altivec supported'

    #act
    check_0005_os_hana_support_rhel_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_power8_rhel_not_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_CPU='POWER8 (architected), altivec supported'
    OS_VERSION='8.0'

    #act
    check_0005_os_hana_support_rhel_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_power8_rhel_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_CPU='POWER8 (architected), altivec supported'
    OS_VERSION='7.7'

    #act
    check_0005_os_hana_support_rhel_ibmpower

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_power9_rhel_not_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_CPU='POWER9 (architected), altivec supported'
    OS_VERSION='7.7'

    #act
    check_0005_os_hana_support_rhel_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_power9_rhel_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_CPU='POWER9 (architected), altivec supported'
    OS_VERSION='8.2'

    #act
    check_0005_os_hana_support_rhel_ibmpower

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_powerX_not_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_CPU='POWERx (architected), altivec supported'

    #act
    check_0005_os_hana_support_rhel_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_architecture_not_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc65le'
    LIB_PLATF_CPU='POWER9 (architected), altivec supported'

    #act
    check_0005_os_hana_support_rhel_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_environment_not_handled() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_CPU='POWER90 (architected), altivec supported'
    OS_VERSION='8.2'

    #act
    check_0005_os_hana_support_rhel_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_rhel_not_handled() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_CPU='POWER9 (architected), altivec supported'
    OS_VERSION='8.9'

    #act
    check_0005_os_hana_support_rhel_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
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
    LIB_PLATF_CPU=
    OS_VERSION=

}
# tearDown

#Import Libraries
# - order is important - sourcing shunit triggers testing
# - that's also the reason, why it could not be done during oneTimeSetup

#Load and run shUnit2
#shellcheck source=../shunit2
source "${PROGRAM_DIR}/../shunit2"

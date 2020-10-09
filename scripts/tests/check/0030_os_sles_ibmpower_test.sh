#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
readonly PROGRAM_DIR

#mock PREREQUISITE functions
LIB_FUNC_IS_IBMPOWER() { return 0 ; }
LIB_FUNC_IS_SLES() { return 0 ; }

LIB_PLATF_ARCHITECTURE=''
LIB_PLATF_CPU=''
OS_VERSION=''
OS_LEVEL=''
declare -i LIB_PLATF_RAM_MIB_AVAILABLE


test_power6_bigendian_not_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64'
    LIB_PLATF_CPU='POWER6 (architected), altivec supported'

    #act
    check_0030_os_sles_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_power7_bigendian_sles_not_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64'
    LIB_PLATF_CPU='POWER7 (architected), altivec supported'
    OS_VERSION='11.3'

    #act
    check_0030_os_sles_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_power8_bigendian_no_bigmem_less4T() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64'
    LIB_PLATF_CPU='POWER8 (architected), altivec supported'
    OS_VERSION='11.4'
    OS_LEVEL='xxx'
    LIB_PLATF_RAM_MIB_AVAILABLE=4194304

    #act
    check_0030_os_sles_ibmpower

    #assert
    assertEquals "CheckWarning? RC" '1' "$?"
}

test_power8_bigendian_no_bigmem_great4T() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64'
    LIB_PLATF_CPU='POWER8 (architected), altivec supported'
    OS_VERSION='11.4'
    OS_LEVEL='xxx'
    LIB_PLATF_RAM_MIB_AVAILABLE=4194305

    #act
    check_0030_os_sles_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_power8_bigendian_sles_bigmem_ok() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64'
    LIB_PLATF_CPU='POWER8 (architected), altivec supported'
    OS_VERSION='11.4'
    OS_LEVEL='xxx-bigmem'

    #act
    check_0030_os_sles_ibmpower

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_power6_littleendian_not_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_CPU='POWER6 (architected), altivec supported'

    #act
    check_0030_os_sles_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_power7_littleendian_sles_not_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_CPU='POWER7 (architected), altivec supported'
    OS_VERSION='11.4'

    #act
    check_0030_os_sles_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_power8_littleendian_sles_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_CPU='POWER8 (architected), altivec supported'
    OS_VERSION='12.1'

    #act
    check_0030_os_sles_ibmpower

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_power9_littleendian_sles_not_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_CPU='POWER9 (architected), altivec supported'
    OS_VERSION='12.2'

    #act
    check_0030_os_sles_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_power9_littleendian_sles_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_CPU='POWER9 (architected), altivec supported'
    OS_VERSION='15.1'

    #act
    check_0030_os_sles_ibmpower

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_powerX_not_supported() {

    #arrange
    LIB_PLATF_ARCHITECTURE='ppc64le'
    LIB_PLATF_CPU='POWERx (architected), altivec supported'

    #act
    check_0030_os_sles_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}


oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/0030_os_sles_ibmpower.check
    source "${PROGRAM_DIR}/../../lib/check/0030_os_sles_ibmpower.check"

}

# oneTimeTearDown

setUp() {

    LIB_PLATF_ARCHITECTURE=
    LIB_PLATF_CPU=
    OS_VERSION=
    OS_LEVEL=
    LIB_PLATF_RAM_MIB_AVAILABLE=0

}

# tearDown

#Import Libraries
# - order is important - sourcing shunit triggers testing
# - that's also the reason, why it could not be done during oneTimeSetup

#Load and run shUnit2
#shellcheck source=../shunit2
source "${PROGRAM_DIR}/../shunit2"

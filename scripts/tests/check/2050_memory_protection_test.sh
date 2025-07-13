#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
readonly PROGRAM_DIR

#fake PREREQUISITE functions
LIB_FUNC_IS_SLES() { return 0 ; }
OS_VERSION='15.6'

test_mp_not_configurable() {

    #arrange
    path_to_sap_slice_memory_low='tmp123456'

    #act
    check_2050_memory_protection

    #assert
    assertEquals "CheckWarn? RC" '1' "$?"
}

test_mp_greater_than_gal() {

    # 262144 MiB = 256 GiB
    # 90% of 65536 MiB = 58982 MiB
    # 97% of 196608 MiB = 190709 MiB
    # 58982 + 190709 = 249691 MiB = 261_819_990_016 bytes
    # 1048576 = 1 MiB in bytes

    #arrange
    path_to_sap_slice_memory_low="${PROGRAM_DIR}/mock_memory.low"
    echo $(( 261819990016 + 1 + 1048576 )) > "${path_to_sap_slice_memory_low}"
    LIB_PLATF_RAM_MiB_AVAILABLE=262144

    #act
    check_2050_memory_protection

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_mp_equals_gal() {

    # 4_194_304 MiB = 4096 GiB
    # 90% of    65_536 MiB =    58_982 MiB
    # 97% of 4_128_768 MiB = 4_004_904 MiB
    # 58982 + 4004904 = 4_063_886 MiB = 4_261_293_326_336 bytes

    #arrange
    path_to_sap_slice_memory_low="${PROGRAM_DIR}/mock_memory.low"
    echo 4261293326336 > "${path_to_sap_slice_memory_low}"
    LIB_PLATF_RAM_MiB_AVAILABLE=4194304

    #act
    check_2050_memory_protection

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}


test_mp_less_than_gal() {

    # 4_194_304 MiB = 4096 GiB
    # 90% of    65_536 MiB =    58_982 MiB
    # 97% of 4_128_768 MiB = 4_004_904 MiB
    # 58982 + 4004904 = 4_063_886 MiB = 4_261_293_326_336 bytes
    # 1048576 = 1 MiB in bytes

    #arrange
    path_to_sap_slice_memory_low="${PROGRAM_DIR}/mock_memory.low"
    echo $(( 261819990016 - 1 - 1048576 )) > "${path_to_sap_slice_memory_low}"
    LIB_PLATF_RAM_MiB_AVAILABLE=4194304

    #act
    check_2050_memory_protection

    #assert
    assertEquals "CheckWarn? RC" '1' "$?"
}



oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/2050_memory_protection.check
    source "${PROGRAM_DIR}/../../lib/check/2050_memory_protection.check"

    export avoidDoubleTearDownExecution=true

}

oneTimeTearDown() {

    if ${avoidDoubleTearDownExecution:-false}; then

        rm -f "${PROGRAM_DIR}/mock_memory.low"

        unset -v avoidDoubleTearDownExecution
    fi
}

setUp() {

    LIB_PLATF_RAM_MiB_AVAILABLE=
    echo 0 > "${PROGRAM_DIR}/mock_memory.low"

}

#tearDown

#Import Libraries
# - order is important - sourcing shunit triggers testing
# - that's also the reason, why it could not be done during oneTimeSetup

#Load and run shUnit2
#shellcheck source=../shunit2
source "${PROGRAM_DIR}/../shunit2"

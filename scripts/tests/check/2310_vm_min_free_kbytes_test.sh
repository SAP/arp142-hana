#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
readonly PROGRAM_DIR

#fake PREREQUISITE functions
LIB_FUNC_IS_RHEL() { return 0 ; }

# still to mock for tests
OS_VERSION=''

grep() {

     case "$*" in
        *'min_free_kbytes')     return 1 ;;
        *)                      command grep "$@" ;; # shunit2 also requires grep
    esac

}

test_mfkb_not_configurable() {

    #arrange
    path_to_min_free_kbytes='tmp123456'

    #act
    check_2310_vm_min_free_kbytes

    #assert
    assertEquals "CheckSkip? RC" '3' "$?"
}

test_mfkb_less_minimum() {

    #arrange
    path_to_min_free_kbytes="${PROGRAM_DIR}/mock_min_free_kbytes"
    echo 0 > "${path_to_min_free_kbytes}"
    LIB_PLATF_RAM_MiB_AVAILABLE=262144

    #act
    check_2310_vm_min_free_kbytes

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_mfkb_more_maximum() {

    #arrange
    path_to_min_free_kbytes="${PROGRAM_DIR}/mock_min_free_kbytes"
    echo 2097153 > "${path_to_min_free_kbytes}"
    LIB_PLATF_RAM_MiB_AVAILABLE=262144

    #act
    check_2310_vm_min_free_kbytes

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_mfkb_minimum_mem128G_ok() {

    #arrange
    path_to_min_free_kbytes="${PROGRAM_DIR}/mock_min_free_kbytes"
    echo 128 > "${path_to_min_free_kbytes}"
    LIB_PLATF_RAM_MiB_AVAILABLE=131072

    #act
    check_2310_vm_min_free_kbytes

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_mfkb_oldlimit_mem259G_ok() {

    #arrange
    OS_VERSION='7.7'
    path_to_min_free_kbytes="${PROGRAM_DIR}/mock_min_free_kbytes"
    echo 65536 > "${path_to_min_free_kbytes}"
    LIB_PLATF_RAM_MiB_AVAILABLE=265216

    #act
    check_2310_vm_min_free_kbytes

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_mfkb_oldlimit_mem259G_toolow() {

    #arrange
    OS_VERSION='7.7'
    path_to_min_free_kbytes="${PROGRAM_DIR}/mock_min_free_kbytes"
    echo 65000 > "${path_to_min_free_kbytes}"
    LIB_PLATF_RAM_MiB_AVAILABLE=265216

    #act
    check_2310_vm_min_free_kbytes

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_mfkb_oldlimit_mem4139G_ok() {

    #arrange
    OS_VERSION='7.7'
    path_to_min_free_kbytes="${PROGRAM_DIR}/mock_min_free_kbytes"
    echo 65536 > "${path_to_min_free_kbytes}"
    LIB_PLATF_RAM_MiB_AVAILABLE=4238336

    #act
    check_2310_vm_min_free_kbytes

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_mfkb_newlimit_mem259G_ok() {

    #arrange
    OS_VERSION='8.4'
    path_to_min_free_kbytes="${PROGRAM_DIR}/mock_min_free_kbytes"
    echo 65536 > "${path_to_min_free_kbytes}"
    LIB_PLATF_RAM_MiB_AVAILABLE=265216

    #act
    check_2310_vm_min_free_kbytes

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_mfkb_newlimit_mem259G_toolow() {

    #arrange
    OS_VERSION='8.4'
    path_to_min_free_kbytes="${PROGRAM_DIR}/mock_min_free_kbytes"
    echo 65000 > "${path_to_min_free_kbytes}"
    LIB_PLATF_RAM_MiB_AVAILABLE=265216

    #act
    check_2310_vm_min_free_kbytes

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_mfkb_newlimit_mem4139G_ok() {

    #arrange
    OS_VERSION='8.4'
    path_to_min_free_kbytes="${PROGRAM_DIR}/mock_min_free_kbytes"
    echo 262144 > "${path_to_min_free_kbytes}"
    LIB_PLATF_RAM_MiB_AVAILABLE=4238336

    #act
    check_2310_vm_min_free_kbytes

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_mfkb_newlimit_mem4139G_toolow() {

    #arrange
    OS_VERSION='8.4'
    path_to_min_free_kbytes="${PROGRAM_DIR}/mock_min_free_kbytes"
    echo 262100 > "${path_to_min_free_kbytes}"
    LIB_PLATF_RAM_MiB_AVAILABLE=4238336

    #act
    check_2310_vm_min_free_kbytes

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/2310_vm_min_free_kbytes.check
    source "${PROGRAM_DIR}/../../lib/check/2310_vm_min_free_kbytes.check"

    export avoidDoubleTearDownExecution=true

}

oneTimeTearDown() {

    if ${avoidDoubleTearDownExecution:-false}; then

        rm -f "${PROGRAM_DIR}/mock_min_free_kbytes"

        unset -v avoidDoubleTearDownExecution
    fi
}

setUp() {

    OS_VERSION=
    LIB_PLATF_RAM_MiB_AVAILABLE=
    echo 0 > "${PROGRAM_DIR}/mock_min_free_kbytes"

}

#tearDown

#Import Libraries
# - order is important - sourcing shunit triggers testing
# - that's also the reason, why it could not be done during oneTimeSetup

#Load and run shUnit2
#shellcheck source=../shunit2
source "${PROGRAM_DIR}/../shunit2"

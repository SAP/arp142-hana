#!/usr/bin/env bash
#------------------------------------------------------------------
# bashunit migration notes:
# 1. PROGRAM_DIR not readonly - bashunit runs all tests in same session
# 2. Guard check skips if already loaded to avoid readonly variable conflicts
#------------------------------------------------------------------
set -u  # treat unset variables as an error

if [[ -z "${PROGRAM_DIR:-}" ]]; then
    PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
    [[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
fi

# Mock variables
OS_VERSION=''
LIB_PLATF_RAM_MiB_AVAILABLE=0
path_to_min_free_kbytes=''

# Mock functions
LIB_FUNC_IS_RHEL() { return 1 ; }
LIB_FUNC_IS_SLES() { return 0 ; }

grep() {

    case "$*" in
        *'min_free_kbytes')     return 1 ;;
        *)                      command grep "$@" ;; # bashunit also requires grep
    esac

}


function test_mfkb_not_configurable() {

    #arrange
    path_to_min_free_kbytes='tmp123456'

    #act
    check_2310_vm_min_free_kbytes

    #assert
    if [[ $? -ne 3 ]]; then
        bashunit::fail "Expected RC=3 (skipped) for min_free_kbytes not configurable"
    fi
}

function test_mfkb_less_minimum() {

    #arrange
    path_to_min_free_kbytes="${PROGRAM_DIR}/mock_min_free_kbytes"
    echo 0 > "${path_to_min_free_kbytes}"
    LIB_PLATF_RAM_MiB_AVAILABLE=262144

    #act
    check_2310_vm_min_free_kbytes

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for min_free_kbytes less than minimum"
    fi
}

function test_mfkb_more_maximum() {

    #arrange
    path_to_min_free_kbytes="${PROGRAM_DIR}/mock_min_free_kbytes"
    echo 2097153 > "${path_to_min_free_kbytes}"
    LIB_PLATF_RAM_MiB_AVAILABLE=262144

    #act
    check_2310_vm_min_free_kbytes

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for min_free_kbytes more than maximum"
    fi
}

function test_mfkb_minimum_mem128G_ok() {

    #arrange
    path_to_min_free_kbytes="${PROGRAM_DIR}/mock_min_free_kbytes"
    echo 128 > "${path_to_min_free_kbytes}"
    LIB_PLATF_RAM_MiB_AVAILABLE=131072

    #act
    check_2310_vm_min_free_kbytes

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for min_free_kbytes minimum mem 128G"
    fi
}

function test_mfkb_oldlimit_mem259G_ok() {

    #arrange
    OS_VERSION='12.5'
    path_to_min_free_kbytes="${PROGRAM_DIR}/mock_min_free_kbytes"
    echo 65536 > "${path_to_min_free_kbytes}"
    LIB_PLATF_RAM_MiB_AVAILABLE=265216

    #act
    check_2310_vm_min_free_kbytes

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for old limit mem 259G"
    fi
}

function test_mfkb_oldlimit_mem259G_toolow() {

    #arrange
    OS_VERSION='12.5'
    path_to_min_free_kbytes="${PROGRAM_DIR}/mock_min_free_kbytes"
    echo 65000 > "${path_to_min_free_kbytes}"
    LIB_PLATF_RAM_MiB_AVAILABLE=265216

    #act
    check_2310_vm_min_free_kbytes

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for old limit mem 259G too low"
    fi
}

function test_mfkb_oldlimit_mem4139G_ok() {

    #arrange
    OS_VERSION='12.5'
    path_to_min_free_kbytes="${PROGRAM_DIR}/mock_min_free_kbytes"
    echo 65536 > "${path_to_min_free_kbytes}"
    LIB_PLATF_RAM_MiB_AVAILABLE=4238336

    #act
    check_2310_vm_min_free_kbytes

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for old limit mem 4139G"
    fi
}

function test_mfkb_newlimit_mem259G_ok() {

    #arrange
    OS_VERSION='15.6'
    path_to_min_free_kbytes="${PROGRAM_DIR}/mock_min_free_kbytes"
    echo 65536 > "${path_to_min_free_kbytes}"
    LIB_PLATF_RAM_MiB_AVAILABLE=265216

    #act
    check_2310_vm_min_free_kbytes

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for new limit mem 259G"
    fi
}

function test_mfkb_newlimit_mem259G_toolow() {

    #arrange
    OS_VERSION='15.6'
    path_to_min_free_kbytes="${PROGRAM_DIR}/mock_min_free_kbytes"
    echo 65000 > "${path_to_min_free_kbytes}"
    LIB_PLATF_RAM_MiB_AVAILABLE=265216

    #act
    check_2310_vm_min_free_kbytes

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for new limit mem 259G too low"
    fi
}

function test_mfkb_newlimit_mem4139G_ok() {

    #arrange
    OS_VERSION='15.6'
    path_to_min_free_kbytes="${PROGRAM_DIR}/mock_min_free_kbytes"
    echo 262144 > "${path_to_min_free_kbytes}"
    LIB_PLATF_RAM_MiB_AVAILABLE=4238336

    #act
    check_2310_vm_min_free_kbytes

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for new limit mem 4139G"
    fi
}

function test_mfkb_newlimit_mem4139G_toolow() {

    #arrange
    OS_VERSION='15.6'
    path_to_min_free_kbytes="${PROGRAM_DIR}/mock_min_free_kbytes"
    echo 262100 > "${path_to_min_free_kbytes}"
    LIB_PLATF_RAM_MiB_AVAILABLE=4238336

    #act
    check_2310_vm_min_free_kbytes

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for new limit mem 4139G too low"
    fi
}


function set_up_before_script() {

    # Disable errexit - bashunit enables it but sourced files may return non-zero
    set +eE

    # Skip if already loaded (bashunit runs all tests in same session)
    [[ -n "${_2310_test_loaded:-}" ]] && return 0
    _2310_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/2310_vm_min_free_kbytes.check
    source "${PROGRAM_DIR}/../../lib/check/2310_vm_min_free_kbytes.check"

}

function set_up() {

    OS_VERSION=''
    LIB_PLATF_RAM_MiB_AVAILABLE=0
    echo 0 > "${PROGRAM_DIR}/mock_min_free_kbytes"

}

function tear_down() {

    rm -f "${PROGRAM_DIR}/mock_min_free_kbytes"

}

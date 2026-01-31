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
is_root_user=0
path_to_host_profile=''

# Mock functions
LIB_FUNC_IS_ROOT() { return ${is_root_user} ; }
LIB_FUNC_TRIM_LEFT() { printf '%s' "${1#"${1%%[![:space:]]*}"}" ; }
LIB_FUNC_TRIM_RIGHT() { printf '%s' "${1%"${1##*[![:space:]]}"}" ; }
LIB_FUNC_TRIM() {
    : "$(LIB_FUNC_TRIM_LEFT "$1")"
    : "$(LIB_FUNC_TRIM_RIGHT "$_")"
    printf '%s' "$_"
}
LIB_FUNC_STRINGCONTAIN() { [[ "$1" == *"$2"* ]] ; }


function test_not_root_user() {

    #arrange
    is_root_user=1

    #act
    check_3120_ip_port_hostagent

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for not root user"
    fi
}

function test_host_profile_not_found() {

    #arrange
    path_to_host_profile="${PROGRAM_DIR}/mock_host_profile_nonexistent"

    #act
    check_3120_ip_port_hostagent

    #assert
    if [[ $? -ne 3 ]]; then
        bashunit::fail "Expected RC=3 (skipped) for host profile not found"
    fi
}

function test_reserved_port_disabled() {

    #arrange
    echo 'reserved_port/enable = false' > "${path_to_host_profile}"

    #act
    check_3120_ip_port_hostagent

    #assert
    if [[ $? -ne 3 ]]; then
        bashunit::fail "Expected RC=3 (skipped) for reserved port disabled"
    fi
}

function test_valid_configuration() {

    #arrange
    {
        echo 'reserved_port/enable = true'
        echo 'reserved_port/product_list = HANA,ABAP,J2EE'
        echo 'reserved_port/instance_list = 00,01,02'
    } > "${path_to_host_profile}"

    #act
    check_3120_ip_port_hostagent

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for valid configuration"
    fi
}

function test_invalid_product_list() {

    #arrange
    {
        echo 'reserved_port/enable = true'
        echo 'reserved_port/product_list = HANA,INVALID_PRODUCT,ABAP'
        echo 'reserved_port/instance_list = 00,01'
    } > "${path_to_host_profile}"

    #act
    check_3120_ip_port_hostagent

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for invalid product list"
    fi
}

function test_missing_product_list() {

    #arrange
    {
        echo 'reserved_port/enable = true'
        echo 'reserved_port/instance_list = 00,01'
    } > "${path_to_host_profile}"

    #act
    check_3120_ip_port_hostagent

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for missing product list"
    fi
}

function test_missing_instance_list() {

    #arrange
    {
        echo 'reserved_port/enable = true'
        echo 'reserved_port/product_list = HANA,ABAP'
    } > "${path_to_host_profile}"

    #act
    check_3120_ip_port_hostagent

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for missing instance list"
    fi
}

function test_empty_product_list() {

    #arrange
    {
        echo 'reserved_port/enable = true'
        echo 'reserved_port/product_list ='
        echo 'reserved_port/instance_list = 00,01'
    } > "${path_to_host_profile}"

    #act
    check_3120_ip_port_hostagent

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for empty product list"
    fi
}

function test_all_valid_products() {

    #arrange
    {
        echo 'reserved_port/enable = true'
        echo 'reserved_port/product_list = HANA,HANAREP,XSA,ABAP,J2EE,SUITE,ETD,MDM,SYBASE,MAXDB,ORACLE,DB2,TREX,CONTENTSRV,BO,B1'
        echo 'reserved_port/instance_list = 00,01,02,03,04,05'
    } > "${path_to_host_profile}"

    #act
    check_3120_ip_port_hostagent

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for all valid products"
    fi
}

function test_mixed_valid_invalid_products() {

    #arrange
    {
        echo 'reserved_port/enable = true'
        echo 'reserved_port/product_list = HANA,INVALID1,ABAP,INVALID2'
        echo 'reserved_port/instance_list = 00,01'
    } > "${path_to_host_profile}"

    #act
    check_3120_ip_port_hostagent

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for mixed valid/invalid products"
    fi
}

function test_whitespace_in_product_list() {

    #arrange
    {
        echo 'reserved_port/enable = true'
        echo 'reserved_port/product_list =  HANA , ABAP , J2EE'
        echo 'reserved_port/instance_list = 00,01'
    } > "${path_to_host_profile}"

    #act
    check_3120_ip_port_hostagent

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for whitespace in product list"
    fi
}


function set_up_before_script() {

    # Disable errexit - bashunit enables it but sourced files may return non-zero
    set +eE

    # Skip if already loaded (bashunit runs all tests in same session)
    [[ -n "${_3120_test_loaded:-}" ]] && return 0
    _3120_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/3120_ip_port_hostagent.check
    source "${PROGRAM_DIR}/../../lib/check/3120_ip_port_hostagent.check"

}

function set_up() {

    path_to_host_profile="${PROGRAM_DIR}/mock_host_profile"
    : > "${path_to_host_profile}"  # Create empty file without content
    is_root_user=0

}

function tear_down() {

    rm -f "${PROGRAM_DIR}/mock_host_profile"

}

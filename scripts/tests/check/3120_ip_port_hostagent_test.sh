#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
readonly PROGRAM_DIR

#fake PREREQUISITE functions
LIB_FUNC_IS_ROOT() { return ${is_root_user} ; }
LIB_FUNC_TRIM_LEFT() { printf '%s' "${1#"${1%%[![:space:]]*}"}" ; }
LIB_FUNC_TRIM_RIGHT() { printf '%s' "${1%"${1##*[![:space:]]}"}" ; }
LIB_FUNC_TRIM() {
    : "$(LIB_FUNC_TRIM_LEFT "$1")"
    : "$(LIB_FUNC_TRIM_RIGHT "$_")"
    printf '%s' "$_"
}

LIB_FUNC_STRINGCONTAIN() { [[ "$1" == *"$2"* ]] ; }

# Variable to control root user simulation
is_root_user=0

test_not_root_user() {

    #arrange
    is_root_user=1

    #act
    check_3120_ip_port_hostagent

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_host_profile_not_found() {

    #arrange
    path_to_host_profile="${PROGRAM_DIR}/mock_host_profile_nonexistent"

    #act
    check_3120_ip_port_hostagent

    #assert
    assertEquals "CheckSkip? RC" '3' "$?"
}

test_reserved_port_disabled() {

    #arrange
    echo 'reserved_port/enable = false' > "${path_to_host_profile}"

    #act
    check_3120_ip_port_hostagent

    #assert
    assertEquals "CheckSkip? RC" '3' "$?"
}

test_valid_configuration() {

    #arrange
    {
        echo 'reserved_port/enable = true'
        echo 'reserved_port/product_list = HANA,ABAP,J2EE'
        echo 'reserved_port/instance_list = 00,01,02'
    } > "${path_to_host_profile}"

    #act
    check_3120_ip_port_hostagent

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_invalid_product_list() {

    #arrange
    {
        echo 'reserved_port/enable = true'
        echo 'reserved_port/product_list = HANA,INVALID_PRODUCT,ABAP'
        echo 'reserved_port/instance_list = 00,01'
    } > "${path_to_host_profile}"

    #act
    check_3120_ip_port_hostagent

    #assert
    assertEquals "CheckWarning? RC" '1' "$?"
}

test_missing_product_list() {

    #arrange
    {
        echo 'reserved_port/enable = true'
        echo 'reserved_port/instance_list = 00,01'
    } > "${path_to_host_profile}"

    #act
    check_3120_ip_port_hostagent

    #assert
    assertEquals "CheckWarning? RC" '1' "$?"
}

test_missing_instance_list() {

    #arrange
    {
        echo 'reserved_port/enable = true'
        echo 'reserved_port/product_list = HANA,ABAP'
    } > "${path_to_host_profile}"

    #act
    check_3120_ip_port_hostagent

    #assert
    assertEquals "CheckWarning? RC" '1' "$?"
}

test_empty_product_list() {

    #arrange
    {
        echo 'reserved_port/enable = true'
        echo 'reserved_port/product_list ='
        echo 'reserved_port/instance_list = 00,01'
    } > "${path_to_host_profile}"

    #act
    check_3120_ip_port_hostagent

    #assert
    assertEquals "CheckWarning? RC" '1' "$?"
}

test_all_valid_products() {

    #arrange
    {
        echo 'reserved_port/enable = true'
        echo 'reserved_port/product_list = HANA,HANAREP,XSA,ABAP,J2EE,SUITE,ETD,MDM,SYBASE,MAXDB,ORACLE,DB2,TREX,CONTENTSRV,BO,B1'
        echo 'reserved_port/instance_list = 00,01,02,03,04,05'
    } > "${path_to_host_profile}"

    #act
    check_3120_ip_port_hostagent

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_mixed_valid_invalid_products() {

    #arrange
    {
        echo 'reserved_port/enable = true'
        echo 'reserved_port/product_list = HANA,INVALID1,ABAP,INVALID2'
        echo 'reserved_port/instance_list = 00,01'
    } > "${path_to_host_profile}"

    #act
    check_3120_ip_port_hostagent

    #assert
    assertEquals "CheckWarning? RC" '1' "$?"
}

test_whitespace_in_product_list() {

    #arrange
    {
        echo 'reserved_port/enable = true'
        echo 'reserved_port/product_list =  HANA , ABAP , J2EE'
        echo 'reserved_port/instance_list = 00,01'
    } > "${path_to_host_profile}"

    #act
    check_3120_ip_port_hostagent

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/3120_ip_port_hostagent.check
    source "${PROGRAM_DIR}/../../lib/check/3120_ip_port_hostagent.check"

    export avoidDoubleTearDownExecution=true

}

oneTimeTearDown() {

    if ${avoidDoubleTearDownExecution:-false}; then

        rm -f "${PROGRAM_DIR}/mock_host_profile"

        unset -v avoidDoubleTearDownExecution
    fi
}

setUp() {

    path_to_host_profile="${PROGRAM_DIR}/mock_host_profile"
    : > "${path_to_host_profile}"  # Create empty file without content
    is_root_user=0

}

#tearDown

#Import Libraries
# - order is important - sourcing shunit triggers testing
# - that's also the reason, why it could not be done during oneTimeSetup

#Load and run shUnit2
#shellcheck source=../shunit2
source "${PROGRAM_DIR}/../shunit2"
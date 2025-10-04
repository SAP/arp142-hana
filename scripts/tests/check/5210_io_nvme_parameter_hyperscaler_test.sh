#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
[[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
readonly PROGRAM_DIR

#fake PREREQUISITE functions
LIB_FUNC_IS_CLOUD_AMAZON() { return ${is_amazon_cloud} ; }
LIB_FUNC_IS_CLOUD_MICROSOFT() { return ${is_microsoft_cloud} ; }

# Variables to control cloud platform simulation
is_amazon_cloud=1
is_microsoft_cloud=1

test_not_on_hyperscaler() {

    #arrange
    is_amazon_cloud=1
    is_microsoft_cloud=1

    #act
    check_5210_io_nvme_parameter_hyperscaler

    #assert
    assertEquals "CheckSkip? RC" '3' "$?"
}

test_on_amazon_cloud() {

    #arrange
    is_amazon_cloud=0
    is_microsoft_cloud=1
    echo "240" > "${PROGRAM_DIR}/mock_nvme_timeout"
    path_to_nvme_timeout="${PROGRAM_DIR}/mock_nvme_timeout"

    #act
    check_5210_io_nvme_parameter_hyperscaler

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_on_microsoft_cloud() {

    #arrange
    is_amazon_cloud=1
    is_microsoft_cloud=0
    echo "240" > "${PROGRAM_DIR}/mock_nvme_timeout"
    path_to_nvme_timeout="${PROGRAM_DIR}/mock_nvme_timeout"

    #act
    check_5210_io_nvme_parameter_hyperscaler

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_nvme_timeout_file_not_found() {

    #arrange
    is_amazon_cloud=0
    is_microsoft_cloud=1
    path_to_nvme_timeout="${PROGRAM_DIR}/nonexistent_nvme_timeout"

    #act
    check_5210_io_nvme_parameter_hyperscaler

    #assert
    assertEquals "CheckSkip? RC" '3' "$?"
}

test_recommended_value_exact_match() {

    #arrange
    is_amazon_cloud=0
    is_microsoft_cloud=1
    echo "240" > "${PROGRAM_DIR}/mock_nvme_timeout"
    path_to_nvme_timeout="${PROGRAM_DIR}/mock_nvme_timeout"

    #act
    check_5210_io_nvme_parameter_hyperscaler

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_value_higher_than_recommended() {

    #arrange
    is_amazon_cloud=0
    is_microsoft_cloud=1
    echo "300" > "${PROGRAM_DIR}/mock_nvme_timeout"
    path_to_nvme_timeout="${PROGRAM_DIR}/mock_nvme_timeout"

    #act
    check_5210_io_nvme_parameter_hyperscaler

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_value_lower_than_recommended() {

    #arrange
    is_amazon_cloud=0
    is_microsoft_cloud=1
    echo "200" > "${PROGRAM_DIR}/mock_nvme_timeout"
    path_to_nvme_timeout="${PROGRAM_DIR}/mock_nvme_timeout"

    #act
    check_5210_io_nvme_parameter_hyperscaler

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_boundary_value_one_below() {

    #arrange
    is_amazon_cloud=0
    is_microsoft_cloud=1
    echo "239" > "${PROGRAM_DIR}/mock_nvme_timeout"
    path_to_nvme_timeout="${PROGRAM_DIR}/mock_nvme_timeout"

    #act
    check_5210_io_nvme_parameter_hyperscaler

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_boundary_value_one_above() {

    #arrange
    is_amazon_cloud=0
    is_microsoft_cloud=1
    echo "241" > "${PROGRAM_DIR}/mock_nvme_timeout"
    path_to_nvme_timeout="${PROGRAM_DIR}/mock_nvme_timeout"

    #act
    check_5210_io_nvme_parameter_hyperscaler

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_empty_file() {

    #arrange
    is_amazon_cloud=0
    is_microsoft_cloud=1
    echo "" > "${PROGRAM_DIR}/mock_nvme_timeout"
    path_to_nvme_timeout="${PROGRAM_DIR}/mock_nvme_timeout"

    #act
    check_5210_io_nvme_parameter_hyperscaler

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_zero_value() {

    #arrange
    is_amazon_cloud=0
    is_microsoft_cloud=1
    echo "0" > "${PROGRAM_DIR}/mock_nvme_timeout"
    path_to_nvme_timeout="${PROGRAM_DIR}/mock_nvme_timeout"

    #act
    check_5210_io_nvme_parameter_hyperscaler

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_value_with_whitespace() {

    #arrange
    is_amazon_cloud=0
    is_microsoft_cloud=1
    echo " 240 " > "${PROGRAM_DIR}/mock_nvme_timeout"
    path_to_nvme_timeout="${PROGRAM_DIR}/mock_nvme_timeout"

    #act
    check_5210_io_nvme_parameter_hyperscaler

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_very_large_value() {

    #arrange
    is_amazon_cloud=0
    is_microsoft_cloud=1
    echo "999999" > "${PROGRAM_DIR}/mock_nvme_timeout"
    path_to_nvme_timeout="${PROGRAM_DIR}/mock_nvme_timeout"

    #act
    check_5210_io_nvme_parameter_hyperscaler

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_microsoft_cloud_with_low_value() {

    #arrange
    is_amazon_cloud=1
    is_microsoft_cloud=0
    echo "100" > "${PROGRAM_DIR}/mock_nvme_timeout"
    path_to_nvme_timeout="${PROGRAM_DIR}/mock_nvme_timeout"

    #act
    check_5210_io_nvme_parameter_hyperscaler

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/5210_io_nvme_parameter_hyperscaler.check
    source "${PROGRAM_DIR}/../../lib/check/5210_io_nvme_parameter_hyperscaler.check"

    export avoidDoubleTearDownExecution=true

}

oneTimeTearDown() {

    if ${avoidDoubleTearDownExecution:-false}; then

        rm -f "${PROGRAM_DIR}/mock_nvme_timeout"

        unset -v avoidDoubleTearDownExecution
    fi
}

setUp() {

    # Default path - can be overridden by individual tests
    path_to_nvme_timeout="/sys/module/nvme_core/parameters/io_timeout"
    is_amazon_cloud=1
    is_microsoft_cloud=1

    # Clean up any existing mock files
    rm -f "${PROGRAM_DIR}/mock_nvme_timeout"

}

#tearDown

#Import Libraries
# - order is important - sourcing shunit triggers testing
# - that's also the reason, why it could not be done during oneTimeSetup

#Load and run shUnit2
#shellcheck source=../shunit2
source "${PROGRAM_DIR}/../shunit2"

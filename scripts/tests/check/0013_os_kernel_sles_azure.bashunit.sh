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
OS_LEVEL=''

# Mock functions
LIB_FUNC_IS_CLOUD_MICROSOFT() { return 0 ; }
LIB_FUNC_IS_SLES() { return 0 ; }


function test_kernel_azure_not_supported() {

    #arrange
    OS_LEVEL='4.12.14-122.103-azure'

    #act
    check_0013_os_kernel_sles_azure

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for Azure kernel"
    fi
}

function test_kernel_default_supported() {

    #arrange
    OS_LEVEL='4.12.14-122.103-default'

    #act
    check_0013_os_kernel_sles_azure

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for default kernel"
    fi
}


function set_up_before_script() {

    # Disable errexit - bashunit enables it but sourced files may return non-zero
    set +eE

    # Skip if already loaded (bashunit runs all tests in same session)
    [[ -n "${_0013_test_loaded:-}" ]] && return 0
    _0013_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/0013_os_kernel_sles_azure.check
    source "${PROGRAM_DIR}/../../lib/check/0013_os_kernel_sles_azure.check"

}

function set_up() {

    # Reset mock variables
    OS_LEVEL=

}

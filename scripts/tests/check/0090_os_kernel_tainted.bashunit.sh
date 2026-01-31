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

# Mock path for kernel tainted
path_to_kernel_tainted=''


function test_kernel_tainted_set0_untainted_ok() {

    #arrange
    echo 0 > "${path_to_kernel_tainted}"

    #act
    check_0090_os_kernel_tainted

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for untainted kernel"
    fi
}

function test_kernel_tainted_set1_tainted_error() {

    #arrange
    echo 1 > "${path_to_kernel_tainted}"

    #act
    check_0090_os_kernel_tainted

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for tainted kernel (flag 1)"
    fi
}

function test_kernel_tainted_set8_tainted_warning() {

    #arrange
    echo 8 > "${path_to_kernel_tainted}"

    #act
    check_0090_os_kernel_tainted

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for tainted kernel (flag 8)"
    fi
}

function test_kernel_tainted_set_non_listed_tainted_warning() {

    #arrange
    echo 1048576 > "${path_to_kernel_tainted}"

    #act
    check_0090_os_kernel_tainted

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for tainted kernel (non-listed flag)"
    fi
}

function test_kernel_tainted_set15_tainted_error() {

    #arrange
    echo 15 > "${path_to_kernel_tainted}"

    #act
    check_0090_os_kernel_tainted

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for tainted kernel (flag 15)"
    fi
}


function set_up_before_script() {

    # Disable errexit - bashunit enables it but sourced files may return non-zero
    set +eE

    # Skip if already loaded (bashunit runs all tests in same session)
    [[ -n "${_0090_test_loaded:-}" ]] && return 0
    _0090_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/0090_os_kernel_tainted.check
    source "${PROGRAM_DIR}/../../lib/check/0090_os_kernel_tainted.check"

}

function set_up() {

    # Create temp file for mock kernel tainted path
    path_to_kernel_tainted="${PROGRAM_DIR}/mock_kernel_tainted"
    echo 0 > "${path_to_kernel_tainted}"

}

function tear_down() {

    # Clean up mock file
    if [[ -f "${path_to_kernel_tainted}" ]]; then
        rm -f "${path_to_kernel_tainted}"
    fi

}

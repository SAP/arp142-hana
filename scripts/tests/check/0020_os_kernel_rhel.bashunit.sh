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
OS_LEVEL=''
LIB_FUNC_NORMALIZE_KERNEL_RETURN=''
COMPARE_VERSIONS_RC=0

# Mock functions
LIB_FUNC_IS_INTEL() { return 0 ; }
LIB_FUNC_IS_RHEL() { return 0 ; }
LIB_FUNC_NORMALIZE_KERNEL() {
    LIB_FUNC_NORMALIZE_KERNEL_RETURN="${1%%.el*}"
}

LIB_FUNC_COMPARE_VERSIONS() {
    COMPARE_VERSIONS_ARGUMENTS=("$1" "$2")
    # shellcheck disable=SC2086
    return $COMPARE_VERSIONS_RC ;
}

assert_check_processed() {
    local rc=$1
    local context="${2:-}"
    assert_not_equals 99 "${rc}" "Check must be processed${context:+ in }${context}"
}

function test_rhel_not_supported() {

    #arrange
    OS_VERSION='6.9'

    #act
    check_0020_os_kernel_rhel
    local rc=$?

    #assert
    assert_check_processed "${rc}" 'unsupported RHEL'
    assert_exit_code 2 'Expected RC=2 (error) for unsupported RHEL' "${rc}"
}

function test_rhel_supported_kernel_tolow() {

    #arrange
    OS_VERSION='8.10'
    COMPARE_VERSIONS_RC=2

    #act
    check_0020_os_kernel_rhel
    local rc=$?

    #assert
    assert_check_processed "${rc}" 'kernel too low'
    assert_exit_code 2 'Expected RC=2 (error) for kernel too low' "${rc}"
}

function test_rhel_supported_kernel_ok() {

    #arrange
    OS_VERSION='8.10'
    COMPARE_VERSIONS_RC=1

    #act
    check_0020_os_kernel_rhel
    local rc=$?

    #assert
    assert_check_processed "${rc}" 'supported kernel'
    assert_exit_code 0 'Expected RC=0 (ok) for supported kernel' "${rc}"
}

function test_rhel10_supported_kernel_ok() {

    #arrange
    OS_VERSION='10.0'
    COMPARE_VERSIONS_RC=1

    #act
    check_0020_os_kernel_rhel
    local rc=$?

    #assert
    assert_check_processed "${rc}" 'RHEL 10.0 supported kernel'
    assert_exit_code 0 'Expected RC=0 (ok) for RHEL 10.0 supported kernel' "${rc}"
}

function test_rhel10_supported_kernel_tolow() {
    #arrange
    OS_VERSION='10.0'
    COMPARE_VERSIONS_RC=2

    #act
    check_0020_os_kernel_rhel
    local rc=$?

    #assert
    assert_check_processed "${rc}" 'RHEL 10.0 kernel too low'
    assert_exit_code 2 'Expected RC=2 (error) for RHEL 10.0 kernel too low' "${rc}"
}

function test_rhel102_supported_kernel_ok() {

    #arrange
    OS_VERSION='10.2'
    COMPARE_VERSIONS_RC=1

    #act
    check_0020_os_kernel_rhel
    local rc=$?

    #assert
    assert_check_processed "${rc}" 'RHEL 10.2 supported kernel'
    assert_exit_code 0 'Expected RC=0 (ok) for RHEL 10.2 supported kernel' "${rc}"
    assert_equals '6.12.0-211.63.1' "${COMPARE_VERSIONS_ARGUMENTS[1]}"
}

function test_rhel102_supported_kernel_tolow() {

    #arrange
    OS_VERSION='10.2'
    COMPARE_VERSIONS_RC=2

    #act
    check_0020_os_kernel_rhel
    local rc=$?

    #assert
    assert_check_processed "${rc}" 'RHEL 10.2 kernel too low'
    assert_exit_code 2 'Expected RC=2 (error) for RHEL 10.2 kernel too low' "${rc}"
}


function set_up_before_script() {

    # Disable errexit - bashunit enables it but sourced files may return non-zero
    set +eE

    # Skip if already loaded (bashunit runs all tests in same session)
    [[ -n "${_0020_test_loaded:-}" ]] && return 0
    _0020_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/0020_os_kernel_rhel.check
    source "${PROGRAM_DIR}/../../lib/check/0020_os_kernel_rhel.check"

}

function set_up() {

    # Reset mock variables
    OS_VERSION=
    OS_LEVEL=
    LIB_FUNC_NORMALIZE_KERNEL_RETURN=
    COMPARE_VERSIONS_RC=0
    COMPARE_VERSIONS_ARGUMENTS=()

}

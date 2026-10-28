#!/usr/bin/env bash
set -u  # treat unset variables as an error

if [[ -z "${PROGRAM_DIR:-}" ]]; then
    PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
    [[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
fi

# Mock variables
OS_VERSION=''

# Mock functions
LIB_FUNC_IS_RHEL() { return 0 ; }
LIB_FUNC_IS_RHEL4SAP() { return 0 ; }

assert_check_processed() {
    local rc=$1
    local context="${2:-}"
    assert_not_equals 99 "${rc}" "Check must be processed${context:+ in }${context}"
}

function test_rhel_out_of_lifetime() {

    #arrange
    OS_VERSION='6.9'

    #act
    check_0001_os_support_rhel
    local rc=$?

    #assert
    assert_check_processed "${rc}" 'RHEL out of lifetime'
    assert_exit_code 2 'Expected RC=2 (error) for RHEL out of lifetime' "${rc}"
}

function test_rhel_not_supported() {

    #arrange
    OS_VERSION='7.8'

    #act
    check_0001_os_support_rhel
    local rc=$?

    #assert
    assert_check_processed "${rc}" 'RHEL not supported'
    assert_exit_code 2 'Expected RC=2 (error) for RHEL not supported' "${rc}"
}

function test_rhel_supported() {

    #arrange
    OS_VERSION='9.2'

    #act
    check_0001_os_support_rhel
    local rc=$?

    #assert
    assert_check_processed "${rc}" 'RHEL supported'
    assert_exit_code 0 'Expected RC=0 (ok) for RHEL supported' "${rc}"
}

function test_rhel_not_handled() {

    #arrange
    OS_VERSION='9.9'

    #act
    check_0001_os_support_rhel
    local rc=$?

    #assert
    assert_check_processed "${rc}" 'RHEL not handled'
    assert_exit_code 2 'Expected RC=2 (error) for RHEL not handled' "${rc}"
}

function test_rhel10_supported() {

    #arrange
    OS_VERSION='10.0'

    #act
    local rc=0
    check_0001_os_support_rhel || rc=$?

    #assert
    assert_check_processed "${rc}" 'RHEL 10.0 supported'
    assert_exit_code 0 'Expected RC=0 (ok) for RHEL 10.0 supported' "${rc}"
}

function test_rhel102_supported() {

    #arrange
    OS_VERSION='10.2'

    #act
    local rc=0
    check_0001_os_support_rhel || rc=$?

    #assert
    assert_check_processed "${rc}" 'RHEL 10.2 supported'
    assert_exit_code 0 'Expected RC=0 (ok) for RHEL 10.2 supported' "${rc}"
}


function set_up_before_script() {

    # Disable errexit - bashunit enables it but sourced files may return non-zero
    set +eE

    # Skip if already loaded (bashunit runs all tests in same session)
    [[ -n "${_0001_test_loaded:-}" ]] && return 0
    _0001_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/0001_os_support_rhel.check
    source "${PROGRAM_DIR}/../../lib/check/0001_os_support_rhel.check"

}

function set_up() {

    # Reset mock variables
    # shellcheck disable=SC2034
    OS_VERSION=
    LIB_FUNC_IS_RHEL() { return 0 ; }
    LIB_FUNC_IS_RHEL4SAP() { return 0 ; }

}

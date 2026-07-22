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
OS_VERSION='9.4'
TEST_SELINUX_MODE='Disabled'

# Mock functions
LIB_FUNC_IS_RHEL() { return 0 ; }
LIB_FUNC_IS_SLES() { return 1 ; }

# Mock LIB_FUNC_STRINGCONTAIN - checks if first arg contains second arg
LIB_FUNC_STRINGCONTAIN() {
    [[ "$1" == *"$2"* ]]
}

assert_check_processed() {
    local rc=$1
    local context="${2:-}"
    if [[ ${rc} -eq 99 ]]; then
        bashunit::fail "RC=99 (unprocessed) - check logic did not reach a conclusion${context:+ in }${context}"
    fi
}

function test_non_rhel_non_sles_skipped() {

    #arrange
    LIB_FUNC_IS_RHEL() { return 1 ; }
    LIB_FUNC_IS_SLES() { return 1 ; }

    #act
    check_0500_selinux
    local rc=$?

    #assert
    if [[ ${rc} -ne 3 ]]; then
        bashunit::fail "Expected RC=3 (skipped) for non-RHEL/non-SLES"
    fi
    assert_true true
}

function test_rhel9_requires_disabled() {

    #arrange
    LIB_FUNC_IS_RHEL() { return 0 ; }
    LIB_FUNC_IS_SLES() { return 1 ; }
    OS_VERSION='9.4'
    TEST_SELINUX_MODE='Disabled'

    #act
    check_0500_selinux
    local rc=$?

    #assert
    assert_check_processed ${rc} 'RHEL9 disabled'
    if [[ ${rc} -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for RHEL9 with SELinux Disabled"
    fi
    assert_true true
}

function test_rhel7_requires_disabled() {

    #arrange
    LIB_FUNC_IS_RHEL() { return 0 ; }
    LIB_FUNC_IS_SLES() { return 1 ; }
    OS_VERSION='7.9'
    TEST_SELINUX_MODE='Disabled'

    #act
    check_0500_selinux
    local rc=$?

    #assert
    assert_check_processed ${rc} 'RHEL7 disabled'
    if [[ ${rc} -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for RHEL7 with SELinux Disabled"
    fi
    assert_true true
}

function test_rhel8_requires_disabled() {

    #arrange
    LIB_FUNC_IS_RHEL() { return 0 ; }
    LIB_FUNC_IS_SLES() { return 1 ; }
    OS_VERSION='8.8'
    TEST_SELINUX_MODE='Disabled'

    #act
    check_0500_selinux
    local rc=$?

    #assert
    assert_check_processed ${rc} 'RHEL8 disabled'
    if [[ ${rc} -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for RHEL8 with SELinux Disabled"
    fi
    assert_true true
}

function test_rhel9_permissive_is_error() {

    #arrange
    LIB_FUNC_IS_RHEL() { return 0 ; }
    LIB_FUNC_IS_SLES() { return 1 ; }
    OS_VERSION='9.4'
    TEST_SELINUX_MODE='Permissive'

    #act
    check_0500_selinux
    local rc=$?

    #assert
    assert_check_processed ${rc} 'RHEL9 permissive'
    if [[ ${rc} -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for RHEL9 with SELinux Permissive"
    fi
    assert_true true
}

function test_rhel10_permissive_is_ok() {

    #arrange
    LIB_FUNC_IS_RHEL() { return 0 ; }
    LIB_FUNC_IS_SLES() { return 1 ; }
    OS_VERSION='10.0'
    TEST_SELINUX_MODE='Permissive'

    #act
    check_0500_selinux
    local rc=$?

    #assert
    assert_check_processed ${rc} 'RHEL10 permissive'
    if [[ ${rc} -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for RHEL10 with SELinux Permissive"
    fi
    assert_true true
}

function test_rhel10_disabled_is_ok() {

    #arrange
    LIB_FUNC_IS_RHEL() { return 0 ; }
    LIB_FUNC_IS_SLES() { return 1 ; }
    OS_VERSION='10.0'
    TEST_SELINUX_MODE='Disabled'

    #act
    check_0500_selinux
    local rc=$?

    #assert
    assert_check_processed ${rc} 'RHEL10 disabled'
    if [[ ${rc} -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for RHEL10 with SELinux Disabled"
    fi
    assert_true true
}

function test_rhel10_enforcing_is_error() {

    #arrange
    LIB_FUNC_IS_RHEL() { return 0 ; }
    LIB_FUNC_IS_SLES() { return 1 ; }
    OS_VERSION='10.0'
    TEST_SELINUX_MODE='Enforcing'

    #act
    check_0500_selinux
    local rc=$?

    #assert
    assert_check_processed ${rc} 'RHEL10 enforcing'
    if [[ ${rc} -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for RHEL10 with SELinux Enforcing"
    fi
    assert_true true
}

function test_rhel9_enforcing_is_error() {

    #arrange
    LIB_FUNC_IS_RHEL() { return 0 ; }
    LIB_FUNC_IS_SLES() { return 1 ; }
    OS_VERSION='9.4'
    TEST_SELINUX_MODE='Enforcing'

    #act
    check_0500_selinux
    local rc=$?

    #assert
    assert_check_processed ${rc} 'RHEL9 enforcing'
    if [[ ${rc} -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for RHEL9 with SELinux Enforcing"
    fi
    assert_true true
}

function test_sles12_skipped() {

    #arrange
    LIB_FUNC_IS_RHEL() { return 1 ; }
    LIB_FUNC_IS_SLES() { return 0 ; }
    OS_VERSION='12.5'
    TEST_SELINUX_MODE='Disabled'

    #act
    check_0500_selinux
    local rc=$?

    #assert
    if [[ ${rc} -ne 3 ]]; then
        bashunit::fail "Expected RC=3 (skipped) for SLES12"
    fi
    assert_true true
}

function test_sles15_skipped() {

    #arrange
    LIB_FUNC_IS_RHEL() { return 1 ; }
    LIB_FUNC_IS_SLES() { return 0 ; }
    OS_VERSION='15.6'
    TEST_SELINUX_MODE='Permissive'

    #act
    check_0500_selinux
    local rc=$?

    #assert
    if [[ ${rc} -ne 3 ]]; then
        bashunit::fail "Expected RC=3 (skipped) for SLES15"
    fi
    assert_true true
}

function test_sles16_permissive_is_ok() {

    #arrange
    LIB_FUNC_IS_RHEL() { return 1 ; }
    LIB_FUNC_IS_SLES() { return 0 ; }
    OS_VERSION='16.0'
    TEST_SELINUX_MODE='Permissive'

    #act
    check_0500_selinux
    local rc=$?

    #assert
    assert_check_processed ${rc} 'SLES16 permissive'
    if [[ ${rc} -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for SLES16 with SELinux Permissive"
    fi
    assert_true true
}

function test_sles16_disabled_is_ok() {

    #arrange
    LIB_FUNC_IS_RHEL() { return 1 ; }
    LIB_FUNC_IS_SLES() { return 0 ; }
    OS_VERSION='16.0'
    TEST_SELINUX_MODE='Disabled'

    #act
    check_0500_selinux
    local rc=$?

    #assert
    assert_check_processed ${rc} 'SLES16 disabled'
    if [[ ${rc} -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for SLES16 with SELinux Disabled"
    fi
    assert_true true
}

function test_sles16_enforcing_is_error() {

    #arrange
    LIB_FUNC_IS_RHEL() { return 1 ; }
    LIB_FUNC_IS_SLES() { return 0 ; }
    OS_VERSION='16.0'
    TEST_SELINUX_MODE='Enforcing'

    #act
    check_0500_selinux
    local rc=$?

    #assert
    assert_check_processed ${rc} 'SLES16 enforcing'
    if [[ ${rc} -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for SLES16 with SELinux Enforcing"
    fi
    assert_true true
}

function test_unsupported_sles_release_warns() {

    #arrange
    LIB_FUNC_IS_RHEL() { return 1 ; }
    LIB_FUNC_IS_SLES() { return 0 ; }
    OS_VERSION='11.4'
    TEST_SELINUX_MODE='Disabled'

    #act
    check_0500_selinux
    local rc=$?

    #assert
    if [[ ${rc} -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for unsupported SLES release"
    fi
    assert_true true
}

function set_up_before_script() {

    # Disable errexit - bashunit enables it but sourced files may return non-zero
    set +eE

    # Skip if already loaded (bashunit runs all tests in same session)
    [[ -n "${_0500_test_loaded:-}" ]] && return 0
    _0500_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/0500_selinux.check
    source "${PROGRAM_DIR}/../../lib/check/0500_selinux.check"

}

function set_up() {

    # Reset mock variables
    OS_VERSION='9.4'
    TEST_SELINUX_MODE='Disabled'

    # Reset mock functions to default (RHEL)
    LIB_FUNC_IS_RHEL() { return 0 ; }
    LIB_FUNC_IS_SLES() { return 1 ; }

}

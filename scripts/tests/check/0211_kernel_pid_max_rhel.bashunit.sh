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
SYSTEMD_VERSION=''
TEST_KERNEL_PID_MAX=0
TEST_KERNEL_THREADS_MAX=0
RPM_RC=0

# Mock functions
LIB_FUNC_IS_RHEL() { return 0 ; }

rpm() {

    case "$*" in
        '-q --quiet'*)      return "${RPM_RC}" ;;

        '-q --queryformat'*) printf '%s' "${SYSTEMD_VERSION}" ;;
    esac

}


function test_systemd_not_installed() {

    #arrange
    RPM_RC=1
    SYSTEMD_VERSION='239'

    #act
    check_0211_kernel_pid_max_rhel

    #assert
    if [[ $? -ne 3 ]]; then
        bashunit::fail "Expected RC=3 (skipped) for systemd not installed"
    fi
}

function test_systemd_too_low() {

    #arrange
    RPM_RC=0
    SYSTEMD_VERSION='238'

    #act
    check_0211_kernel_pid_max_rhel

    #assert
    if [[ $? -ne 3 ]]; then
        bashunit::fail "Expected RC=3 (skipped) for systemd version too low"
    fi
}

function test_all_settings_correct() {

    #arrange
    RPM_RC=0
    SYSTEMD_VERSION='239'
    TEST_KERNEL_PID_MAX=4194304
    TEST_KERNEL_THREADS_MAX=250000

    #act
    check_0211_kernel_pid_max_rhel

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for all settings correct"
    fi
}

function test_pidmax_too_low() {

    #arrange
    RPM_RC=0
    SYSTEMD_VERSION='239'
    TEST_KERNEL_PID_MAX=4194303
    TEST_KERNEL_THREADS_MAX=250000

    #act
    check_0211_kernel_pid_max_rhel

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for pid_max too low"
    fi
}

function test_threadsmax_too_low() {

    #arrange
    RPM_RC=0
    SYSTEMD_VERSION='239'
    TEST_KERNEL_PID_MAX=4194304
    TEST_KERNEL_THREADS_MAX=249999

    #act
    check_0211_kernel_pid_max_rhel

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for threads-max too low"
    fi
}

function test_both_too_low() {

    #arrange
    RPM_RC=0
    SYSTEMD_VERSION='239'
    TEST_KERNEL_PID_MAX=4194303
    TEST_KERNEL_THREADS_MAX=249999

    #act
    check_0211_kernel_pid_max_rhel

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for both too low"
    fi
}


function set_up_before_script() {

    # Disable errexit - bashunit enables it but sourced files may return non-zero
    set +eE

    # Skip if already loaded (bashunit runs all tests in same session)
    [[ -n "${_0211_test_loaded:-}" ]] && return 0
    _0211_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/0211_kernel_pid_max_rhel.check
    source "${PROGRAM_DIR}/../../lib/check/0211_kernel_pid_max_rhel.check"

}

function set_up() {

    # Reset mock variables
    SYSTEMD_VERSION=''
    TEST_KERNEL_PID_MAX=0
    TEST_KERNEL_THREADS_MAX=0
    RPM_RC=0

}

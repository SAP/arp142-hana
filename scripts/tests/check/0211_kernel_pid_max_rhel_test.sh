#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
readonly PROGRAM_DIR

#mock PREREQUISITE functions
LIB_FUNC_IS_RHEL() { return 0 ; }

# still to mock for tests
# rpm -q --quiet systemd
# rpm -q --queryformat "%{VERSION}" systemd
# /proc/sys/kernel/pid_max
# /proc/sys/kernel/threads-max

SYSTEMD_VERSION=''
declare -i TEST_KERNEL_PID_MAX
declare -i TEST_KERNEL_THREADS_MAX
declare -i RPM_RC

rpm() {

    case "$*" in
        '-q --quiet'*)      return "${RPM_RC}" ;;

        '-q --queryformat'*) printf '%s' "${SYSTEMD_VERSION}" ;;
    esac

}

test_systemd_not_installed() {

    #arrange
    RPM_RC=1
    SYSTEMD_VERSION='239'

    #act
    check_0211_kernel_pid_max_rhel

    #assert
    assertEquals "CheckSkipped? RC" '3' "$?"
}

test_systemd_too_low() {

    #arrange
    RPM_RC=0
    SYSTEMD_VERSION='238'

    #act
    check_0211_kernel_pid_max_rhel

    #assert
    assertEquals "CheckSkipped? RC" '3' "$?"
}

test_all_settings_correct() {

    #arrange
    RPM_RC=0
    SYSTEMD_VERSION='239'
    TEST_KERNEL_PID_MAX=4194304
    TEST_KERNEL_THREADS_MAX=250000

    #act
    check_0211_kernel_pid_max_rhel

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_pidmax_too_low() {

    #arrange
    RPM_RC=0
    SYSTEMD_VERSION='239'
    TEST_KERNEL_PID_MAX=4194303
    TEST_KERNEL_THREADS_MAX=250000

    #act
    check_0211_kernel_pid_max_rhel

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_threadsmax_too_low() {

    #arrange
    RPM_RC=0
    SYSTEMD_VERSION='239'
    TEST_KERNEL_PID_MAX=4194304
    TEST_KERNEL_THREADS_MAX=249999

    #act
    check_0211_kernel_pid_max_rhel

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_both_too_low() {

    #arrange
    RPM_RC=0
    SYSTEMD_VERSION='239'
    TEST_KERNEL_PID_MAX=4194303
    TEST_KERNEL_THREADS_MAX=249999

    #act
    check_0211_kernel_pid_max_rhel

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

# testCompareTooBigNumbersShouldFail() {
#     local -i _rc

#     #The following tests should fail (test the tester)
#     LIB_COMPARE_TOOBIG_NUMBERS '1' '2'
#     _rc=$?
#     assertNotEquals 'test[1]: testing the tester failed' '0' "${_rc}"
#     assertNotEquals 'test[1]: testing the tester failed' '1' "${_rc}"

#     LIB_COMPARE_TOOBIG_NUMBERS '2' '2'
#     _rc=$?
#     assertNotEquals 'test[2]: testing the tester failed' '1' "${_rc}"
#     assertNotEquals 'test[2]: testing the tester failed' '2' "${_rc}"

#     LIB_COMPARE_TOOBIG_NUMBERS '2' '1'
#     _rc=$?
#     assertNotEquals 'test[3]: testing the tester failed' '0' "${_rc}"
#     assertNotEquals 'test[3]: testing the tester failed' '2' "${_rc}"
# }

oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/0211_kernel_pid_max_rhel.check
    source "${PROGRAM_DIR}/../../lib/check/0211_kernel_pid_max_rhel.check"

}

# oneTimeTearDown
# setUp
# tearDown

#Import Libraries
# - order is important - sourcing shunit triggers testing
# - that's also the reason, why it could not be done during oneTimeSetup

#Load and run shUnit2
#shellcheck source=../shunit2
source "${PROGRAM_DIR}/../shunit2"

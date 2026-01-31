#!/usr/bin/env bash
#------------------------------------------------------------------
# bashunit migration: 5010_io_scheduler_blockdevices_test.sh
# Tests for I/O scheduler check on block devices
#------------------------------------------------------------------
set -u

if [[ -z "${PROGRAM_DIR:-}" ]]; then
    PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
    [[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
fi

# Guard to avoid reloading
[[ -n "${_5010_io_scheduler_test_loaded:-}" ]] && return 0
_5010_io_scheduler_test_loaded=true

#mock PREREQUISITE functions
LIB_FUNC_IS_CLOUD_MICROSOFT() { return 1 ; }
LIB_FUNC_IS_CLOUD_AMAZON() { return 1 ; }
LIB_FUNC_IS_CLOUD_GOOGLE() { return 1 ; }
LIB_FUNC_IS_VIRT_VMWARE() { return 1 ; }
LIB_FUNC_IS_VIRT_KVM() { return 1 ; }
LIB_FUNC_IS_VIRT_XEN() { return 1 ; }
LIB_FUNC_IS_SLES() { return 0 ; }
LIB_FUNC_IS_RHEL() { return 1 ; }

LIB_FUNC_STRINGCONTAIN() { [[ -z "${1##*"$2"*}" ]] && [[ -z "$2" || -n "$1" ]]; }

# Mock variables
io_scheduler=()

grep() {
    case "$*" in
        *'scheduler' )  printf "%s\n" "${io_scheduler[@]}" ;;
        *)              command grep "$@" ;;
    esac
}

function test_1scheduler_ok() {
    #arrange
    io_scheduler=()
    io_scheduler+=('[noop]')

    #act
    check_5010_io_scheduler_blockdevices
    local rc=$?

    #assert
    if [[ "$rc" != '0' ]]; then
        bashunit::fail "Expected CheckOk RC=0 but got RC=$rc"
    fi
}

function test_1scheduler_wrong() {
    #arrange
    io_scheduler=()
    io_scheduler+=('[cfq]')

    #act
    check_5010_io_scheduler_blockdevices
    local rc=$?

    #assert
    if [[ "$rc" != '1' ]]; then
        bashunit::fail "Expected CheckWarning RC=1 but got RC=$rc"
    fi
}

function test_2scheduler_both_ok() {
    #arrange
    io_scheduler=()
    io_scheduler+=('[noop]')
    io_scheduler+=('[deadline]')

    #act
    check_5010_io_scheduler_blockdevices
    local rc=$?

    #assert
    if [[ "$rc" != '0' ]]; then
        bashunit::fail "Expected CheckOk RC=0 but got RC=$rc"
    fi
}

function test_2scheduler_both_wrong() {
    #arrange
    io_scheduler=()
    io_scheduler+=('[cfq]')
    io_scheduler+=('[anticipatory]')

    #act
    check_5010_io_scheduler_blockdevices
    local rc=$?

    #assert
    if [[ "$rc" != '1' ]]; then
        bashunit::fail "Expected CheckWarning RC=1 but got RC=$rc"
    fi
}

function test_2scheduler_1_wrong() {
    #arrange
    io_scheduler=()
    io_scheduler+=('[cfq]')
    io_scheduler+=('[mq-deadline]')

    #act
    check_5010_io_scheduler_blockdevices
    local rc=$?

    #assert
    if [[ "$rc" != '1' ]]; then
        bashunit::fail "Expected CheckWarning RC=1 but got RC=$rc"
    fi
}

function test_4scheduler_all_ok() {
    #arrange
    io_scheduler=()
    io_scheduler+=('[noop]')
    io_scheduler+=('[none]')
    io_scheduler+=('[deadline]')
    io_scheduler+=('[mq-deadline]')

    #act
    check_5010_io_scheduler_blockdevices
    local rc=$?

    #assert
    if [[ "$rc" != '0' ]]; then
        bashunit::fail "Expected CheckOk RC=0 but got RC=$rc"
    fi
}

function test_4scheduler_1_wrong() {
    #arrange
    io_scheduler=()
    io_scheduler+=('[cfq]')
    io_scheduler+=('[none]')
    io_scheduler+=('[deadline]')
    io_scheduler+=('[mq-deadline]')

    #act
    check_5010_io_scheduler_blockdevices
    local rc=$?

    #assert
    if [[ "$rc" != '1' ]]; then
        bashunit::fail "Expected CheckWarning RC=1 but got RC=$rc"
    fi
}

function set_up_before_script() {
    set +eE

    [[ -n "${HANA_HELPER_PROGVERSION:-}" ]] && return 0

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/5010_io_scheduler_blockdevices.check
    source "${PROGRAM_DIR}/../../lib/check/5010_io_scheduler_blockdevices.check"
}

function set_up() {
    io_scheduler=()
}

#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
readonly PROGRAM_DIR

#fake PREREQUISITE functions
LIB_FUNC_IS_CLOUD_MICROSOFT() { return 1 ; }
LIB_FUNC_IS_CLOUD_AMAZON() { return 1 ; }
LIB_FUNC_IS_CLOUD_GOOGLE() { return 1 ; }
LIB_FUNC_IS_VIRT_VMWARE() { return 1 ; }
LIB_FUNC_IS_VIRT_KVM() { return 1 ; }
LIB_FUNC_IS_VIRT_XEN() { return 1 ; }
LIB_FUNC_IS_SLES() { return 0 ; }
LIB_FUNC_IS_RHEL() { return 1 ; }

LIB_FUNC_STRINGCONTAIN() { [[ -z "${1##*"$2"*}" ]] && [[ -z "$2" || -n "$1" ]]; }

# still to mock for tests
# grep '/sys/block/sd*/queue/scheduler'
io_scheduler=''

grep() {
    #we fake <(grep --no-messages --only-matching --no-filename '\[.*\]' ${search_pattern} | sort --unique)
    case "$*" in

        *'scheduler' )  printf "%s\n" "${io_scheduler[@]}" ;;

        *)              command grep "$@" ;; # shunit2 requires grep
    esac
}

test_1scheduler_ok() {

    #arrange
    io_scheduler=()
    io_scheduler+=('[noop]')

    #act
    check_5010_io_scheduler_blockdevices

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}


test_1scheduler_wrong() {

    #arrange
    io_scheduler=()
    io_scheduler+=('[cfq]')

    #act
    check_5010_io_scheduler_blockdevices

    #assert
    assertEquals "CheckWarning? RC" '1' "$?"
}

test_2scheduler_both_ok() {

    #arrange
    io_scheduler=()
    io_scheduler+=('[noop]')
    io_scheduler+=('[deadline]')

    #act
    check_5010_io_scheduler_blockdevices

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_2scheduler_both_wrong() {

    #arrange
    io_scheduler=()
    io_scheduler+=('[cfq]')
    io_scheduler+=('[anticipatory]')

    #act
    check_5010_io_scheduler_blockdevices

    #assert
    assertEquals "CheckWarning? RC" '1' "$?"
}

test_2scheduler_1_wrong() {

    #arrange
    io_scheduler=()
    io_scheduler+=('[cfq]')
    io_scheduler+=('[mq-deadline]')

    #act
    check_5010_io_scheduler_blockdevices

    #assert
    assertEquals "CheckWarning? RC" '1' "$?"
}

test_4scheduler_all_ok() {

    #arrange
    io_scheduler=()
    io_scheduler+=('[noop]')
    io_scheduler+=('[none]')
    io_scheduler+=('[deadline]')
    io_scheduler+=('[mq-deadline]')

    #act
    check_5010_io_scheduler_blockdevices

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_4scheduler_1_wrong() {

    #arrange
    io_scheduler=()
    io_scheduler+=('[cfq]')
    io_scheduler+=('[none]')
    io_scheduler+=('[deadline]')
    io_scheduler+=('[mq-deadline]')

    #act
    check_5010_io_scheduler_blockdevices

    #assert
    assertEquals "CheckWarning? RC" '1' "$?"
}

oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/5010_io_scheduler_blockdevices.check
    source "${PROGRAM_DIR}/../../lib/check/5010_io_scheduler_blockdevices.check"

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

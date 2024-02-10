#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
readonly PROGRAM_DIR

#fake PREREQUISITE functions
LIB_FUNC_IS_CLOUD_AMAZON() { return 0 ; }

# still to mock for tests
# grep /sys/class/net/**/device/uevent
if_ena=''

grep() {

    #we fake (grep DRIVER=ena -rsH /sys/class/net/**/device/uevent)
    case "$*" in
        *'uevent')  [[ ${#if_ena[@]} -eq 0 ]] && : || printf "%s\n" "${if_ena[@]}" ;;

        *)          command grep "$@" ;; # shunit2 requires grep
    esac
}

test_0interface_error() {

    #arrange
    if_ena=()

    #act
    check_3302_ena_interfaces_amazon

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_1interface_warning() {

    #arrange
    if_ena=()
    if_ena+=('/sys/class/net/eth0/device/uevent:DRIVER=ena')

    #act
    check_3302_ena_interfaces_amazon

    #assert
    assertEquals "CheckWarning? RC" '1' "$?"
}

test_2interfaces_ok() {

    #arrange
    if_ena=()
    if_ena+=('/sys/class/net/eth0/device/uevent:DRIVER=ena')
    if_ena+=('/sys/class/net/eth1/device/uevent:DRIVER=ena')

    #act
    check_3302_ena_interfaces_amazon

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_4interfaces_ok() {

    #arrange
    if_ena=()
    if_ena+=('/sys/class/net/eth0/device/uevent:DRIVER=ena')
    if_ena+=('/sys/class/net/eth1/device/uevent:DRIVER=ena')
    if_ena+=('/sys/class/net/eth2/device/uevent:DRIVER=ena')
    if_ena+=('/sys/class/net/eth4/device/uevent:DRIVER=ena')

    #act
    check_3302_ena_interfaces_amazon

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}


 oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/3302_ena_interfaces_amazon.check
    source "${PROGRAM_DIR}/../../lib/check/3302_ena_interfaces_amazon.check"

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

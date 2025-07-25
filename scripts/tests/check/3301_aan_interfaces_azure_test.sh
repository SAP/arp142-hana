#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
readonly PROGRAM_DIR

#fake PREREQUISITE functions
LIB_FUNC_IS_CLOUD_MICROSOFT() { return 0 ; }

# still to mock for tests
# grep /sys/class/net/**/device/uevent
if_aan=''

grep() {

    #we fake (grep DRIVER=mana -rsH /sys/class/net/**/device/uevent)
    case "$*" in
        *'uevent')  [[ ${#if_aan[@]} -eq 0 ]] && : || printf "%s\n" "${if_aan[@]}" ;;

        *)          command grep "$@" ;; # shunit2 requires grep
    esac
}

test_0interface_error() {

    #arrange
    if_aan=()

    #act
    check_3301_network_accelerated_azure

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_1interface_ok() {

    #arrange
    if_aan=()
    if_aan+=('/sys/class/net/eth0/device/uevent:DRIVER=mana')

    #act
    check_3301_network_accelerated_azure

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_2interfaces_ok() {

    #arrange
    if_aan=()
    if_aan+=('/sys/class/net/eth0/device/uevent:DRIVER=mana')
    if_aan+=('/sys/class/net/eth1/device/uevent:DRIVER=mlx')

    #act
    check_3301_network_accelerated_azure

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_4interfaces_ok() {

    #arrange
    if_aan=()
    if_aan+=('/sys/class/net/eth0/device/uevent:DRIVER=mana')
    if_aan+=('/sys/class/net/eth1/device/uevent:DRIVER=mlx')
    if_aan+=('/sys/class/net/eth2/device/uevent:DRIVER=mlx')
    if_aan+=('/sys/class/net/eth4/device/uevent:DRIVER=mana')

    #act
    check_3301_network_accelerated_azure

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}


 oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/3301_network_accelerated_azure.check
    source "${PROGRAM_DIR}/../../lib/check/3301_network_accelerated_azure.check"

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

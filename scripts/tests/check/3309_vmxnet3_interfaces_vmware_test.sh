#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
[[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
readonly PROGRAM_DIR

#fake PREREQUISITE functions
LIB_FUNC_IS_VIRT_VMWARE() { return 0 ; }

# still to mock for tests
# grep /sys/class/net/**/device/uevent
if_vmxnet3=''

grep() {

    #we fake (grep DRIVER=vmxnet3 -rsH /sys/class/net/**/device/uevent)
    case "$*" in
        *'uevent')  [[ ${#if_vmxnet3[@]} -eq 0 ]] && : || printf "%s\n" "${if_vmxnet3[@]}" ;;

        *)          command grep "$@" ;; # shunit2 requires grep
    esac
}

test_0interface_error() {

    #arrange
    if_vmxnet3=()

    #act
    check_3309_vmxnet3_interfaces_vmware

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_1interface_warning() {

    #arrange
    if_vmxnet3=()
    if_vmxnet3+=('/sys/class/net/eth0/device/uevent:DRIVER=vmxnet3')

    #act
    check_3309_vmxnet3_interfaces_vmware

    #assert
    assertEquals "CheckWarning? RC" '1' "$?"
}

test_2interfaces_ok() {

    #arrange
    if_vmxnet3=()
    if_vmxnet3+=('/sys/class/net/eth0/device/uevent:DRIVER=vmxnet3')
    if_vmxnet3+=('/sys/class/net/eth1/device/uevent:DRIVER=vmxnet3')

    #act
    check_3309_vmxnet3_interfaces_vmware

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_4interfaces_ok() {

    #arrange
    if_vmxnet3=()
    if_vmxnet3+=('/sys/class/net/eth0/device/uevent:DRIVER=vmxnet3')
    if_vmxnet3+=('/sys/class/net/eth1/device/uevent:DRIVER=vmxnet3')
    if_vmxnet3+=('/sys/class/net/eth2/device/uevent:DRIVER=vmxnet3')
    if_vmxnet3+=('/sys/class/net/eth4/device/uevent:DRIVER=vmxnet3')

    #act
    check_3309_vmxnet3_interfaces_vmware

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}


 oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/3309_vmxnet3_interfaces_vmware.check
    source "${PROGRAM_DIR}/../../lib/check/3309_vmxnet3_interfaces_vmware.check"

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

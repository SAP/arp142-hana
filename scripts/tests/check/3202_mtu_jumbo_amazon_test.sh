#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
readonly PROGRAM_DIR

#fake PREREQUISITE functions
LIB_FUNC_IS_CLOUD_AMAZON() { return 0 ; }

# still to mock for tests
# grep /sys/class/net/*/mtu
if_mtu=''

grep() {

    #we fake (grep . -rsH /sys/class/net/*/mtu)
    case "$*" in
        *'mtu')     printf "%s\n" "${if_mtu[@]}" ;;

        *)              command grep "$*" ;; # shunit2 requires grep
    esac
}

test_1if_with_mtu_ok() {

    #arrange
    if_mtu=()
    if_mtu+=('/sys/class/net/eth0/mtu:1500')

    #act
    check_3202_mtu_jumbo_amazon

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_2if_with_loopback_ignore() {

    #arrange
    if_mtu=()
    if_mtu+=('/sys/class/net/eth0/mtu:1500')
    if_mtu+=('/sys/class/net/lo/mtu:65536')

    #act
    check_3202_mtu_jumbo_amazon

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_4if_with_eth1_mtu_toolow() {

    #arrange
    if_mtu=()
    if_mtu+=('/sys/class/net/eth0/mtu:1500')
    if_mtu+=('/sys/class/net/eth1/mtu:8999')
    if_mtu+=('/sys/class/net/eth1/mtu:9000')
    if_mtu+=('/sys/class/net/lo/mtu:65536')

    #act
    check_3202_mtu_jumbo_amazon

    #assert
    assertEquals "CheckWarning? RC" '1' "$?"
}

test_3if_with_eth1_mtu_tohigh() {

    #arrange
    if_mtu=()
    if_mtu+=('/sys/class/net/eth0/mtu:1500')
    if_mtu+=('/sys/class/net/eth1/mtu:9002')
    if_mtu+=('/sys/class/net/lo/mtu:65536')

    #act
    check_3202_mtu_jumbo_amazon

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_4if_with_mtu_ok() {

    #arrange
    if_mtu=()
    if_mtu+=('/sys/class/net/eth0/mtu:1500')
    if_mtu+=('/sys/class/net/eth1/mtu:9001')
    if_mtu+=('/sys/class/net/eth2/mtu:9001')
    if_mtu+=('/sys/class/net/lo/mtu:65536')

    #act
    check_3202_mtu_jumbo_amazon

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_2if_with_wrong_output_not_processed() {

    #arrange
    if_mtu=()
    if_mtu+=('/sys/class/net//mtu:9000')
    if_mtu+=('/sys/class/net/eth1/mtu:')

    #act
    check_3202_mtu_jumbo_amazon

    #assert
    assertEquals "CheckWarning? RC" '1' "$?"
}
 oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/3202_mtu_jumbo_amazon.check
    source "${PROGRAM_DIR}/../../lib/check/3202_mtu_jumbo_amazon.check"

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

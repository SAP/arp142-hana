#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
[[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
readonly PROGRAM_DIR

#fake PREREQUISITE functions
LIB_FUNC_IS_BARE_METAL() { return 1 ; }

# still to mock for tests
# grep /sys/devices/system/node/node*/cpulist
cpu_nodes=''

grep() {

    #we fake <(grep -H "^.*$" -r /sys/devices/system/node/node*/cpulist)
    case "$*" in
        *'cpulist')     printf "%s\n" "${cpu_nodes[@]}" ;;

        *)              command grep "$@" ;; # shunit2 requires grep
    esac
}

test_1numa_with_node_ok() {

    #arrange
    cpu_nodes=()
    cpu_nodes+=('/sys/devices/system/node/node6/cpulist:0-39')

    #act
    check_1230_cpu_distribution_virt

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_2numa_with_numa0_empty_ignore() {

    #arrange
    cpu_nodes=()
    cpu_nodes+=('/sys/devices/system/node/node0/cpulist:')
    cpu_nodes+=('/sys/devices/system/node/node6/cpulist:0-39')

    #act
    check_1230_cpu_distribution_virt

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}


test_2numa_with_both_nodes_same_cpu() {

    #arrange
    cpu_nodes=()
    cpu_nodes+=('/sys/devices/system/node/node0/cpulist:40-79')
    cpu_nodes+=('/sys/devices/system/node/node6/cpulist:0-39')

    #act
    check_1230_cpu_distribution_virt

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_2numa_with_numa0_multiple_cpu_ranges_simple() {

    #arrange
    cpu_nodes=()
    cpu_nodes+=('/sys/devices/system/node/node0/cpulist:40-59,60-79')
    cpu_nodes+=('/sys/devices/system/node/node6/cpulist:0-39')

    #act
    check_1230_cpu_distribution_virt

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_2numa_with_numa0_multiple_cpu_ranges_complicated() {

    #arrange
    cpu_nodes=()
    cpu_nodes+=('/sys/devices/system/node/node0/cpulist:0-7,16-23,32-39,48-55')
    cpu_nodes+=('/sys/devices/system/node/node6/cpulist:0-31')

    #act
    check_1230_cpu_distribution_virt

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_numa_ignore_nodes_with_no_cpus() {

    #arrange
    cpu_nodes=()
    cpu_nodes+=('/sys/devices/system/node/node0/cpulist:0-39')
    cpu_nodes+=('/sys/devices/system/node/node2/cpulist:')
    cpu_nodes+=('/sys/devices/system/node/node4/cpulist:0-39')
    cpu_nodes+=('/sys/devices/system/node/node6/cpulist:')

    #act
    check_1230_cpu_distribution_virt

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_2numa_with_both_out_margin() {

    #arrange
    cpu_nodes=()
    cpu_nodes+=('/sys/devices/system/node/node0/cpulist:0-15')
    cpu_nodes+=('/sys/devices/system/node/node6/cpulist:0-7')

    #act
    check_1230_cpu_distribution_virt

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_3numa_with_numa0_lt_margin() {

    #arrange
    cpu_nodes=()
    cpu_nodes+=('/sys/devices/system/node/node0/cpulist:0-21')
    cpu_nodes+=('/sys/devices/system/node/node4/cpulist:0-49')
    cpu_nodes+=('/sys/devices/system/node/node6/cpulist:0-49')

    #act
    check_1230_cpu_distribution_virt

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_3numa_with_numa0_gt_margin() {

    #arrange
    cpu_nodes=()
    cpu_nodes+=('/sys/devices/system/node/node0/cpulist:0-29')
    cpu_nodes+=('/sys/devices/system/node/node4/cpulist:0-19')
    cpu_nodes+=('/sys/devices/system/node/node6/cpulist:0-19')

    #act
    check_1230_cpu_distribution_virt

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}


 oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/1230_cpu_distribution_virt.check
    source "${PROGRAM_DIR}/../../lib/check/1230_cpu_distribution_virt.check"

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

#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
readonly PROGRAM_DIR

#fake PREREQUISITE functions
LIB_FUNC_IS_IBMPOWER() { return 0 ; }

# still to mock for tests
# grep /sys/devices/system/node/node*/meminfo
# grep /sys/devices/system/node/node*/cpulist
mem_nodes=''
cpu_nodes=''

grep() {

    #we fake <(grep -h -m1 'MemTotal' -r /sys/devices/system/node/node*/meminfo)
    #we fake <(grep -H "^.*$" -r /sys/devices/system/node/node*/cpulist)

    if [[ "$*" == *MemTotal* ]]; then
        printf "%s\n" "${mem_nodes[@]}"

    else
        printf "%s\n" "${cpu_nodes[@]}"
    fi

}

test_1numa_with_node_ok() {

    #arrange
    mem_nodes=()
    mem_nodes+=('Node 6 MemTotal:       502777024 kB')

    cpu_nodes=()
    cpu_nodes+=('/sys/devices/system/node/node6/cpulist:0-39')

    #act
    check_2230_numa_distribution_ibmpower

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_2numa_with_numa0_empty_ignore() {

    #arrange
    mem_nodes=()
    mem_nodes+=('Node 0 MemTotal:              0 kB')
    mem_nodes+=('Node 6 MemTotal:       502777024 kB')

    cpu_nodes=()
    cpu_nodes+=('/sys/devices/system/node/node0/cpulist:')
    cpu_nodes+=('/sys/devices/system/node/node6/cpulist:0-39')

    #act
    check_2230_numa_distribution_ibmpower

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_numa_different_number() {

    #arrange
    mem_nodes=()
    mem_nodes+=('Node 6 MemTotal:       502777024 kB')

    cpu_nodes=()
    cpu_nodes+=('/sys/devices/system/node/node6/cpulist:0-39')
    cpu_nodes+=('/sys/devices/system/node/node0/cpulist:')

    #act
    check_2230_numa_distribution_ibmpower

    #assert
    assertEquals "CheckWarning? RC" '1' "$?"
}

test_2numa_with_numa_nodes_not_matching() {

    #arrange
    mem_nodes=()
    mem_nodes+=('Node 0 MemTotal:               0 kB')
    mem_nodes+=('Node 6 MemTotal:       502777024 kB')

    cpu_nodes=()
    cpu_nodes+=('/sys/devices/system/node/node6/cpulist:0-39')
    cpu_nodes+=('/sys/devices/system/node/node0/cpulist:')

    #act
    check_2230_numa_distribution_ibmpower

    #assert
    assertEquals "CheckWarning? RC" '1' "$?"
}

test_2numa_with_both_nodes_ok() {

    #arrange
    mem_nodes=()
    mem_nodes+=('Node 0 MemTotal:       502777024 kB')
    mem_nodes+=('Node 6 MemTotal:       502777024 kB')

    cpu_nodes=()
    cpu_nodes+=('/sys/devices/system/node/node0/cpulist:40-79')
    cpu_nodes+=('/sys/devices/system/node/node6/cpulist:0-39')

    #act
    check_2230_numa_distribution_ibmpower

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_2numa_with_numa0_memory_but_no_cpu() {

    #arrange
    mem_nodes=()
    mem_nodes+=('Node 0 MemTotal:       502777024 kB')
    mem_nodes+=('Node 6 MemTotal:       502777024 kB')

    cpu_nodes=()
    cpu_nodes+=('/sys/devices/system/node/node0/cpulist:')
    cpu_nodes+=('/sys/devices/system/node/node6/cpulist:0-39')

    #act
    check_2230_numa_distribution_ibmpower

    #assert
    assertEquals "CheckWarning? RC" '1' "$?"
}


test_2numa_with_numa0_cpu_but_no_memory() {

    #arrange
    mem_nodes=()
    mem_nodes+=('Node 0 MemTotal:               0 kB')
    mem_nodes+=('Node 6 MemTotal:       502777024 kB')

    cpu_nodes=()
    cpu_nodes+=('/sys/devices/system/node/node0/cpulist:40-79')
    cpu_nodes+=('/sys/devices/system/node/node6/cpulist:0-39')

    #act
    check_2230_numa_distribution_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_2numa_with_numa0_memory_lt_margin() {

    #arrange
    mem_nodes=()
    mem_nodes+=('Node 0 MemTotal:       400388510 kB')
    mem_nodes+=('Node 6 MemTotal:       502777024 kB')

    cpu_nodes=()
    cpu_nodes+=('/sys/devices/system/node/node0/cpulist:40-79')
    cpu_nodes+=('/sys/devices/system/node/node6/cpulist:0-39')

    #act
    check_2230_numa_distribution_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_2numa_with_numa0_cpu_gt_margin() {

    #arrange
    mem_nodes=()
    mem_nodes+=('Node 0 MemTotal:       502777024 kB')
    mem_nodes+=('Node 6 MemTotal:       502777024 kB')

    cpu_nodes=()
    cpu_nodes+=('/sys/devices/system/node/node0/cpulist:40-59')
    cpu_nodes+=('/sys/devices/system/node/node6/cpulist:0-39')

    #act
    check_2230_numa_distribution_ibmpower

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}


 oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/2230_numa_distribution_ibmpower.check
    source "${PROGRAM_DIR}/../../lib/check/2230_numa_distribution_ibmpower.check"

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

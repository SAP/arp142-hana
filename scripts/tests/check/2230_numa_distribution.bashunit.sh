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
mem_nodes=()
cpu_nodes=()

# Mock functions
LIB_FUNC_IS_BARE_METAL() { return 1 ; }

grep() {

    #we fake <(grep -h -m1 'MemTotal' -r /sys/devices/system/node/node*/meminfo)
    #we fake <(grep -H "^.*$" -r /sys/devices/system/node/node*/cpulist)
    case "$*" in
        *'meminfo')     printf "%s\n" "${mem_nodes[@]}" ;;

        *'cpulist')     printf "%s\n" "${cpu_nodes[@]}" ;;

        *)              command grep "$@" ;; # bashunit requires grep
    esac
}


function test_1numa_with_node_ok() {

    #arrange
    mem_nodes=()
    mem_nodes+=('Node 6 MemTotal:       502777024 kB')

    cpu_nodes=()
    cpu_nodes+=('/sys/devices/system/node/node6/cpulist:0-39')

    #act
    check_2230_numa_distribution

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for 1 NUMA with node ok"
    fi
}

function test_2numa_with_numa0_empty_ignore() {

    #arrange
    mem_nodes=()
    mem_nodes+=('Node 0 MemTotal:              0 kB')
    mem_nodes+=('Node 6 MemTotal:       502777024 kB')

    cpu_nodes=()
    cpu_nodes+=('/sys/devices/system/node/node0/cpulist:')
    cpu_nodes+=('/sys/devices/system/node/node6/cpulist:0-39')

    #act
    check_2230_numa_distribution

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for 2 NUMA with numa0 empty ignored"
    fi
}

function test_numa_different_number() {

    #arrange
    mem_nodes=()
    mem_nodes+=('Node 6 MemTotal:       502777024 kB')

    cpu_nodes=()
    cpu_nodes+=('/sys/devices/system/node/node6/cpulist:0-39')
    cpu_nodes+=('/sys/devices/system/node/node0/cpulist:')

    #act
    check_2230_numa_distribution

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for NUMA different number"
    fi
}

function test_2numa_with_numa_nodes_not_matching() {

    #arrange
    mem_nodes=()
    mem_nodes+=('Node 0 MemTotal:               0 kB')
    mem_nodes+=('Node 6 MemTotal:       502777024 kB')

    cpu_nodes=()
    cpu_nodes+=('/sys/devices/system/node/node6/cpulist:0-39')
    cpu_nodes+=('/sys/devices/system/node/node0/cpulist:')

    #act
    check_2230_numa_distribution

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for NUMA nodes not matching"
    fi
}

function test_2numa_with_both_nodes_ok() {

    #arrange
    mem_nodes=()
    mem_nodes+=('Node 0 MemTotal:       502777024 kB')
    mem_nodes+=('Node 6 MemTotal:       502777024 kB')

    cpu_nodes=()
    cpu_nodes+=('/sys/devices/system/node/node0/cpulist:40-79')
    cpu_nodes+=('/sys/devices/system/node/node6/cpulist:0-39')

    #act
    check_2230_numa_distribution

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for 2 NUMA with both nodes ok"
    fi
}

function test_2numa_with_numa0_memory_but_no_cpu() {

    #arrange
    mem_nodes=()
    mem_nodes+=('Node 0 MemTotal:       502777024 kB')
    mem_nodes+=('Node 6 MemTotal:       502777024 kB')

    cpu_nodes=()
    cpu_nodes+=('/sys/devices/system/node/node0/cpulist:')
    cpu_nodes+=('/sys/devices/system/node/node6/cpulist:0-39')

    #act
    check_2230_numa_distribution

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for NUMA0 memory but no CPU"
    fi
}

function test_2numa_with_numa0_cpu_but_no_memory() {

    #arrange
    mem_nodes=()
    mem_nodes+=('Node 0 MemTotal:               0 kB')
    mem_nodes+=('Node 6 MemTotal:       502777024 kB')

    cpu_nodes=()
    cpu_nodes+=('/sys/devices/system/node/node0/cpulist:40-79')
    cpu_nodes+=('/sys/devices/system/node/node6/cpulist:0-39')

    #act
    check_2230_numa_distribution

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for NUMA0 CPU but no memory"
    fi
}

function test_2numa_with_numa0_multiple_cpu_ranges_simple() {

    #arrange
    mem_nodes=()
    mem_nodes+=('Node 0 MemTotal:       502777024 kB')
    mem_nodes+=('Node 6 MemTotal:       502777024 kB')

    cpu_nodes=()
    cpu_nodes+=('/sys/devices/system/node/node0/cpulist:40-59,60-79')
    cpu_nodes+=('/sys/devices/system/node/node6/cpulist:0-39')

    #act
    check_2230_numa_distribution

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for multiple CPU ranges simple"
    fi
}

function test_2numa_with_numa0_multiple_cpu_ranges_complicated() {

    #arrange
    mem_nodes=()
    mem_nodes+=('Node 0 MemTotal:       502777024 kB')
    mem_nodes+=('Node 6 MemTotal:       502777024 kB')

    cpu_nodes=()
    cpu_nodes+=('/sys/devices/system/node/node0/cpulist:0-7,16-23,32-39,48-55')
    cpu_nodes+=('/sys/devices/system/node/node6/cpulist:0-31')

    #act
    check_2230_numa_distribution

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for multiple CPU ranges complicated"
    fi
}

function test_2numa_with_numa0_ratio_lt_margin() {

    #arrange
    mem_nodes=()
    mem_nodes+=('Node 0 MemTotal:       5500000 kB')
    mem_nodes+=('Node 6 MemTotal:       8000000 kB')

    cpu_nodes=()
    cpu_nodes+=('/sys/devices/system/node/node0/cpulist:0-41')
    cpu_nodes+=('/sys/devices/system/node/node6/cpulist:0-49')

    #act
    check_2230_numa_distribution

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for ratio lt margin"
    fi
}

function test_2numa_with_numa0_ratio_gt_margin() {

    #arrange
    mem_nodes=()
    mem_nodes+=('Node 0 MemTotal:       1250000 kB')
    mem_nodes+=('Node 6 MemTotal:       2000000 kB')

    cpu_nodes=()
    cpu_nodes+=('/sys/devices/system/node/node0/cpulist:40-49')
    cpu_nodes+=('/sys/devices/system/node/node6/cpulist:0-19')

    #act
    check_2230_numa_distribution

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for ratio gt margin"
    fi
}

function test_2numa_with_both_ratio_out_margin() {

    #arrange
    mem_nodes=()
    mem_nodes+=('Node 0 MemTotal:       2000000 kB')
    mem_nodes+=('Node 6 MemTotal:       2000000 kB')

    cpu_nodes=()
    cpu_nodes+=('/sys/devices/system/node/node0/cpulist:40-59')
    cpu_nodes+=('/sys/devices/system/node/node6/cpulist:0-39')

    #act
    check_2230_numa_distribution

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for both ratio out margin"
    fi
}


function set_up_before_script() {

    # Disable errexit - bashunit enables it but sourced files may return non-zero
    set +eE

    # Skip if already loaded (bashunit runs all tests in same session)
    [[ -n "${_2230_test_loaded:-}" ]] && return 0
    _2230_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/2230_numa_distribution.check
    source "${PROGRAM_DIR}/../../lib/check/2230_numa_distribution.check"

}

function set_up() {

    # Reset mock variables
    mem_nodes=()
    cpu_nodes=()

}

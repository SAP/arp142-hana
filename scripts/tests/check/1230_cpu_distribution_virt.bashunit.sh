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

# Mock variables for CPU node data
cpu_nodes=()

# Mock functions
LIB_FUNC_IS_BARE_METAL() { return 1 ; }

# Override grep to fake /sys/devices/system/node/node*/cpulist
grep() {

    #we fake <(grep -H "^.*$" -r /sys/devices/system/node/node*/cpulist)
    case "$*" in
        *'cpulist')     printf "%s\n" "${cpu_nodes[@]}" ;;

        *)              command grep "$@" ;; # bashunit requires grep
    esac
}


function test_1numa_with_node_ok() {

    #arrange
    cpu_nodes=()
    cpu_nodes+=('/sys/devices/system/node/node6/cpulist:0-39')

    #act
    check_1230_cpu_distribution_virt

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for 1 NUMA with node"
    fi
}

function test_2numa_with_numa0_empty_ignore() {

    #arrange
    cpu_nodes=()
    cpu_nodes+=('/sys/devices/system/node/node0/cpulist:')
    cpu_nodes+=('/sys/devices/system/node/node6/cpulist:0-39')

    #act
    check_1230_cpu_distribution_virt

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for 2 NUMA with empty node0"
    fi
}

function test_2numa_with_both_nodes_same_cpu() {

    #arrange
    cpu_nodes=()
    cpu_nodes+=('/sys/devices/system/node/node0/cpulist:40-79')
    cpu_nodes+=('/sys/devices/system/node/node6/cpulist:0-39')

    #act
    check_1230_cpu_distribution_virt

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for 2 NUMA with same CPU count"
    fi
}

function test_2numa_with_numa0_multiple_cpu_ranges_simple() {

    #arrange
    cpu_nodes=()
    cpu_nodes+=('/sys/devices/system/node/node0/cpulist:40-59,60-79')
    cpu_nodes+=('/sys/devices/system/node/node6/cpulist:0-39')

    #act
    check_1230_cpu_distribution_virt

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for 2 NUMA with multiple CPU ranges"
    fi
}

function test_2numa_with_numa0_multiple_cpu_ranges_complicated() {

    #arrange
    cpu_nodes=()
    cpu_nodes+=('/sys/devices/system/node/node0/cpulist:0-7,16-23,32-39,48-55')
    cpu_nodes+=('/sys/devices/system/node/node6/cpulist:0-31')

    #act
    check_1230_cpu_distribution_virt

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for complicated CPU ranges"
    fi
}

function test_numa_ignore_nodes_with_no_cpus() {

    #arrange
    cpu_nodes=()
    cpu_nodes+=('/sys/devices/system/node/node0/cpulist:0-39')
    cpu_nodes+=('/sys/devices/system/node/node2/cpulist:')
    cpu_nodes+=('/sys/devices/system/node/node4/cpulist:0-39')
    cpu_nodes+=('/sys/devices/system/node/node6/cpulist:')

    #act
    check_1230_cpu_distribution_virt

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) ignoring nodes with no CPUs"
    fi
}

function test_2numa_with_both_out_margin() {

    #arrange
    cpu_nodes=()
    cpu_nodes+=('/sys/devices/system/node/node0/cpulist:0-15')
    cpu_nodes+=('/sys/devices/system/node/node6/cpulist:0-7')

    #act
    check_1230_cpu_distribution_virt

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for imbalanced CPUs"
    fi
}

function test_3numa_with_numa0_lt_margin() {

    #arrange
    cpu_nodes=()
    cpu_nodes+=('/sys/devices/system/node/node0/cpulist:0-21')
    cpu_nodes+=('/sys/devices/system/node/node4/cpulist:0-49')
    cpu_nodes+=('/sys/devices/system/node/node6/cpulist:0-49')

    #act
    check_1230_cpu_distribution_virt

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for NUMA0 below margin"
    fi
}

function test_3numa_with_numa0_gt_margin() {

    #arrange
    cpu_nodes=()
    cpu_nodes+=('/sys/devices/system/node/node0/cpulist:0-29')
    cpu_nodes+=('/sys/devices/system/node/node4/cpulist:0-19')
    cpu_nodes+=('/sys/devices/system/node/node6/cpulist:0-19')

    #act
    check_1230_cpu_distribution_virt

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for NUMA0 above margin"
    fi
}


function set_up_before_script() {

    # Disable errexit - bashunit enables it but sourced files may return non-zero
    set +eE

    # Skip if already loaded (bashunit runs all tests in same session)
    [[ -n "${_1230_test_loaded:-}" ]] && return 0
    _1230_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/1230_cpu_distribution_virt.check
    source "${PROGRAM_DIR}/../../lib/check/1230_cpu_distribution_virt.check"

}

function set_up() {

    # Reset mock variables
    cpu_nodes=()

}

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
path_to_proc_swaps=''
mock_proc_swaps_content=''


function test_proc_swaps_not_found() {

    #arrange
    path_to_proc_swaps="${PROGRAM_DIR}/nonexistent_swaps_file"
    unset mock_proc_swaps_content

    #act
    check_2330_swap_space

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for proc swaps not found"
    fi
}

function test_no_swap_configured() {

    #arrange
    mock_proc_swaps_content=$'Filename Type Size Used Priority'

    #act
    check_2330_swap_space

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for no swap configured"
    fi
}

function test_insufficient_swap_single_area() {

    #arrange
    # 9 GiB = 9437184 KiB
    mock_proc_swaps_content=$'Filename Type Size Used Priority\n/dev/dm-1 partition 9437184 0 -2'

    #act
    check_2330_swap_space

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for insufficient swap single area"
    fi
}

function test_sufficient_swap_single_area() {

    #arrange
    # 11 GiB = 11534336 KiB
    mock_proc_swaps_content=$'Filename Type Size Used Priority\n/dev/dm-1 partition 11534336 0 -2'

    #act
    check_2330_swap_space

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for sufficient swap single area"
    fi
}

function test_sufficient_swap_exact_threshold() {

    #arrange
    # Exactly 10 GiB = 10485760 KiB
    mock_proc_swaps_content=$'Filename  Type Size Used Priority\n/dev/dm-1 partition 10485760 0 -2'

    #act
    check_2330_swap_space

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for sufficient swap exact threshold"
    fi
}

function test_sufficient_swap_multiple_areas() {

    #arrange
    # 6 GiB + 5 GiB = 11 GiB total
    mock_proc_swaps_content=$'Filename Type Size Used Priority\n/dev/dm-1 partition 6291456 0 -2\n/swapfile file 5242880 100 -3'

    #act
    check_2330_swap_space

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for sufficient swap multiple areas"
    fi
}

function test_insufficient_swap_multiple_areas() {

    #arrange
    # 4 GiB + 5 GiB = 9 GiB total (below threshold)
    mock_proc_swaps_content=$'Filename Type Size Used Priority\n/dev/dm-1 partition 4194304 0 -2\n/swapfile file 5242880 100 -3'

    #act
    check_2330_swap_space

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for insufficient swap multiple areas"
    fi
}

function test_corrupted_non_numeric_size() {

    #arrange
    mock_proc_swaps_content=$'Filename Type Size Used Priority\n/dev/dm-1 partition INVALID 0 -2'

    #act
    check_2330_swap_space

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for corrupted non-numeric size"
    fi
}

function test_empty_lines_ignored() {

    #arrange
    # 11 GiB with empty lines
    mock_proc_swaps_content=$'Filename Type Size Used Priority\n/dev/dm-1 partition 11534336 0 -2\n\n'

    #act
    check_2330_swap_space

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for empty lines ignored"
    fi
}

function test_zero_swap_space() {

    #arrange
    mock_proc_swaps_content=$'Filename Type Size Used Priority\n/dev/dm-1 partition 0 0 -2'

    #act
    check_2330_swap_space

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for zero swap space"
    fi
}


function set_up_before_script() {

    # Disable errexit - bashunit enables it but sourced files may return non-zero
    set +eE

    # Skip if already loaded (bashunit runs all tests in same session)
    [[ -n "${_2330_test_loaded:-}" ]] && return 0
    _2330_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/2330_swap_space.check
    source "${PROGRAM_DIR}/../../lib/check/2330_swap_space.check"

}

function set_up() {

    path_to_proc_swaps=''
    mock_proc_swaps_content=''

}

#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
[[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
readonly PROGRAM_DIR

test_proc_swaps_not_found() {

    #arrange
    path_to_proc_swaps="${PROGRAM_DIR}/nonexistent_swaps_file"
    unset mock_proc_swaps_content

    #act
    check_2330_swap_space

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_no_swap_configured() {

    #arrange
    mock_proc_swaps_content=$'Filename Type Size Used Priority'

    #act
    check_2330_swap_space

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_insufficient_swap_single_area() {

    #arrange
    # 9 GiB = 9437184 KiB
    mock_proc_swaps_content=$'Filename Type Size Used Priority\n/dev/dm-1 partition 9437184 0 -2'

    #act
    check_2330_swap_space

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_sufficient_swap_single_area() {

    #arrange
    # 11 GiB = 11534336 KiB
    mock_proc_swaps_content=$'Filename Type Size Used Priority\n/dev/dm-1 partition 11534336 0 -2'

    #act
    check_2330_swap_space

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_sufficient_swap_exact_threshold() {

    #arrange
    # Exactly 10 GiB = 10485760 KiB
    mock_proc_swaps_content=$'Filename  Type Size Used Priority\n/dev/dm-1 partition 10485760 0 -2'

    #act
    check_2330_swap_space

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_sufficient_swap_multiple_areas() {

    #arrange
    # 6 GiB + 5 GiB = 11 GiB total
    mock_proc_swaps_content=$'Filename Type Size Used Priority\n/dev/dm-1 partition 6291456 0 -2\n/swapfile file 5242880 100 -3'

    #act
    check_2330_swap_space

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_insufficient_swap_multiple_areas() {

    #arrange
    # 4 GiB + 5 GiB = 9 GiB total (below threshold)
    mock_proc_swaps_content=$'Filename Type Size Used Priority\n/dev/dm-1 partition 4194304 0 -2\n/swapfile file 5242880 100 -3'

    #act
    check_2330_swap_space

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_corrupted_non_numeric_size() {

    #arrange
    mock_proc_swaps_content=$'Filename Type Size Used Priority\n/dev/dm-1 partition INVALID 0 -2'

    #act
    check_2330_swap_space

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_empty_lines_ignored() {

    #arrange
    # 11 GiB with empty lines
    mock_proc_swaps_content=$'Filename Type Size Used Priority\n/dev/dm-1 partition 11534336 0 -2\n\n'

    #act
    check_2330_swap_space

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_zero_swap_space() {

    #arrange
    mock_proc_swaps_content=$'Filename Type Size Used Priority\n/dev/dm-1 partition 0 0 -2'

    #act
    check_2330_swap_space

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/2330_swap_space.check
    source "${PROGRAM_DIR}/../../lib/check/2330_swap_space.check"
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

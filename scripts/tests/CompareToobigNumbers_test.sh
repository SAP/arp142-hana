#!/usr/bin/env bash
set -u      # treat unset variables as an error

PROGRAM_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
readonly PROGRAM_DIR

testCompareTooBigNumbersEqualTo() {

    local -i i=1

    while read -ra _test
    do
        #printf "test[$i]: <%s> <%s>\n" "${_test[0]}" "${_test[1]}"
        LIB_COMPARE_TOOBIG_NUMBERS "${_test[0]}" "${_test[1]}"
        assertTrue "EqualTo failure test#$(( i++ ))" "[ $? -eq 0 ]"
    done <<- EOF
    1                       1
    9223372036854775807     9223372036854775807
    18446744073709551615    18446744073709551615
EOF
}

testCompareTooBigNumbersLessThan() {

    local -i i=1

    while read -ra _test
    do
        #printf "test[$i]: <%s> <%s>\n" "${_test[0]}" "${_test[1]}"
        LIB_COMPARE_TOOBIG_NUMBERS "${_test[0]}" "${_test[1]}"
        assertTrue "LessThan failure test#$(( i++ ))" "[ $? -eq 2 ]"
    done <<- EOF
    1                          2
    9223372036854775807        18446744073709551615
    9223372036854775807        9223372036854775808
    922337203685477580         922337203685477581
    18446744073709551615       18446744073709551616
EOF
}

testCompareTooBigNumbersGreaterThan() {

    local -i i=1

    while read -ra _test
    do
        #printf "test[$i]: <%s> <%s>\n" "${_test[0]}" "${_test[1]}"
        LIB_COMPARE_TOOBIG_NUMBERS "${_test[0]}" "${_test[1]}"
        assertTrue "GreaterThan failure test#$(( i++ ))" "[ $? -eq 1 ]"
    done <<- EOF
    2                       1
    18446744073709551615    9223372036854775807
    9223372036854775808     9223372036854775807
    922337203685477581      922337203685477580
    18446744073709551616    18446744073709551615
EOF
}

testCompareTooBigNumbersShouldFail() {
    local -i _rc

    #The following tests should fail (test the tester)
    LIB_COMPARE_TOOBIG_NUMBERS '1' '2'
    _rc=$?
    assertNotEquals 'test[1]: testing the tester failed' '0' "${_rc}"
    assertNotEquals 'test[1]: testing the tester failed' '1' "${_rc}"

    LIB_COMPARE_TOOBIG_NUMBERS '2' '2'
    _rc=$?
    assertNotEquals 'test[2]: testing the tester failed' '1' "${_rc}"
    assertNotEquals 'test[2]: testing the tester failed' '2' "${_rc}"

    LIB_COMPARE_TOOBIG_NUMBERS '2' '1'
    _rc=$?
    assertNotEquals 'test[3]: testing the tester failed' '0' "${_rc}"
    assertNotEquals 'test[3]: testing the tester failed' '2' "${_rc}"
}

oneTimeSetUp () {

    # prevent loading of original libraries
    # shellcheck disable=SC2034
    LIB_LINUX_RELEASE='dont load'
    # shellcheck disable=SC2034
    LIB_PLATF_x86_64_RELEASE='dont load'
    # shellcheck disable=SC2034
    LIB_PLATF_POWER_RELEASE='dont load'

    declare -i LIB_PLATF_RAM_MIB_PHYS=1024
    declare -i LIB_PLATF_RAM_MiB_AVAILABLE=1024

    #shellcheck source=./saphana-logger-stubs
    source "${PROGRAM_DIR}/./saphana-logger-stubs"

    #shellcheck source=../bin/saphana-helper-funcs
    source "${PROGRAM_DIR}/../bin/saphana-helper-funcs"

 }

# oneTimeTearDown
# setUp
# tearDown

#Import Libraries
# - order is important - sourcing shunit triggers testing
# - that's also the reason, why it could not be done during oneTimeSetup

#shellcheck source=./shunit2
source "${PROGRAM_DIR}/shunit2"

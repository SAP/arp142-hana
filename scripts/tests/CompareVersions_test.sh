#! /bin/bash
set -u 		# treat unset variables as an error

#Useful information
#http://stackoverflow.com/questions/4023830/how-compare-two-strings-in-dot-separated-version-format-in-bash

PROGRAM_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
readonly PROGRAM_DIR

testCompareVersionsEqualTo() {

    local -i i=1

    while read -ra _test
    do
        #printf "test[$i]: <%s> <%s>\n" "${_test[0]}" "${_test[1]}"
        LIB_FUNC_COMPARE_VERSIONS "${_test[0]}" "${_test[1]}"
        assertTrue "EqualTo failure test#$(( i++ ))" "[ $? -eq 0 ]"
    done <<- EOF
    1               1
    5.6.7           5.6.7
    1.01.1          1.1.1
    1.1.1           1.01.1
    1               1.0
    1.0             1
    1.0.2.0         1.0.2
    1..0            1.0
    1.0             1..0
    2.11.3-17.95.2  2.11.3-17.95.2
    2.19-38.2       2.19-38.2
EOF
}

testCompareVersionsLessThan() {

    local -i i=1

    LIB_FUNC_COMPARE_VERSIONS '2.1' '2.2'
    assertTrue "LessThan failure test#$(( i++ ))" "[ $? -eq 2 ]"

    LIB_FUNC_COMPARE_VERSIONS '4.08' '4.08.01'
    assertTrue "LessThan failure test#$(( i++ ))" "[ $? -eq 2 ]"

    LIB_FUNC_COMPARE_VERSIONS '3.2' '3.2.1.9.8144'
    assertTrue "LessThan failure test#$(( i++ ))" "[ $? -eq 2 ]"

    LIB_FUNC_COMPARE_VERSIONS '1.2' '2.1'
    assertTrue "LessThan failure test#$(( i++ ))" "[ $? -eq 2 ]"

    LIB_FUNC_COMPARE_VERSIONS '2.11.3-17.56.2' '2.11.3-17.95.2'
    assertTrue "LessThan failure test#$(( i++ ))" "[ $? -eq 2 ]"

    LIB_FUNC_COMPARE_VERSIONS '2.11.3-17.95.2' '2.19-38.2'
    assertTrue "LessThan failure test#$(( i++ ))" "[ $? -eq 2 ]"

}

testCompareVersionsGreaterThan() {

    local -i i=1

    while read -ra _test
    do
        #printf "test[$i]: <%s> <%s>\n" "${_test[0]}" "${_test[1]}"
        LIB_FUNC_COMPARE_VERSIONS "${_test[0]}" "${_test[1]}"
        assertTrue "GreaterThan failure test#$(( i++ ))" "[ $? -eq 1 ]"
    done <<- EOF
    3.0.4.10        3.0.4.2
    3.2.1.9.8144    3.2
    2.1             1.2
    2.11.3-17.95.2  2.11.3-17.56.2
    2.19-38.2       2.11.3-17.95.2
    3.0.101-0.47.71-1	3.0.101-0.47.71
EOF
}

testCompareVersionsShouldFail() {
    local -i _rc

    #The following tests should fail (test the tester)
    LIB_FUNC_COMPARE_VERSIONS '1' '2'
    _rc=$?
    assertNotEquals 'test[1]: testing the tester failed' '0' "${_rc}"
    assertNotEquals 'test[1]: testing the tester failed' '1' "${_rc}"

    LIB_FUNC_COMPARE_VERSIONS '2' '2'
    _rc=$?
    assertNotEquals 'test[2]: testing the tester failed' '1' "${_rc}"
    assertNotEquals 'test[2]: testing the tester failed' '2' "${_rc}"

    LIB_FUNC_COMPARE_VERSIONS '2' '1'
    _rc=$?
    assertNotEquals 'test[3]: testing the tester failed' '0' "${_rc}"
    assertNotEquals 'test[3]: testing the tester failed' '2' "${_rc}"
}

# oneTimeSetUp () {

# }
# oneTimeTearDown
# setUp
# tearDown

#Import Libraries
# - order is important - sourcing shunit triggers testing
# - that's also the reason, why it could not be done during oneTimeSetup
#shellcheck source=../bin/saphana-helper-funcs
source "${PROGRAM_DIR}/../bin/saphana-helper-funcs"
#shellcheck source=./shunit2
source "${PROGRAM_DIR}/shunit2"

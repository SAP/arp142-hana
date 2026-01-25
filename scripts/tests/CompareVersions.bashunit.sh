#!/usr/bin/env bash
#------------------------------------------------------------------
# bashunit migration notes:
# 1. PROGRAM_DIR not readonly - bashunit runs all tests in same session
# 2. Guard check skips if already loaded to avoid readonly variable conflicts
#------------------------------------------------------------------
set -u      # treat unset variables as an error

#Useful information
#http://stackoverflow.com/questions/4023830/how-compare-two-strings-in-dot-separated-version-format-in-bash

if [[ -z "${PROGRAM_DIR:-}" ]]; then
    PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
    [[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
fi

function test_compare_versions_equal_to() {

    local -i i=1

    while read -ra _test
    do
        #printf "test[$i]: <%s> <%s>\n" "${_test[0]}" "${_test[1]}"
        LIB_FUNC_COMPARE_VERSIONS "${_test[0]}" "${_test[1]}"
        if [[ $? -ne 0 ]]; then
            bashunit::fail "EqualTo failure test#$i"
        fi
        ((i++))
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

function test_compare_versions_less_than() {

    local -i i=1

    LIB_FUNC_COMPARE_VERSIONS '2.1' '2.2'
    if [[ $? -ne 2 ]]; then
        bashunit::fail "LessThan failure test#$i"
    fi
    ((i++))

    LIB_FUNC_COMPARE_VERSIONS '4.08' '4.08.01'
    if [[ $? -ne 2 ]]; then
        bashunit::fail "LessThan failure test#$i"
    fi
    ((i++))

    LIB_FUNC_COMPARE_VERSIONS '4.08.01' '4.08.02'
    if [[ $? -ne 2 ]]; then
        bashunit::fail "LessThan failure test#$i"
    fi
    ((i++))

    LIB_FUNC_COMPARE_VERSIONS '3.2' '3.2.1.9.8144'
    if [[ $? -ne 2 ]]; then
        bashunit::fail "LessThan failure test#$i"
    fi
    ((i++))

    LIB_FUNC_COMPARE_VERSIONS '1.2' '2.1'
    if [[ $? -ne 2 ]]; then
        bashunit::fail "LessThan failure test#$i"
    fi
    ((i++))

    LIB_FUNC_COMPARE_VERSIONS '2.11.3-17.56.2' '2.11.3-17.95.2'
    if [[ $? -ne 2 ]]; then
        bashunit::fail "LessThan failure test#$i"
    fi
    ((i++))

    LIB_FUNC_COMPARE_VERSIONS '2.11.3-17.95.2' '2.19-38.2'
    if [[ $? -ne 2 ]]; then
        bashunit::fail "LessThan failure test#$i"
    fi

}

function test_compare_versions_greater_than() {

    local -i i=1

    while read -ra _test
    do
        #printf "test[$i]: <%s> <%s>\n" "${_test[0]}" "${_test[1]}"
        LIB_FUNC_COMPARE_VERSIONS "${_test[0]}" "${_test[1]}"
        if [[ $? -ne 1 ]]; then
            bashunit::fail "GreaterThan failure test#$i"
        fi
        ((i++))
    done <<- EOF
    3.0.4.10        3.0.4.2
    3.2.1.9.8144    3.2
    2.1             1.2
    2.11.3-17.95.2  2.11.3-17.56.2
    2.19-38.2       2.11.3-17.95.2
    3.0.101-0.47.71-1   3.0.101-0.47.71
EOF
}

function test_compare_versions_should_fail() {
    local -i _rc

    #The following tests should fail (test the tester)
    LIB_FUNC_COMPARE_VERSIONS '1' '2'
    _rc=$?
    if [[ ${_rc} -eq 0 ]] || [[ ${_rc} -eq 1 ]]; then
        bashunit::fail 'test[1]: testing the tester failed'
    fi

    LIB_FUNC_COMPARE_VERSIONS '2' '2'
    _rc=$?
    if [[ ${_rc} -eq 1 ]] || [[ ${_rc} -eq 2 ]]; then
        bashunit::fail 'test[2]: testing the tester failed'
    fi

    LIB_FUNC_COMPARE_VERSIONS '2' '1'
    _rc=$?
    if [[ ${_rc} -eq 0 ]] || [[ ${_rc} -eq 2 ]]; then
        bashunit::fail 'test[3]: testing the tester failed'
    fi
}

function set_up_before_script() {

    # prevent loading of original libraries - must be set BEFORE sourcing logger-stubs
    # shellcheck disable=SC2034
    LIB_LINUX_RELEASE='dont load'
    # shellcheck disable=SC2034
    LIB_PLATF_x86_64_RELEASE='dont load'
    # shellcheck disable=SC2034
    LIB_PLATF_POWER_RELEASE='dont load'

    # Set these before sourcing helper-funcs (which may make them readonly)
    # shellcheck disable=SC2034
    LIB_PLATF_RAM_MIB_PHYS=1024
    # shellcheck disable=SC2034
    LIB_PLATF_RAM_MiB_AVAILABLE=1024
    # shellcheck disable=SC2034
    LIB_PLATF_RAM_KiB_AVAILABLE=1024
    source "${PROGRAM_DIR}/./saphana-logger-stubs"

    #shellcheck source=../bin/saphana-helper-funcs
    source "${PROGRAM_DIR}/../bin/saphana-helper-funcs"

 }

# tear_down_after_script
# set_up
# tear_down

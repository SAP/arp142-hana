#!/usr/bin/env bash
#------------------------------------------------------------------
# bashunit migration notes:
# 1. PROGRAM_DIR not readonly - bashunit runs all tests in same session
# 2. set +eE in setup - bashunit enables errexit which breaks library sourcing
# 3. Guard check skips if already loaded to avoid readonly variable conflicts
#------------------------------------------------------------------
set -u      # treat unset variables as an error

if [[ -z "${PROGRAM_DIR:-}" ]]; then
    PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
    [[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
fi

function test_compare_toobig_numbers_equal_to() {

    local -i i=1

    while read -ra _test
    do
        #printf "test[$i]: <%s> <%s>\n" "${_test[0]}" "${_test[1]}"
        LIB_COMPARE_TOOBIG_NUMBERS "${_test[0]}" "${_test[1]}"
        if [[ $? -ne 0 ]]; then
            bashunit::fail "EqualTo failure test#$i"
        fi
        ((i++))
    done <<- EOF
    1                       1
    9223372036854775807     9223372036854775807
    18446744073709551615    18446744073709551615
EOF
}

function test_compare_toobig_numbers_less_than() {

    local -i i=1

    while read -ra _test
    do
        #printf "test[$i]: <%s> <%s>\n" "${_test[0]}" "${_test[1]}"
        LIB_COMPARE_TOOBIG_NUMBERS "${_test[0]}" "${_test[1]}"
        if [[ $? -ne 2 ]]; then
            bashunit::fail "LessThan failure test#$i"
        fi
        ((i++))
    done <<- EOF
    1                          2
    9223372036854775807        18446744073709551615
    9223372036854775807        9223372036854775808
    922337203685477580         922337203685477581
    18446744073709551615       18446744073709551616
EOF
}

function test_compare_toobig_numbers_greater_than() {

    local -i i=1

    while read -ra _test
    do
        #printf "test[$i]: <%s> <%s>\n" "${_test[0]}" "${_test[1]}"
        LIB_COMPARE_TOOBIG_NUMBERS "${_test[0]}" "${_test[1]}"
        if [[ $? -ne 1 ]]; then
            bashunit::fail "GreaterThan failure test#$i"
        fi
        ((i++))
    done <<- EOF
    2                       1
    18446744073709551615    9223372036854775807
    9223372036854775808     9223372036854775807
    922337203685477581      922337203685477580
    18446744073709551616    18446744073709551615
EOF
}

function test_compare_toobig_numbers_should_fail() {
    local -i _rc

    #The following tests should fail (test the tester)
    LIB_COMPARE_TOOBIG_NUMBERS '1' '2'
    _rc=$?
    if [[ ${_rc} -eq 0 ]] || [[ ${_rc} -eq 1 ]]; then
        bashunit::fail 'test[1]: testing the tester failed'
    fi

    LIB_COMPARE_TOOBIG_NUMBERS '2' '2'
    _rc=$?
    if [[ ${_rc} -eq 1 ]] || [[ ${_rc} -eq 2 ]]; then
        bashunit::fail 'test[2]: testing the tester failed'
    fi

    LIB_COMPARE_TOOBIG_NUMBERS '2' '1'
    _rc=$?
    if [[ ${_rc} -eq 0 ]] || [[ ${_rc} -eq 2 ]]; then
        bashunit::fail 'test[3]: testing the tester failed'
    fi
}

function set_up_before_script() {

    # Disable errexit - bashunit enables it but our sourced files have commands
    # that may return non-zero as part of normal operation
    set +eE

    # Skip if already loaded (bashunit runs all tests in same session)
    [[ -n "${HANA_HELPER_PROGVERSION:-}" ]] && return 0

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

    #shellcheck source=./saphana-logger-stubs
    source "${PROGRAM_DIR}/./saphana-logger-stubs"

    #shellcheck source=../bin/saphana-helper-funcs
    source "${PROGRAM_DIR}/../bin/saphana-helper-funcs"

 }

# tear_down_after_script
# set_up
# tear_down

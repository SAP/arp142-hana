#!/usr/bin/env bash
#------------------------------------------------------------------
# bashunit migration notes:
# 1. PROGRAM_DIR not readonly - bashunit runs all tests in same session
# 2. Guard check skips if already loaded to avoid readonly variable conflicts
#------------------------------------------------------------------
set -u      # treat unset variables as an error

if [[ -z "${PROGRAM_DIR:-}" ]]; then
    PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
    [[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
fi

function test_string_contain() {

    local -i i=1

    # DON't specify ; between IFS and read -> this will change IFS globally
    while IFS=":" read -ra _test
    do
        #printf "test[%d]: <%s> <%s>\\n" $i "${_test[0]}" "${_test[1]}"

        LIB_FUNC_STRINGCONTAIN "${_test[0]}" "${_test[1]}"
        if [[ $? -ne 0 ]]; then
            bashunit::fail "StringContains failure test#$i"
        fi
        ((i++))

    done <<- EOF
    echo "My string":o "M
    echo "My string":str
    echo "POWER8":POWER8
	EOF
}

function test_string_does_not_contain() {

    local -i i=1

    # DON't specify ; between IFS and read -> this will change IFS globally
    while IFS=":" read -ra _test
    do
        #printf "test[%d]: <%s> <%s>\\n" $i "${_test[0]}" "${_test[1]}"

        LIB_FUNC_STRINGCONTAIN "${_test[0]}" "${_test[1]}"
        if [[ $? -eq 0 ]]; then
            bashunit::fail "StringDoesNoContains failure test#$i"
        fi
        ((i++))

    done <<- EOF
    echo "My string":alt
    echo "My string":My string2
    echo "POWER8":Power8
	EOF
}

function set_up_before_script() {

    # prevent loading of original libraries
    # shellcheck disable=SC2034
    LIB_LINUX_RELEASE='dont load'
    # shellcheck disable=SC2034
    LIB_PLATF_x86_64_RELEASE='dont load'
    # shellcheck disable=SC2034
    LIB_PLATF_POWER_RELEASE='dont load'

    declare -i LIB_PLATF_RAM_MIB_PHYS=1024
    declare -i LIB_PLATF_RAM_MiB_AVAILABLE=1024
    declare -i LIB_PLATF_RAM_KiB_AVAILABLE=1024

    #shellcheck source=./saphana-logger-stubs
    source "${PROGRAM_DIR}/./saphana-logger-stubs"

    #shellcheck source=../bin/saphana-helper-funcs
    source "${PROGRAM_DIR}/../bin/saphana-helper-funcs"

 }

# tear_down_after_script
# set_up
# tear_down

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

function test_normalize_rpm_equal_to() {

    local -i i=1
    local rpmversion

    while read -ra _test
    do
        # printf "test[$i]: expected <%s> orig <%s>\n" "${_test[1]}" "${_test[0]}"
        LIB_FUNC_NORMALIZE_RPM "${_test[0]}"
        rpmversion="${LIB_FUNC_NORMALIZE_RPM_RETURN}"

        # printf "test[$i]: expected <%s> normalized <%s>\n" "${_test[1]}" "${rpmversion}"
        if [[ "${_test[1]}" != "${rpmversion}" ]]; then
            bashunit::fail "EqualTo failure test#$i: expected '${_test[1]}' but got '${rpmversion}'"
        fi
        ((i++))

    done <<- EOF
    2.28-42.el8             2.28-42.8
    2.11.0-5.el7_7.3        2.11.0-5.7.7.3
    2.17-106.el7_2.9        2.17-106.7.2.9
    2.17-157.el7_3.5        2.17-157.7.3.5
    219-42.el7_4.4          219-42.7.4.4
    219-30.el7              219-30.7
    2.12-1.166.el6_7.1      2.12-1.166.6.7.1
    2.1.5+20221208.a3f44794f-150500.6.11.1  2.1.5-150500.6.11.1      # Remove +*-
	EOF
}

function test_normalize_rpm_should_fail() {

    local rpmversion

    #The following tests should fail (test the tester)
    LIB_FUNC_NORMALIZE_RPM '2.17-157.el7_3.5'
    rpmversion="${LIB_FUNC_NORMALIZE_RPM_RETURN}"

    # printf "test[1]: orig <%s> normalized <%s>\n"  '2.17-157.el7_3.5' "${rpmversion}"
    if [[ '2.17-157.el7_3.5' == "${rpmversion}" ]]; then
        bashunit::fail 'test[1]: testing the tester failed'
    fi
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

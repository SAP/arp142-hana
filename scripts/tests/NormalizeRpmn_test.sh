#!/usr/bin/env bash
set -u # treat unset variables as an error

PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
[[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
readonly PROGRAM_DIR

testNormalizeRpmEqualTo() {

    local -i i=1
    local kut

    while read -ra _test
    do
        # printf "test[$i]: expected <%s> orig <%s>\n" "${_test[1]}" "${_test[0]}"
        kut="${_test[0]}"
        LIB_FUNC_NORMALIZE_RPMn kut

        # printf "test[$i]: expected <%s> normalized <%s>\n" "${_test[1]}" "${kut}"
        assertEquals "EqualTo failure test#$(( i++ ))" "${_test[1]}" "${kut}"

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

testNormalizeRpmShouldFail() {

    local kut

    #The following tests should fail (test the tester)
    kut='2.17-157.el7_3.5'
    LIB_FUNC_NORMALIZE_RPMn kut

    # printf "test[1]: orig <%s> normalized <%s>\n"  '2.17-157.el7_3.5' "${kut}"
    assertNotEquals 'test[1]: testing the tester failed' '2.17-157.el7_3.5' "${kut}"
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
    declare -i LIB_PLATF_RAM_KiB_AVAILABLE=1024

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

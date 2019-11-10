#!/usr/bin/env bash
set -u      # treat unset variables as an error

PROGRAM_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
readonly PROGRAM_DIR

testNormalizeRpmEqualTo() {

    local -i i=1
    local rpmversion

    while read -ra _test
    do
        #printf "test[$i]: orig <%s> <%s>\n" "${_test[1]}" "${_test[0]}"
        LIB_FUNC_NORMALIZE_RPM "${_test[0]}"
        rpmversion="${LIB_FUNC_NORMALIZE_RPM_RETURN}"

        #printf "test[$i]: norm <%s> <%s>\n" "${_test[1]}" "${rpmversion}"
        assertEquals "EqualTo failure test#$(( i++ ))" "${_test[1]}" "${rpmversion}"

    done <<- EOF
    2.17-106.el7_2.9        2.17-106.0.9
    2.17-157.el7_3.5        2.17-157.0.5
    219-42.el7_4.4          219-42.0.4
    219-30.el7              219-30.0
	EOF
}

testNormalizeRpmShouldFail() {

    local rpmversion

    #The following tests should fail (test the tester)
    LIB_FUNC_NORMALIZE_RPM '2.17-157.el7_3.5'
    rpmversion="${LIB_FUNC_NORMALIZE_RPM_RETURN}"

    #printf "test[1]: norm <%s> <%s>\n"  '2.17-157.el7_3.5' "${rpmversion}"
    assertNotEquals 'test[1]: testing the tester failed' '2.17-157.el7_3.5' "${rpmversion}"
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

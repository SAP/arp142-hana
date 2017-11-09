#! /bin/bash
set -u 		# treat unset variables as an error

PROGRAM_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
readonly PROGRAM_DIR

testNormalizeRpmEqualTo() {

	local -i i=1
	local rpmversion

	while read -ra _test
	do
		#printf "test[$i]: orig <%s> <%s>\n" "${_test[1]}" "${_test[0]}"
		lib_func_normalize_rpm "${_test[0]}"
		rpmversion="${lib_func_normalize_rpm_return}"

		#printf "test[$i]: norm <%s> <%s>\n" "${_test[1]}" "${rpmversion}"
		assertEquals "EqualTo failure test#$(( i++ ))" "${_test[1]}" "${rpmversion}"
		
	done <<- EOF
	2.17-106.el7_2.9			2.17-106.0.9
	2.17-157.el7_3.5			2.17-157.0.5
	EOF
}

testNormalizeRpmShouldFail() {

	local rpmversion

	#The following tests should fail (test the tester)
	lib_func_normalize_rpm '2.17-157.el7_3.5'
	rpmversion="${lib_func_normalize_rpm_return}"

	#printf "test[1]: norm <%s> <%s>\n"  '2.17-157.el7_3.5' "${rpmversion}"
	assertNotEquals 'test[1]: testing the tester failed' '2.17-157.el7_3.5' "${rpmversion}"
}

# oneTimeSetUp () {

# }
# oneTimeTearDown
# setUp
# tearDown

#Import Libraries 
# - order is important - sourcing shunit triggers testing
# - thats also the reason, why it could not be done during oneTimeSetup
source "${PROGRAM_DIR}/../bin/saphana-helper-funcs"
source "${PROGRAM_DIR}/shunit2"

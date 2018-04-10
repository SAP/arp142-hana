#! /bin/bash
set -u 		# treat unset variables as an error

PROGRAM_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
readonly PROGRAM_DIR

testNormalizeKernelEqualTo() {

	local -i i=1
	local kernelversion

	while read -ra _test
	do
		#printf "test[$i]: orig <%s> <%s>\n" "${_test[1]}" "${_test[0]}"
		LIB_FUNC_NORMALIZE_KERNEL "${_test[0]}"
		kernelversion="${LIB_FUNC_NORMALIZE_KERNEL_RETURN}"

		#printf "test[$i]: norm <%s> <%s>\n"  "${_test[1]}"	"${kernelversion}"
		assertEquals "EqualTo failure test#$(( i++ ))" "${_test[1]}" "${kernelversion}"

	done <<- EOF
	3.0.101-0.47.71.7930.0.PTF-default		3.0.101-0.47.71.7930.0.1
	3.0.101-0.47.71-default           		3.0.101-0.47.71-1
	3.0.101-0.47-bigsmp          			3.0.101-0.47-1
	3.0.101-88-bigmem						3.0.101-88-1
	3.0.101-71-ppc64						3.0.101-71-1
	2.6.32-504.16.2.el6.x86_64				2.6.32-504.16.2				# Remove trailing ".el6.x86_64"
	3.10.0-327.46.1.el7.x86_64				3.10.0-327.46.1
	3.10.0-514.26.2.el7.x86_64				3.10.0-514.26.2
	EOF
}

testNormalizeKernelShouldFail() {

	local kernelversion

	#The following tests should fail (test the tester)
	LIB_FUNC_NORMALIZE_KERNEL '3.0.101-0.47.71-default2'
	kernelversion="${LIB_FUNC_NORMALIZE_KERNEL_RETURN}"

	#printf "test[1]: norm <%s> <%s>\n"  '3.0.101-0.47.71-default2' "${kernelversion}"
	assertNotEquals 'test[1]: testing the tester failed' '3.0.101-0.47.71.1' "${kernelversion}"
}

# oneTimeSetUp () {

# }
# oneTimeTearDown
# setUp
# tearDown

#Import Libraries
# - order is important - sourcing shunit triggers testing
# - thats also the reason, why it could not be done during oneTimeSetup
#shellcheck source=scripts/bin/saphana-helper-funcs
source "${PROGRAM_DIR}/../bin/saphana-helper-funcs"
#shellcheck source=scripts/tests/shunit2
source "${PROGRAM_DIR}/shunit2"

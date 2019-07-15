#! /bin/bash
set -u 		# treat unset variables as an error

PROGRAM_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
readonly PROGRAM_DIR

testStringContain() {

	local -i i=1

	# DON't specify ; between IFS and read -> this will change IFS globally
	while IFS=":" read -ra _test
	do
		#printf "test[%d]: <%s> <%s>\\n" $i "${_test[0]}" "${_test[1]}"

		LIB_FUNC_STRINGCONTAIN "${_test[0]}" "${_test[1]}"
		assertTrue "StringContains failure test#$(( i++ ))" $?

	done <<- EOF
	echo "My string":o "M
	echo "My string":str
	echo "POWER8":POWER8
	EOF
}

testStringDoesNotContain() {

	local -i i=1

	# DON't specify ; between IFS and read -> this will change IFS globally
	while IFS=":" read -ra _test
	do
		#printf "test[%d]: <%s> <%s>\\n" $i "${_test[0]}" "${_test[1]}"

		LIB_FUNC_STRINGCONTAIN "${_test[0]}" "${_test[1]}"
		assertFalse "StringDoesNoContains failure test#$(( i++ ))" "$?"

	done <<- EOF
	echo "My string":alt
	echo "My string":My string2
	echo "POWER8":Power8
	EOF
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

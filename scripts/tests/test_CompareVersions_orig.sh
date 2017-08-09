#!/bin/bash
set -u 		# treat unset variables as an error

#Useful information
#http://stackoverflow.com/questions/4023830/how-compare-two-strings-in-dot-separated-version-format-in-bash

PROGRAM_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
readonly PROGRAM_DIR

#Import Libraries
source "${PROGRAM_DIR}/../bin/saphana-logger"
source "${PROGRAM_DIR}/../bin/saphana-helper-funcs"


test_CompareVersions () {
	lib_func_compare_versions "$1" "$2"
	case $? in
		0) op='=';;
		1) op='>';;
		2) op='<';;
	esac
	if [[ $op != "$3" ]]
	then
		printf 'FAIL: Expected "%s", Actual "%s", Arg1 "%s", Arg2 "%s"\n'	"$3" "$op" "$1" "$2"
	else
		printf 'Pass: "%s %s %s"\n'	"$1" "$op" "$2"
	fi
}

# Run tests
# argument table format:
# testarg1   testarg2     expected_relationship
printf 'The following tests should pass\n'
while read -r test
do
	# shellcheck disable=SC2086
	test_CompareVersions $test
done << EOF
1            1            =
2.1          2.2          <
3.0.4.10     3.0.4.2      >
4.08         4.08.01      <
3.2.1.9.8144 3.2          >
3.2          3.2.1.9.8144 <
1.2          2.1          <
2.1          1.2          >
5.6.7        5.6.7        =
1.01.1       1.1.1        =
1.1.1        1.01.1       =
1            1.0          =
1.0          1            =
1.0.2.0      1.0.2        =
1..0         1.0          =
1.0          1..0         =
2.11.3-17.95.2  2.11.3-17.95.2  =
2.11.3-17.95.2  2.11.3-17.56.2  >
2.11.3-17.56.2  2.11.3-17.95.2  <
2.19-38.2       2.19-38.2       =
2.19-38.2       2.11.3-17.95.2  >
2.11.3-17.95.2  2.19-38.2       <
3.0.101-0.47.71-1	3.0.101-0.47.71 >
EOF

printf 'The following test should fail (test the tester)\n'
test_CompareVersions 1 1 '>'

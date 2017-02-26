#!/bin/bash

#Useful information
#http://stackoverflow.com/questions/4023830/how-compare-two-strings-in-dot-separated-version-format-in-bash

#Import Libraries
source ../bin/saphana-logger.sh
source ../bin/saphana-helper-funcs.sh


test_CompareVersions () {
	lib_func_compare_versions $1 $2
	case $? in
		0) op='=';;
		1) op='>';;
		2) op='<';;
	esac
	if [[ $op != $3 ]]
	then
		echo "FAIL: Expected '$3', Actual '$op', Arg1 '$1', Arg2 '$2'"
	else
		echo "Pass: '$1 $op $2'"
	fi
}

# Run tests
# argument table format:
# testarg1   testarg2     expected_relationship
echo "The following tests should pass"
while read -r test
do
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
EOF

echo "The following test should fail (test the tester)"
test_CompareVersions 1 1 '>'
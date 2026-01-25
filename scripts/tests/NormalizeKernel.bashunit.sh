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

function test_normalize_kernel_equal_to() {

    local -i i=1
    local kernelversion

    while read -ra _test
    do
        #printf "test[$i]: orig <%s> <%s>\n" "${_test[1]}" "${_test[0]}"
        LIB_FUNC_NORMALIZE_KERNEL "${_test[0]}"
        kernelversion="${LIB_FUNC_NORMALIZE_KERNEL_RETURN}"

        #printf "test[$i]: norm <%s> <%s>\n"  "${_test[1]}" "${kernelversion}"
        if [[ "${_test[1]}" != "${kernelversion}" ]]; then
            bashunit::fail "EqualTo failure test#$i: expected '${_test[1]}' but got '${kernelversion}'"
        fi
        ((i++))

    done <<- EOF
    3.0.101-0.47.71.7930.0.PTF-default      3.0.101-0.47.71.7930.0.1
    3.0.101-0.47.71-default                 3.0.101-0.47.71-1
    3.0.101-0.47-bigsmp                     3.0.101-0.47-1
    3.0.101-88-bigmem                       3.0.101-88-1
    3.0.101-71-ppc64                        3.0.101-71-1
    2.6.32-504.16.2.el6.x86_64              2.6.32-504.16.2             # Remove trailing ".el6.x86_64"
    3.10.0-327.46.1.el7.x86_64              3.10.0-327.46.1
    3.10.0-514.26.2.el7.x86_64              3.10.0-514.26.2
	EOF
}

function test_normalize_kernel_should_fail() {

    local kernelversion

    #The following tests should fail (test the tester)
    LIB_FUNC_NORMALIZE_KERNEL '3.0.101-0.47.71-default2'
    kernelversion="${LIB_FUNC_NORMALIZE_KERNEL_RETURN}"

    #printf "test[1]: norm <%s> <%s>\n"  '3.0.101-0.47.71-default2' "${kernelversion}"
    if [[ '3.0.101-0.47.71.1' == "${kernelversion}" ]]; then
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
    declare -i LIB_PLATF_RAM_KiB_AVAILABLE=0

    #shellcheck source=./saphana-logger-stubs
    source "${PROGRAM_DIR}/./saphana-logger-stubs"

    #shellcheck source=../bin/saphana-helper-funcs
    source "${PROGRAM_DIR}/../bin/saphana-helper-funcs"

 }

# tear_down_after_script
# set_up
# tear_down

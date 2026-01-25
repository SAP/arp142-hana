#!/usr/bin/env bash
#------------------------------------------------------------------
# bashunit migration notes:
# 1. PROGRAM_DIR not readonly - bashunit runs all tests in same session
# 2. set +eE in setup - bashunit enables errexit which breaks library sourcing
# 3. Guard checks for function existence (not guard variable) because other
#    tests set LIB_PLATF_POWER_RELEASE='dont load' which would skip sourcing
# 4. unset LIB_PLATF_POWER_RELEASE before sourcing to allow library loading
#------------------------------------------------------------------
set -u      # treat unset variables as an error

if [[ -z "${PROGRAM_DIR:-}" ]]; then
    PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
    [[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
fi

lscpu() {
    #we fake lscpu to avoid __get_platform_power_cpu_details
    :
}

function test_ibmcloud_power_instance_name_equal_to() {

    local -i i=1
    local inst_name

    while read -ra _test
    do

        LIB_PLATF_POWER_CPU_TOTAL=${_test[0]}
        LIB_PLATF_CPU_THREADSPERCORE=${_test[1]}
        LIB_PLATF_RAM_MiB_AVAILABLE=${_test[2]}

        LIB_FUNC_IBMCLOUD_POWER_INSTANCE_NAME
        inst_name="${RETURN_IBMCLOUD_POWER_INSTANCE_NAME}"

        # printf "test[$i]: expected <%s> created <%s>\n" "${_test[3]}" "${inst_name}"
        if [[ "${_test[3]}" != "${inst_name}" ]]; then
            bashunit::fail "EqualTo failure test#$i: expected '${_test[3]}' but got '${inst_name}'"
        fi
        ((i++))

    done <<- EOF
    160     8       2048000         bh1-20x2000
    560     8       7168000         bh1-70x7000
    480     8       3072000         ch1-60x3000
    1120    8       7168000         ch1-140x7000
    64      8       1474560         mh1-8x1440
    1000    8       23040000        mh1-125x22500
    48      8       1474560         umh1-6x1440
    480     8       14745600        umh1-60x14400
    32      8       131072          ush1-4x128
    32      8       786432          ush1-4x768
	EOF
    #CPUt   SMT     MiB             instance_name
}

function test_ibmcloud_power_instance_name_should_fail() {

    local inst_name

    #The following tests should fail (test the tester)
    LIB_PLATF_POWER_CPU_TOTAL=160
    LIB_PLATF_CPU_THREADSPERCORE=8
    LIB_PLATF_RAM_MiB_AVAILABLE=2048000

    LIB_FUNC_IBMCLOUD_POWER_INSTANCE_NAME
    inst_name="${RETURN_IBMCLOUD_POWER_INSTANCE_NAME}"

    # printf "test[1]: expected <%s> created <%s>\n"  'bh1-16x2000' "${inst_name}"
    if [[ 'bh1-16x2000' == "${inst_name}" ]]; then
        bashunit::fail 'test[1]: testing the tester failed'
    fi
}

function set_up_before_script() {

    # Disable errexit - bashunit enables it but our sourced files have commands
    # that may return non-zero as part of normal operation
    set +eE

    # Check if the function we need exists (not just the guard variable)
    # Other tests set LIB_PLATF_POWER_RELEASE='dont load' which would make us skip
    # sourcing, but we need the actual library functions
    if declare -F LIB_FUNC_IBMCLOUD_POWER_INSTANCE_NAME >/dev/null 2>&1; then
        return 0
    fi

    # prevent loading of original libraries
    # lib_platf_power
    #   -->  saphana-logger (prevented by saphana-logger-stubs)
    #   -->  saphana-helper-funcs
    #           --> lib_linux_release
    #           --> lib_platf_x86_64 (HOSTTYPE)
    #           --> lib_platf_power (HOSTTYPE)

    #shellcheck source=./saphana-logger-stubs
    source "${PROGRAM_DIR}/./saphana-logger-stubs"

    # shellcheck disable=SC2034
    LIB_LINUX_RELEASE='dont load'
    HOSTTYPE='ppc64le'

    # Need to unset any fake guard value and set ours to allow sourcing
    unset LIB_PLATF_POWER_RELEASE 2>/dev/null || true

    # prevent setting variables readonly by __get_platform_power_cpu_details
    # we also fake lscpu - see on top

    # shellcheck disable=SC2034
    LIB_PLATF_RAM_KiB_AVAILABLE=0
    LIB_PLATF_POWER_CPU_TOTAL=0
    LIB_PLATF_CPU_THREADSPERCORE=0
    LIB_PLATF_RAM_MiB_AVAILABLE=0

    #shellcheck source=../bin/lib_platf_power
    source "${PROGRAM_DIR}/../bin/lib_platf_power"

 }

# tear_down_after_script
# set_up
# tear_down

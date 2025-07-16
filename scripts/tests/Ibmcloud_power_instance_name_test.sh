#!/usr/bin/env bash
set -u      # treat unset variables as an error

PROGRAM_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
readonly PROGRAM_DIR

lscpu() {
    #we fake lscpu to avoid __get_platform_power_cpu_details
    :
}

testIbmCloudPowerInstanceNameEqualTo() {

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
        assertEquals "EqualTo failure test#$(( i++ ))" "${_test[3]}" "${inst_name}"

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

testIbmCloudPowerInstanceNameShouldFail() {

    local inst_name

    #The following tests should fail (test the tester)
    LIB_PLATF_POWER_CPU_TOTAL=160
    LIB_PLATF_CPU_THREADSPERCORE=8
    LIB_PLATF_RAM_MiB_AVAILABLE=2048000

    LIB_FUNC_IBMCLOUD_POWER_INSTANCE_NAME
    inst_name="${RETURN_IBMCLOUD_POWER_INSTANCE_NAME}"

    # printf "test[1]: expected <%s> created <%s>\n"  'bh1-16x2000' "${inst_name}"
    assertNotEquals 'test[1]: testing the tester failed' 'bh1-16x2000' "${inst_name}"
}

oneTimeSetUp () {

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

    # prevent setting variables readonly by __get_platform_power_cpu_details
    # we also fake lscpu - see on top

    # shellcheck disable=SC2034
    declare -i LIB_PLATF_RAM_KiB_AVAILABLE=0
    declare -i LIB_PLATF_POWER_CPU_TOTAL=0
    declare -i LIB_PLATF_CPU_THREADSPERCORE=0
    declare -i LIB_PLATF_RAM_MiB_AVAILABLE=0

    #shellcheck source=../bin/lib_platf_power
    source "${PROGRAM_DIR}/../bin/lib_platf_power"

 }

# oneTimeTearDown
# setUp
# tearDown

#Import Libraries
# - order is important - sourcing shunit triggers testing
# - that's also the reason, why it could not be done during oneTimeSetup

#shellcheck source=./shunit2
source "${PROGRAM_DIR}/shunit2"

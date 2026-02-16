#!/usr/bin/env bash
#------------------------------------------------------------------
# bashunit migration notes:
# 1. PROGRAM_DIR not readonly - bashunit runs all tests in same session
# 2. Guard check skips if already loaded to avoid readonly variable conflicts
#------------------------------------------------------------------
set -u  # treat unset variables as an error

if [[ -z "${PROGRAM_DIR:-}" ]]; then
    PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
    [[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
fi

# Mock variables
LIB_PLATF_CPU_NUMANODES=''
LIB_PLATF_CPU_SOCKETS=''
LIB_PLATF_CPU_MODELID=''
OS_VERSION=''
OS_NAME=''
_is_intel=0
_is_bare_metal=0
_is_sles=0
_is_rhel=1

# Mock functions
LIB_FUNC_IS_INTEL() { return "${_is_intel}" ; }
LIB_FUNC_IS_BARE_METAL() { return "${_is_bare_metal}" ; }
LIB_FUNC_IS_SLES() { return "${_is_sles}" ; }
LIB_FUNC_IS_RHEL() { return "${_is_rhel}" ; }


# ==============================================================================
# PRECONDITION TESTS
# ==============================================================================

function test_precondition_not_intel() {

    #arrange
    _is_intel=1

    #act
    check_1210_cpu_subnuma_intel

    #assert
    if [[ $? -ne 3 ]]; then
        bashunit::fail "Expected RC=3 (skipped) for non-Intel"
    fi
}

function test_precondition_virtualized() {

    #arrange
    _is_bare_metal=1

    #act
    check_1210_cpu_subnuma_intel

    #assert
    if [[ $? -ne 3 ]]; then
        bashunit::fail "Expected RC=3 (skipped) for virtualized"
    fi
}

function test_precondition_numanodes_unknown() {

    #arrange
    LIB_PLATF_CPU_NUMANODES=

    #act
    check_1210_cpu_subnuma_intel

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for unknown NUMA nodes"
    fi
}

function test_precondition_cpusockets_unknown() {

    #arrange
    LIB_PLATF_CPU_NUMANODES=4
    LIB_PLATF_CPU_SOCKETS=

    #act
    check_1210_cpu_subnuma_intel

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for unknown CPU sockets"
    fi
}

function test_precondition_unsupported_os() {

    #arrange
    _is_sles=1
    _is_rhel=1
    LIB_PLATF_CPU_NUMANODES=4
    LIB_PLATF_CPU_SOCKETS=4
    OS_NAME='Ubuntu'
    OS_VERSION='20.04'

    #act
    check_1210_cpu_subnuma_intel

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for unsupported OS"
    fi
}

# ==============================================================================
# CHECK LOGIC: NUMA nodes < CPU sockets (always error)
# ==============================================================================

function test_numa_disabled_sles() {

    #arrange
    LIB_PLATF_CPU_NUMANODES=1
    LIB_PLATF_CPU_SOCKETS=2
    LIB_PLATF_CPU_MODELID=85
    OS_VERSION='15.7'

    #act
    check_1210_cpu_subnuma_intel

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for NUMA disabled on SLES"
    fi
}

function test_numa_disabled_rhel() {

    #arrange
    _is_sles=1
    _is_rhel=0
    LIB_PLATF_CPU_NUMANODES=1
    LIB_PLATF_CPU_SOCKETS=4
    LIB_PLATF_CPU_MODELID=79
    OS_VERSION='8.6'

    #act
    check_1210_cpu_subnuma_intel

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for NUMA disabled on RHEL"
    fi
}

# ==============================================================================
# CHECK LOGIC: Skylake+ (model >= 85) - SNC-2 can be enabled or not
# ==============================================================================

function test_skylake_snc2_enabled_ok() {

    #arrange
    LIB_PLATF_CPU_NUMANODES=8
    LIB_PLATF_CPU_SOCKETS=4
    LIB_PLATF_CPU_MODELID=85
    OS_VERSION='15.4'

    #act
    check_1210_cpu_subnuma_intel

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for Skylake with SNC-2 enabled"
    fi
}

function test_skylake_snc2_not_enabled_ok() {

    #arrange
    LIB_PLATF_CPU_NUMANODES=4
    LIB_PLATF_CPU_SOCKETS=4
    LIB_PLATF_CPU_MODELID=85
    OS_VERSION='15.5'

    #act
    check_1210_cpu_subnuma_intel

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for Skylake without SNC-2"
    fi
}

function test_cascadelake_snc2_enabled_ok() {

    #arrange
    LIB_PLATF_CPU_NUMANODES=16
    LIB_PLATF_CPU_SOCKETS=8
    LIB_PLATF_CPU_MODELID=85
    OS_VERSION='15.7'

    #act
    check_1210_cpu_subnuma_intel

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for Cascade Lake with SNC-2"
    fi
}

function test_icelake_snc2_not_enabled_ok() {

    #arrange
    LIB_PLATF_CPU_NUMANODES=2
    LIB_PLATF_CPU_SOCKETS=2
    LIB_PLATF_CPU_MODELID=106
    OS_VERSION='15.4'

    #act
    check_1210_cpu_subnuma_intel

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for Ice Lake without SNC-2"
    fi
}

# ==============================================================================
# CHECK LOGIC: Broadwell/Haswell (model < 85) - CoD must be disabled
# ==============================================================================

function test_broadwell_cod_disabled_ok() {

    #arrange
    LIB_PLATF_CPU_NUMANODES=4
    LIB_PLATF_CPU_SOCKETS=4
    LIB_PLATF_CPU_MODELID=79
    OS_VERSION='12.5'

    #act
    check_1210_cpu_subnuma_intel

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for Broadwell with CoD disabled"
    fi
}

function test_broadwell_cod_not_disabled_error() {

    #arrange
    LIB_PLATF_CPU_NUMANODES=8
    LIB_PLATF_CPU_SOCKETS=4
    LIB_PLATF_CPU_MODELID=79
    OS_VERSION='12.4'

    #act
    check_1210_cpu_subnuma_intel

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for Broadwell with CoD enabled"
    fi
}

function test_haswell_cod_disabled_ok() {

    #arrange
    LIB_PLATF_CPU_NUMANODES=2
    LIB_PLATF_CPU_SOCKETS=2
    LIB_PLATF_CPU_MODELID=63
    OS_VERSION='12.5'

    #act
    check_1210_cpu_subnuma_intel

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for Haswell with CoD disabled"
    fi
}

function test_haswell_cod_not_disabled_error() {

    #arrange
    LIB_PLATF_CPU_NUMANODES=4
    LIB_PLATF_CPU_SOCKETS=2
    LIB_PLATF_CPU_MODELID=63
    OS_VERSION='12.3'

    #act
    check_1210_cpu_subnuma_intel

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for Haswell with CoD enabled"
    fi
}

function test_ivybridge_cod_disabled_ok() {

    #arrange
    LIB_PLATF_CPU_NUMANODES=4
    LIB_PLATF_CPU_SOCKETS=4
    LIB_PLATF_CPU_MODELID=62
    OS_VERSION='12.5'

    #act
    check_1210_cpu_subnuma_intel

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for Ivy Bridge with CoD disabled"
    fi
}

function test_ivybridge_cod_not_disabled_error() {

    #arrange
    LIB_PLATF_CPU_NUMANODES=8
    LIB_PLATF_CPU_SOCKETS=4
    LIB_PLATF_CPU_MODELID=62
    OS_VERSION='12.4'

    #act
    check_1210_cpu_subnuma_intel

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for Ivy Bridge with CoD enabled"
    fi
}

# ==============================================================================
# SAP NOTE VERSION TESTS (RHEL variants)
# ==============================================================================

function test_rhel7_note_assignment() {

    #arrange
    _is_sles=1
    _is_rhel=0
    LIB_PLATF_CPU_NUMANODES=4
    LIB_PLATF_CPU_SOCKETS=4
    LIB_PLATF_CPU_MODELID=79
    OS_VERSION='7.9'

    #act
    check_1210_cpu_subnuma_intel

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for RHEL 7"
    fi
}

function test_rhel8_note_assignment() {

    #arrange
    _is_sles=1
    _is_rhel=0
    LIB_PLATF_CPU_NUMANODES=2
    LIB_PLATF_CPU_SOCKETS=2
    LIB_PLATF_CPU_MODELID=85
    OS_VERSION='8.6'

    #act
    check_1210_cpu_subnuma_intel

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for RHEL 8"
    fi
}

function test_rhel9_note_assignment() {

    #arrange
    _is_sles=1
    _is_rhel=0
    LIB_PLATF_CPU_NUMANODES=8
    LIB_PLATF_CPU_SOCKETS=4
    LIB_PLATF_CPU_MODELID=106
    OS_VERSION='9.2'

    #act
    check_1210_cpu_subnuma_intel

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for RHEL 9"
    fi
}

# ==============================================================================
# SAP NOTE VERSION TESTS (SLES variants)
# ==============================================================================

function test_sles12_note_assignment() {

    #arrange
    LIB_PLATF_CPU_NUMANODES=4
    LIB_PLATF_CPU_SOCKETS=4
    LIB_PLATF_CPU_MODELID=79
    OS_VERSION='12.5'

    #act
    check_1210_cpu_subnuma_intel

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for SLES 12"
    fi
}

function test_sles15_note_assignment() {

    #arrange
    LIB_PLATF_CPU_NUMANODES=2
    LIB_PLATF_CPU_SOCKETS=2
    LIB_PLATF_CPU_MODELID=85
    OS_VERSION='15.4'

    #act
    check_1210_cpu_subnuma_intel

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for SLES 15"
    fi
}


function set_up_before_script() {

    # Disable errexit - bashunit enables it but sourced files may return non-zero
    set +eE

    # Skip if already loaded (bashunit runs all tests in same session)
    [[ -n "${_1210_test_loaded:-}" ]] && return 0
    _1210_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/1210_cpu_subnuma_intel.check
    source "${PROGRAM_DIR}/../../lib/check/1210_cpu_subnuma_intel.check"

}

function set_up() {

    # Reset mock variables
    LIB_PLATF_CPU_NUMANODES=''
    LIB_PLATF_CPU_SOCKETS=''
    LIB_PLATF_CPU_MODELID=''
    OS_VERSION=''
    OS_NAME=''

    # Reset mock function returns
    _is_intel=0
    _is_bare_metal=0
    _is_sles=0
    _is_rhel=1

}

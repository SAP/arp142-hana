#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
[[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
readonly PROGRAM_DIR

#mock PREREQUISITE functions
LIB_FUNC_IS_INTEL() { return 0 ; }
LIB_FUNC_IS_BARE_METAL() { return 0 ; }
LIB_FUNC_IS_SLES() { return 0 ; }
LIB_FUNC_IS_RHEL() { return 1 ; }

# Variables to mock for tests
# LIB_PLATF_CPU_NUMANODES=
# LIB_PLATF_CPU_SOCKETS=
# LIB_PLATF_CPU_MODELID=
# OS_VERSION=
# OS_NAME=

# ==============================================================================
# PRECONDITION TESTS
# ==============================================================================

test_precondition_not_intel() {

    #arrange
    LIB_FUNC_IS_INTEL() { return 1 ; }

    #act
    check_1210_cpu_subnuma_intel

    #assert
    assertEquals "CheckSkipped? RC" '3' "$?"
}

test_precondition_virtualized() {

    #arrange
    LIB_FUNC_IS_BARE_METAL() { return 1 ; }

    #act
    check_1210_cpu_subnuma_intel

    #assert
    assertEquals "CheckSkipped? RC" '3' "$?"
}

test_precondition_numanodes_unknown() {

    #arrange
    LIB_PLATF_CPU_NUMANODES=

    #act
    check_1210_cpu_subnuma_intel

    #assert
    assertEquals "CheckWarn? RC" '1' "$?"
}

test_precondition_cpusockets_unknown() {

    #arrange
    LIB_PLATF_CPU_NUMANODES=4
    LIB_PLATF_CPU_SOCKETS=

    #act
    check_1210_cpu_subnuma_intel

    #assert
    assertEquals "CheckWarn? RC" '1' "$?"
}

test_precondition_unsupported_os() {

    #arrange
    LIB_FUNC_IS_SLES() { return 1 ; }
    LIB_FUNC_IS_RHEL() { return 1 ; }
    LIB_PLATF_CPU_NUMANODES=4
    LIB_PLATF_CPU_SOCKETS=4
    OS_NAME='Ubuntu'
    OS_VERSION='20.04'

    #act
    check_1210_cpu_subnuma_intel

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

# ==============================================================================
# CHECK LOGIC: NUMA nodes < CPU sockets (always error)
# ==============================================================================

test_numa_disabled_sles() {

    #arrange
    LIB_PLATF_CPU_NUMANODES=1
    LIB_PLATF_CPU_SOCKETS=2
    LIB_PLATF_CPU_MODELID=85
    OS_VERSION='15.3'

    #act
    check_1210_cpu_subnuma_intel

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_numa_disabled_rhel() {

    #arrange
    LIB_FUNC_IS_SLES() { return 1 ; }
    LIB_FUNC_IS_RHEL() { return 0 ; }
    LIB_PLATF_CPU_NUMANODES=1
    LIB_PLATF_CPU_SOCKETS=4
    LIB_PLATF_CPU_MODELID=79
    OS_VERSION='8.6'

    #act
    check_1210_cpu_subnuma_intel

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

# ==============================================================================
# CHECK LOGIC: Skylake+ (model >= 85) - SNC-2 can be enabled or not
# ==============================================================================

test_skylake_snc2_enabled_ok() {

    #arrange
    LIB_PLATF_CPU_NUMANODES=8
    LIB_PLATF_CPU_SOCKETS=4
    LIB_PLATF_CPU_MODELID=85
    OS_VERSION='15.4'

    #act
    check_1210_cpu_subnuma_intel

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_skylake_snc2_not_enabled_ok() {

    #arrange
    LIB_PLATF_CPU_NUMANODES=4
    LIB_PLATF_CPU_SOCKETS=4
    LIB_PLATF_CPU_MODELID=85
    OS_VERSION='15.5'

    #act
    check_1210_cpu_subnuma_intel

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_cascadelake_snc2_enabled_ok() {

    #arrange
    LIB_PLATF_CPU_NUMANODES=16
    LIB_PLATF_CPU_SOCKETS=8
    LIB_PLATF_CPU_MODELID=85
    OS_VERSION='15.3'

    #act
    check_1210_cpu_subnuma_intel

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_icelake_snc2_not_enabled_ok() {

    #arrange
    LIB_PLATF_CPU_NUMANODES=2
    LIB_PLATF_CPU_SOCKETS=2
    LIB_PLATF_CPU_MODELID=106
    OS_VERSION='15.4'

    #act
    check_1210_cpu_subnuma_intel

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

# ==============================================================================
# CHECK LOGIC: Broadwell/Haswell (model < 85) - CoD must be disabled
# ==============================================================================

test_broadwell_cod_disabled_ok() {

    #arrange
    LIB_PLATF_CPU_NUMANODES=4
    LIB_PLATF_CPU_SOCKETS=4
    LIB_PLATF_CPU_MODELID=79
    OS_VERSION='12.5'

    #act
    check_1210_cpu_subnuma_intel

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_broadwell_cod_not_disabled_error() {

    #arrange
    LIB_PLATF_CPU_NUMANODES=8
    LIB_PLATF_CPU_SOCKETS=4
    LIB_PLATF_CPU_MODELID=79
    OS_VERSION='12.4'

    #act
    check_1210_cpu_subnuma_intel

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_haswell_cod_disabled_ok() {

    #arrange
    LIB_PLATF_CPU_NUMANODES=2
    LIB_PLATF_CPU_SOCKETS=2
    LIB_PLATF_CPU_MODELID=63
    OS_VERSION='12.5'

    #act
    check_1210_cpu_subnuma_intel

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_haswell_cod_not_disabled_error() {

    #arrange
    LIB_PLATF_CPU_NUMANODES=4
    LIB_PLATF_CPU_SOCKETS=2
    LIB_PLATF_CPU_MODELID=63
    OS_VERSION='12.3'

    #act
    check_1210_cpu_subnuma_intel

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_ivybridge_cod_disabled_ok() {

    #arrange
    LIB_PLATF_CPU_NUMANODES=4
    LIB_PLATF_CPU_SOCKETS=4
    LIB_PLATF_CPU_MODELID=62
    OS_VERSION='12.5'

    #act
    check_1210_cpu_subnuma_intel

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_ivybridge_cod_not_disabled_error() {

    #arrange
    LIB_PLATF_CPU_NUMANODES=8
    LIB_PLATF_CPU_SOCKETS=4
    LIB_PLATF_CPU_MODELID=62
    OS_VERSION='12.4'

    #act
    check_1210_cpu_subnuma_intel

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

# ==============================================================================
# SAP NOTE VERSION TESTS (RHEL variants)
# ==============================================================================

test_rhel7_note_assignment() {

    #arrange
    LIB_FUNC_IS_SLES() { return 1 ; }
    LIB_FUNC_IS_RHEL() { return 0 ; }
    LIB_PLATF_CPU_NUMANODES=4
    LIB_PLATF_CPU_SOCKETS=4
    LIB_PLATF_CPU_MODELID=79
    OS_VERSION='7.9'

    #act
    check_1210_cpu_subnuma_intel

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_rhel8_note_assignment() {

    #arrange
    LIB_FUNC_IS_SLES() { return 1 ; }
    LIB_FUNC_IS_RHEL() { return 0 ; }
    LIB_PLATF_CPU_NUMANODES=2
    LIB_PLATF_CPU_SOCKETS=2
    LIB_PLATF_CPU_MODELID=85
    OS_VERSION='8.6'

    #act
    check_1210_cpu_subnuma_intel

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_rhel9_note_assignment() {

    #arrange
    LIB_FUNC_IS_SLES() { return 1 ; }
    LIB_FUNC_IS_RHEL() { return 0 ; }
    LIB_PLATF_CPU_NUMANODES=8
    LIB_PLATF_CPU_SOCKETS=4
    LIB_PLATF_CPU_MODELID=106
    OS_VERSION='9.2'

    #act
    check_1210_cpu_subnuma_intel

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

# ==============================================================================
# SAP NOTE VERSION TESTS (SLES variants)
# ==============================================================================

test_sles12_note_assignment() {

    #arrange
    LIB_PLATF_CPU_NUMANODES=4
    LIB_PLATF_CPU_SOCKETS=4
    LIB_PLATF_CPU_MODELID=79
    OS_VERSION='12.5'

    #act
    check_1210_cpu_subnuma_intel

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_sles15_note_assignment() {

    #arrange
    LIB_PLATF_CPU_NUMANODES=2
    LIB_PLATF_CPU_SOCKETS=2
    LIB_PLATF_CPU_MODELID=85
    OS_VERSION='15.4'

    #act
    check_1210_cpu_subnuma_intel

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

# ==============================================================================
# shunit2 SETUP
# ==============================================================================

oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/1210_cpu_subnuma_intel.check
    source "${PROGRAM_DIR}/../../lib/check/1210_cpu_subnuma_intel.check"

}

# oneTimeTearDown
# setUp

tearDown() {
    # Reset mocked functions to defaults
    LIB_FUNC_IS_INTEL() { return 0 ; }
    LIB_FUNC_IS_BARE_METAL() { return 0 ; }
    LIB_FUNC_IS_SLES() { return 0 ; }
    LIB_FUNC_IS_RHEL() { return 1 ; }
}

#Import Libraries
# - order is important - sourcing shunit triggers testing
# - that's also the reason, why it could not be done during oneTimeSetup

#Load and run shUnit2
#shellcheck source=../shunit2
source "${PROGRAM_DIR}/../shunit2"

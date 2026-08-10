#!/usr/bin/env bash
# shellcheck disable=SC2329
set -u

if [[ -z "${PROGRAM_DIR:-}" ]]; then
    PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
    [[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
fi

# Mock variables
TEST_current_driver=''
TEST_mwait_exposed=''

# Mock functions
LIB_FUNC_IS_INTEL() { return 0 ; }
LIB_FUNC_IS_VIRT_KVM() { return 1 ; }
LIB_FUNC_IS_VIRT_VMWARE() { return 1 ; }
LIB_FUNC_IS_CLOUD_AMAZON() { return 1 ; }
LIB_FUNC_IS_CLOUD_GOOGLE() { return 1 ; }
LIB_FUNC_IS_SLES() { return 0 ; }
LIB_FUNC_IS_RHEL() { return 1 ; }
LIB_FUNC_IS_BARE_METAL() { return 0 ; }

assert_check_processed() {
    local rc=$1
    local context="${2:-}"
    if [[ ${rc} -eq 99 ]]; then
        bashunit::fail "RC=99 (unprocessed) - check logic did not reach a conclusion${context:+ in }${context}"
    fi
}

function test_non_intel_skipped() {

    #arrange
    LIB_FUNC_IS_INTEL() { return 1 ; }

    #act
    check_1400_cpu_idle_driver_intel
    local rc=$?

    #assert
    if [[ ${rc} -ne 3 ]]; then
        bashunit::fail "Expected RC=3 (skipped) on non-Intel systems"
    fi
    assert_true true
}

function test_intel_idle_default_ok() {

    #arrange
    TEST_current_driver='intel_idle'

    #act
    check_1400_cpu_idle_driver_intel
    local rc=$?

    #assert
    assert_check_processed ${rc} "default intel_idle"
    if [[ ${rc} -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for intel_idle on default platforms"
    fi
    assert_true true
}

function test_acpi_idle_warning() {

    #arrange
    TEST_current_driver='acpi_idle'

    #act
    check_1400_cpu_idle_driver_intel
    local rc=$?

    #assert
    assert_check_processed ${rc} "acpi_idle"
    if [[ ${rc} -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for acpi_idle"
    fi
    assert_true true
}

function test_kvm_non_cloud_haltpoll_expected_intel_idle_warns() {

    #arrange
    LIB_FUNC_IS_VIRT_KVM() { return 0 ; }
    TEST_current_driver='intel_idle'

    #act
    check_1400_cpu_idle_driver_intel
    local rc=$?

    #assert
    assert_check_processed ${rc} "kvm non-cloud intel_idle"
    if [[ ${rc} -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) when haltpoll is expected on KVM"
    fi
    assert_true true
}

function test_kvm_non_cloud_haltpoll_ok() {

    #arrange
    LIB_FUNC_IS_VIRT_KVM() { return 0 ; }
    TEST_current_driver='haltpoll'

    #act
    check_1400_cpu_idle_driver_intel
    local rc=$?

    #assert
    assert_check_processed ${rc} "kvm non-cloud haltpoll"
    if [[ ${rc} -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) when haltpoll is active on KVM"
    fi
    assert_true true
}

function test_kvm_amazon_keeps_intel_idle_ok() {

    #arrange
    LIB_FUNC_IS_VIRT_KVM() { return 0 ; }
    LIB_FUNC_IS_CLOUD_AMAZON() { return 0 ; }
    TEST_current_driver='intel_idle'

    #act
    check_1400_cpu_idle_driver_intel
    local rc=$?

    #assert
    assert_check_processed ${rc} "kvm amazon intel_idle"
    if [[ ${rc} -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for amazon KVM with intel_idle"
    fi
    assert_true true
}

function test_vmware_none_with_mwait_hidden_ok() {

    #arrange
    LIB_FUNC_IS_VIRT_VMWARE() { return 0 ; }
    LIB_FUNC_IS_BARE_METAL() { return 1 ; }
    TEST_current_driver='none'
    TEST_mwait_exposed='false'

    #act
    check_1400_cpu_idle_driver_intel
    local rc=$?

    #assert
    assert_check_processed ${rc} "vmware none mwait hidden"
    if [[ ${rc} -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for VMware with none driver and hidden MWAIT"
    fi
    assert_true true
}

function test_vmware_none_with_mwait_exposed_warns() {

    #arrange
    LIB_FUNC_IS_VIRT_VMWARE() { return 0 ; }
    LIB_FUNC_IS_BARE_METAL() { return 1 ; }
    TEST_current_driver='none'
    TEST_mwait_exposed='true'

    #act
    check_1400_cpu_idle_driver_intel
    local rc=$?

    #assert
    assert_check_processed ${rc} "vmware none mwait exposed"
    if [[ ${rc} -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for VMware with none driver and exposed MWAIT"
    fi
    assert_true true
}

function test_unknown_driver_errors() {

    #arrange
    TEST_current_driver='mystery_idle'

    #act
    check_1400_cpu_idle_driver_intel
    local rc=$?

    #assert
    assert_check_processed ${rc} "unknown driver"
    if [[ ${rc} -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for unknown CPUidle driver"
    fi
    assert_true true
}

function set_up_before_script() {

    set +eE

    [[ -n "${_1400_test_loaded:-}" ]] && return 0
    _1400_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/1400_cpu_idle_driver_intel.check
    source "${PROGRAM_DIR}/../../lib/check/1400_cpu_idle_driver_intel.check"

}

function set_up() {

    TEST_current_driver=''
    TEST_mwait_exposed=''

    LIB_FUNC_IS_INTEL() { return 0 ; }
    LIB_FUNC_IS_VIRT_KVM() { return 1 ; }
    LIB_FUNC_IS_VIRT_VMWARE() { return 1 ; }
    LIB_FUNC_IS_CLOUD_AMAZON() { return 1 ; }
    LIB_FUNC_IS_CLOUD_GOOGLE() { return 1 ; }
    LIB_FUNC_IS_SLES() { return 0 ; }
    LIB_FUNC_IS_RHEL() { return 1 ; }
    LIB_FUNC_IS_BARE_METAL() { return 0 ; }

}

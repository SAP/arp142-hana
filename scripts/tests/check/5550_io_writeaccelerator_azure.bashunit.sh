#!/usr/bin/env bash
#------------------------------------------------------------------
# bashunit: 5550_io_writeaccelerator_azure
# Tests for Premium SSD v1 Write Accelerator check on Azure
#------------------------------------------------------------------
set -u

if [[ -z "${PROGRAM_DIR:-}" ]]; then
    PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
    [[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
fi

# Guard to avoid reloading
[[ -n "${_5550_io_writeaccelerator_azure_test_loaded:-}" ]] && return 0
_5550_io_writeaccelerator_azure_test_loaded=true

# Variables to control cloud platform simulation
is_microsoft_cloud=0

# Mock variables
_imds_disks_response=''

# Mock functions
LIB_FUNC_IS_CLOUD_MICROSOFT() { return ${is_microsoft_cloud} ; }

# Mock curl to prevent actual HTTP calls
curl() { printf ''; return 1; }

function test_not_on_azure() {
    #arrange
    is_microsoft_cloud=1

    #act
    check_5550_io_writeaccelerator_azure
    local rc=$?

    #assert
    if [[ "$rc" != '3' ]]; then
        bashunit::fail "Expected CheckSkipped RC=3 but got RC=$rc"
    fi
    assert_true true
}

function test_imds_not_available() {
    #arrange
    is_microsoft_cloud=0
    _imds_disks_response=''

    #act
    check_5550_io_writeaccelerator_azure
    local rc=$?

    #assert
    if [[ "$rc" != '1' ]]; then
        bashunit::fail "Expected CheckWarning RC=1 but got RC=$rc"
    fi
    assert_true true
}

function test_no_premium_disks() {
    #arrange
    is_microsoft_cloud=0
    # real structure: storageAccountType only inside managedDisk, no writeAcceleratorEnabled for non-WA disk types
    _imds_disks_response='[{"lun":0,"caching":"None","managedDisk":{"storageAccountType":"StandardSSD_LRS","id":"..."}}]'

    #act
    check_5550_io_writeaccelerator_azure
    local rc=$?

    #assert
    if [[ "$rc" != '3' ]]; then
        bashunit::fail "Expected CheckSkipped RC=3 but got RC=$rc"
    fi
    assert_true true
}

function test_premium_wa_enabled() {
    #arrange
    is_microsoft_cloud=0
    _imds_disks_response='[{"lun":0,"caching":"None","writeAcceleratorEnabled":true,"managedDisk":{"storageAccountType":"Premium_LRS","id":"..."},"diskSizeGB":512}]'

    #act
    check_5550_io_writeaccelerator_azure
    local rc=$?

    #assert
    if [[ "$rc" != '0' ]]; then
        bashunit::fail "Expected CheckOk RC=0 but got RC=$rc"
    fi
    assert_true true
}

function test_premium_wa_disabled() {
    #arrange
    is_microsoft_cloud=0
    _imds_disks_response='[{"lun":8,"caching":"None","writeAcceleratorEnabled":false,"managedDisk":{"storageAccountType":"Premium_LRS","id":"..."},"diskSizeGB":4066}]'

    #act
    check_5550_io_writeaccelerator_azure
    local rc=$?

    #assert
    if [[ "$rc" != '1' ]]; then
        bashunit::fail "Expected CheckWarning RC=1 but got RC=$rc"
    fi
    assert_true true
}

function test_multiple_disks_all_wa_enabled() {
    #arrange
    is_microsoft_cloud=0
    _imds_disks_response='[{"lun":0,"writeAcceleratorEnabled":true,"managedDisk":{"storageAccountType":"Premium_LRS","id":"..."}},{"lun":1,"writeAcceleratorEnabled":true,"managedDisk":{"storageAccountType":"Premium_LRS","id":"..."}}]'

    #act
    check_5550_io_writeaccelerator_azure
    local rc=$?

    #assert
    if [[ "$rc" != '0' ]]; then
        bashunit::fail "Expected CheckOk RC=0 but got RC=$rc"
    fi
    assert_true true
}

function test_multiple_disks_one_wa_enabled_one_disabled() {
    # At least one Premium v1 has WA enabled -> OK
    #arrange
    is_microsoft_cloud=0
    _imds_disks_response='[{"lun":0,"writeAcceleratorEnabled":true,"managedDisk":{"storageAccountType":"Premium_LRS","id":"..."}},{"lun":1,"writeAcceleratorEnabled":false,"managedDisk":{"storageAccountType":"Premium_LRS","id":"..."}}]'

    #act
    check_5550_io_writeaccelerator_azure
    local rc=$?

    #assert
    if [[ "$rc" != '0' ]]; then
        bashunit::fail "Expected CheckOk RC=0 but got RC=$rc - at least one WA enabled"
    fi
    assert_true true
}

function test_multiple_disks_none_wa_enabled() {
    # No Premium v1 has WA enabled -> Warning
    #arrange
    is_microsoft_cloud=0
    _imds_disks_response='[{"lun":0,"writeAcceleratorEnabled":false,"managedDisk":{"storageAccountType":"Premium_LRS","id":"..."}},{"lun":1,"writeAcceleratorEnabled":false,"managedDisk":{"storageAccountType":"Premium_LRS","id":"..."}}]'

    #act
    check_5550_io_writeaccelerator_azure
    local rc=$?

    #assert
    if [[ "$rc" != '1' ]]; then
        bashunit::fail "Expected CheckWarning RC=1 but got RC=$rc"
    fi
    assert_true true
}

function test_mixed_disk_types_premium_wa_enabled() {
    # PremiumV2_LRS and UltraSSD_LRS have no writeAcceleratorEnabled field (real behaviour)
    #arrange
    is_microsoft_cloud=0
    _imds_disks_response='[{"lun":0,"writeAcceleratorEnabled":true,"managedDisk":{"storageAccountType":"Premium_LRS","id":"..."}},{"lun":4,"managedDisk":{"storageAccountType":"PremiumV2_LRS","id":"..."}},{"lun":5,"managedDisk":{"storageAccountType":"UltraSSD_LRS","id":"..."}}]'

    #act
    check_5550_io_writeaccelerator_azure
    local rc=$?

    #assert
    if [[ "$rc" != '0' ]]; then
        bashunit::fail "Expected CheckOk RC=0 but got RC=$rc - PremiumV2_LRS/UltraSSD should be ignored"
    fi
    assert_true true
}

function test_premium_wa_field_absent() {
    # Premium_LRS disk with no writeAcceleratorEnabled field -> treat as not enabled -> Warning
    #arrange
    is_microsoft_cloud=0
    _imds_disks_response='[{"lun":8,"caching":"None","managedDisk":{"storageAccountType":"Premium_LRS","id":"..."},"diskSizeGB":4066}]'

    #act
    check_5550_io_writeaccelerator_azure
    local rc=$?

    #assert
    if [[ "$rc" != '1' ]]; then
        bashunit::fail "Expected CheckWarning RC=1 but got RC=$rc - absent writeAcceleratorEnabled should be treated as not enabled"
    fi
    assert_true true
}

function test_real_world_premiumv2_and_premium_wa_disabled() {
    # Real-world: PremiumV2_LRS (no WA field) + Premium_LRS with WA=false -> Warning
    #arrange
    is_microsoft_cloud=0
    _imds_disks_response='[{"lun":4,"name":"name4","createOption":"Attach","caching":"None","managedDisk":{"storageAccountType":"PremiumV2_LRS","id":"..."},"deleteOption":"Detach","diskSizeGB":4096,"toBeDetached":false},{"lun":8,"name":"name8","createOption":"Attach","caching":"None","writeAcceleratorEnabled":false,"managedDisk":{"storageAccountType":"Premium_LRS","id":"..."},"deleteOption":"Detach","diskSizeGB":4066,"toBeDetached":false}]'

    #act
    check_5550_io_writeaccelerator_azure
    local rc=$?

    #assert
    if [[ "$rc" != '1' ]]; then
        bashunit::fail "Expected CheckWarning RC=1 but got RC=$rc"
    fi
    assert_true true
}

function set_up_before_script() {
    set +eE

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/5550_io_writeaccelerator_azure.check
    source "${PROGRAM_DIR}/../../lib/check/5550_io_writeaccelerator_azure.check"
}

function set_up() {
    # Reset mock variables
    is_microsoft_cloud=0
    _imds_disks_response=''
}

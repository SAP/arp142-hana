#!/usr/bin/env bash
#------------------------------------------------------------------
# bashunit migration: 5560_xfs_mount_stripe_size_azure_test.sh
# Tests for HANA XFS mount stripe size check (Azure)
#------------------------------------------------------------------
set -u

if [[ -z "${PROGRAM_DIR:-}" ]]; then
    PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
    [[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
fi

# Guard to avoid reloading
[[ -n "${_5560_xfs_mount_stripe_size_azure_test_loaded:-}" ]] && return 0
_5560_xfs_mount_stripe_size_azure_test_loaded=true

# mock PREREQUISITE functions
LIB_FUNC_IS_CLOUD_MICROSOFT() { return ${_microsoft_rc:-1} ; }

declare -A _mock_min_io   # key=major:minor, value=minimum_io_size in bytes
declare -A _mock_opt_io   # key=major:minor, value=optimal_io_size in bytes (0 = not striped)

# Mock sysfs helpers - defined before sourcing the check file so the declare -f guard preserves them
_sysfs_min_io() { echo "${_mock_min_io[${1}]:-0}"; }
_sysfs_opt_io() { echo "${_mock_opt_io[${1}]:-0}"; }

_microsoft_rc=1
hana_mountinfo=()

# override grep to simulate /proc/self/mountinfo
grep() {
    case "$*" in
        *'/proc/self/mountinfo'* )
            printf -- '%s\n' "${hana_mountinfo[@]}" | command grep "$1" "$2" ;;
        *)
            command grep "$@" ;;
    esac
}

function test_not_azure() {
    # arrange
    _microsoft_rc=1

    # act
    check_5560_xfs_mount_stripe_size_azure
    local rc=$?

    # assert
    if [[ "$rc" != '3' ]]; then
        bashunit::fail "Expected CheckSkipped RC=3 but got RC=$rc"
    fi
    assert_true true
}

function test_no_hana_mounts() {
    # arrange
    _microsoft_rc=0
    hana_mountinfo+=('1 1 8:0 / / rw - ext4 /dev/sda1 rw')

    # act
    check_5560_xfs_mount_stripe_size_azure
    local rc=$?

    # assert
    if [[ "$rc" != '3' ]]; then
        bashunit::fail "Expected CheckSkipped RC=3 but got RC=$rc"
    fi
    assert_true true
}

function test_no_hana_mounts_device_path_contains_hana() {
    # arrange - device path contains '/hana/data' but mountpoint does not
    # the PCRE lookbehind (?<= ) must NOT match /hana/data inside the device field
    _microsoft_rc=0
    hana_mountinfo+=('2 1 9:0 / /backup rw - ext4 /dev/hana/data_backup rw')

    # act
    check_5560_xfs_mount_stripe_size_azure
    local rc=$?

    # assert
    if [[ "$rc" != '3' ]]; then
        bashunit::fail "Expected CheckSkipped RC=3 but got RC=$rc"
    fi
    assert_true true
}

function test_hana_mounts_not_xfs() {
    # arrange
    _microsoft_rc=0
    hana_mountinfo+=('2 1 8:1 / /hana/data rw - ext4 /dev/mapper/vg_hana_data-lv_hana_data rw')
    hana_mountinfo+=('3 1 8:2 / /hana/log  rw - ext4 /dev/mapper/vg_hana_log-lv_hana_log rw')

    # act
    check_5560_xfs_mount_stripe_size_azure
    local rc=$?

    # assert
    if [[ "$rc" != '3' ]]; then
        bashunit::fail "Expected CheckSkipped RC=3 but got RC=$rc"
    fi
    assert_true true
}

function test_data_and_log_correct_stripe() {
    # arrange
    _microsoft_rc=0
    hana_mountinfo+=('2 1 8:1 / /hana/data     rw - xfs /dev/mapper/vg_hana_data-lv_hana_data rw')
    hana_mountinfo+=('3 1 8:2 / /hana/log      rw - xfs /dev/mapper/vg_hana_log-lv_hana_log rw')
    hana_mountinfo+=('4 1 8:3 / /hana/data/BTP rw - xfs /dev/mapper/vg_hana_data_btp-lv_hana_data_btp rw')
    hana_mountinfo+=('5 1 8:4 / /hana/log/ASD  rw - xfs /dev/mapper/vg_hana_log_asd-lv_hana_log_asd rw')
    _mock_min_io["8:1"]=262144 ; _mock_opt_io["8:1"]=1048576  # 256 KiB x 4 stripes
    _mock_min_io["8:2"]=65536  ; _mock_opt_io["8:2"]=262144   #  64 KiB x 4 stripes
    _mock_min_io["8:3"]=262144 ; _mock_opt_io["8:3"]=1048576
    _mock_min_io["8:4"]=65536  ; _mock_opt_io["8:4"]=262144

    # act
    check_5560_xfs_mount_stripe_size_azure
    local rc=$?

    # assert
    if [[ "$rc" != '0' ]]; then
        bashunit::fail "Expected CheckOk RC=0 but got RC=$rc"
    fi
    assert_true true
}

function test_data_wrong_stripe_size() {
    # arrange
    _microsoft_rc=0
    hana_mountinfo+=('2 1 8:1 / /hana/data     rw - xfs /dev/mapper/vg_hana_data-lv_hana_data rw')
    hana_mountinfo+=('3 1 8:2 / /hana/data/BTP rw - xfs /dev/mapper/vg_hana_data_btp-lv_hana_data_btp rw')
    _mock_min_io["8:1"]=131072 ; _mock_opt_io["8:1"]=524288   # 128 KiB x 4 stripes (wrong)
    _mock_min_io["8:2"]=131072 ; _mock_opt_io["8:2"]=524288

    # act
    check_5560_xfs_mount_stripe_size_azure
    local rc=$?

    # assert
    if [[ "$rc" != '2' ]]; then
        bashunit::fail "Expected CheckError RC=2 but got RC=$rc"
    fi
    assert_true true
}

function test_log_wrong_stripe_size() {
    # arrange
    _microsoft_rc=0
    hana_mountinfo+=('2 1 8:1 / /hana/log     rw - xfs /dev/mapper/vg_hana_log-lv_hana_log rw')
    hana_mountinfo+=('3 1 8:2 / /hana/log/ASD rw - xfs /dev/mapper/vg_hana_log_asd-lv_hana_log_asd rw')
    _mock_min_io["8:1"]=131072 ; _mock_opt_io["8:1"]=524288   # 128 KiB x 4 stripes (wrong)
    _mock_min_io["8:2"]=131072 ; _mock_opt_io["8:2"]=524288

    # act
    check_5560_xfs_mount_stripe_size_azure
    local rc=$?

    # assert
    if [[ "$rc" != '2' ]]; then
        bashunit::fail "Expected CheckError RC=2 but got RC=$rc"
    fi
    assert_true true
}

function test_lv_not_striped() {
    # arrange
    _microsoft_rc=0
    hana_mountinfo+=('2 1 8:1 / /hana/data     rw - xfs /dev/mapper/vg_hana_data-lv_hana_data rw')
    hana_mountinfo+=('3 1 8:2 / /hana/data/BTP rw - xfs /dev/mapper/vg_hana_data_btp-lv_hana_data_btp rw')
    _mock_min_io["8:1"]=4096 ; _mock_opt_io["8:1"]=0   # linear, not striped
    _mock_min_io["8:2"]=4096 ; _mock_opt_io["8:2"]=0

    # act
    check_5560_xfs_mount_stripe_size_azure
    local rc=$?

    # assert
    if [[ "$rc" != '3' ]]; then
        bashunit::fail "Expected CheckSkipped RC=3 but got RC=$rc"
    fi
    assert_true true
}

function test_data_striped_log_not_striped() {
    # arrange - /hana/data is striped correctly; /hana/log is linear (not striped)
    # expected: per-volume <OK> for data, <SKIP> for log → summary "At least one correct" → RC=0
    _microsoft_rc=0
    hana_mountinfo+=('2 1 8:1 / /hana/data rw - xfs /dev/mapper/vg_hana_data-lv_hana_data rw')
    hana_mountinfo+=('3 1 8:2 / /hana/log  rw - xfs /dev/mapper/vg_hana_log-lv_hana_log rw')
    _mock_min_io["8:1"]=262144 ; _mock_opt_io["8:1"]=1048576  # 256 KiB x 4 stripes (correct)
    _mock_min_io["8:2"]=4096   ; _mock_opt_io["8:2"]=0        # linear, not striped

    # act
    check_5560_xfs_mount_stripe_size_azure
    local rc=$?

    # assert
    if [[ "$rc" != '0' ]]; then
        bashunit::fail "Expected CheckOk RC=0 but got RC=$rc"
    fi
    assert_true true
}

function test_data_correct_log_wrong_stripe_size() {
    # arrange
    _microsoft_rc=0
    hana_mountinfo+=('2 1 8:1 / /hana/data     rw - xfs /dev/mapper/vg_hana_data-lv_hana_data rw')
    hana_mountinfo+=('3 1 8:2 / /hana/log      rw - xfs /dev/mapper/vg_hana_log-lv_hana_log rw')
    hana_mountinfo+=('4 1 8:3 / /hana/data/BTP rw - xfs /dev/mapper/vg_hana_data_btp-lv_hana_data_btp rw')
    hana_mountinfo+=('5 1 8:4 / /hana/log/ASD  rw - xfs /dev/mapper/vg_hana_log_asd-lv_hana_log_asd rw')
    _mock_min_io["8:1"]=262144 ; _mock_opt_io["8:1"]=1048576  # 256 KiB x 4 (correct)
    _mock_min_io["8:2"]=131072 ; _mock_opt_io["8:2"]=524288   # 128 KiB x 4 (wrong)
    _mock_min_io["8:3"]=262144 ; _mock_opt_io["8:3"]=1048576
    _mock_min_io["8:4"]=131072 ; _mock_opt_io["8:4"]=524288

    # act
    check_5560_xfs_mount_stripe_size_azure
    local rc=$?

    # assert
    if [[ "$rc" != '2' ]]; then
        bashunit::fail "Expected CheckError RC=2 but got RC=$rc"
    fi
    assert_true true
}

function set_up_before_script() {
    set +eE

    [[ -n "${HANA_HELPER_PROGVERSION:-}" ]] && return 0

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/5560_xfs_mount_stripe_size_azure.check
    source "${PROGRAM_DIR}/../../lib/check/5560_xfs_mount_stripe_size_azure.check"
}

function set_up() {
    _microsoft_rc=1
    hana_mountinfo=()
    _mock_min_io=()
    _mock_opt_io=()
}
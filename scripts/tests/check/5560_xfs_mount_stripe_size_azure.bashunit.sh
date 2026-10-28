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

# mock PREREQUISITE functions
LIB_FUNC_IS_CLOUD_MICROSOFT() { return ${_microsoft_rc:-1} ; }

assert_check_processed() {
    local rc=$1
    local context="${2:-}"
    assert_not_equals 99 "${rc}" "Check must be processed${context:+ in }${context}"
}

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
    assert_check_processed "${rc}" "not Azure"
    assert_exit_code 3 '' "${rc}"
}

function test_no_hana_mounts() {
    # arrange
    _microsoft_rc=0
    hana_mountinfo+=('1 1 8:0 / / rw - ext4 /dev/sda1 rw')

    # act
    check_5560_xfs_mount_stripe_size_azure
    local rc=$?

    # assert
    assert_check_processed "${rc}" "no HANA mounts"
    assert_exit_code 3 '' "${rc}"
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
    assert_check_processed "${rc}" "device path contains hana"
    assert_exit_code 3 '' "${rc}"
}

function test_similarly_named_mountpoints_are_ignored() {
    # arrange
    _microsoft_rc=0
    hana_mountinfo+=('6 1 8:5 / /hana/database rw - xfs /dev/mapper/vg_database-lv_database rw')
    hana_mountinfo+=('7 1 8:6 / /hana/logical rw - xfs /dev/mapper/vg_logical-lv_logical rw')
    _mock_io "8:5" 131072 524288
    _mock_io "8:6" 131072 524288

    # act
    check_5560_xfs_mount_stripe_size_azure
    local rc=$?

    # assert
    assert_check_processed "${rc}" "similarly named mountpoints"
    assert_exit_code 3 '' "${rc}"
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
    assert_check_processed "${rc}" "non-XFS HANA mounts"
    assert_exit_code 3 '' "${rc}"
}

function test_data_and_log_correct_stripe() {
    # arrange
    _microsoft_rc=0
    hana_mountinfo+=('2 1 8:1 / /hana/data     rw - xfs /dev/mapper/vg_hana_data-lv_hana_data rw')
    hana_mountinfo+=('3 1 8:2 / /hana/log      rw - xfs /dev/mapper/vg_hana_log-lv_hana_log rw')
    hana_mountinfo+=('4 1 8:3 / /hana/data/BTP rw - xfs /dev/mapper/vg_hana_data_btp-lv_hana_data_btp rw')
    hana_mountinfo+=('5 1 8:4 / /hana/log/ASD  rw - xfs /dev/mapper/vg_hana_log_asd-lv_hana_log_asd rw')
    _mock_io "8:1" 262144 1048576  # 256 KiB x 4 stripes
    _mock_io "8:2" 65536 262144    #  64 KiB x 4 stripes
    _mock_io "8:3" 262144 1048576
    _mock_io "8:4" 65536 262144

    # act
    check_5560_xfs_mount_stripe_size_azure
    local rc=$?

    # assert
    assert_check_processed "${rc}" "correct stripe sizes"
    assert_exit_code 0 '' "${rc}"
}

function test_data_wrong_stripe_size() {
    # arrange
    _microsoft_rc=0
    hana_mountinfo+=('2 1 8:1 / /hana/data     rw - xfs /dev/mapper/vg_hana_data-lv_hana_data rw')
    hana_mountinfo+=('3 1 8:2 / /hana/data/BTP rw - xfs /dev/mapper/vg_hana_data_btp-lv_hana_data_btp rw')
    _mock_io "8:1" 131072 524288  # 128 KiB x 4 stripes (wrong)
    _mock_io "8:2" 131072 524288

    # act
    check_5560_xfs_mount_stripe_size_azure
    local rc=$?

    # assert
    assert_check_processed "${rc}" "wrong data stripe size"
    assert_exit_code 2 '' "${rc}"
}

function test_log_wrong_stripe_size() {
    # arrange
    _microsoft_rc=0
    hana_mountinfo+=('2 1 8:1 / /hana/log     rw - xfs /dev/mapper/vg_hana_log-lv_hana_log rw')
    hana_mountinfo+=('3 1 8:2 / /hana/log/ASD rw - xfs /dev/mapper/vg_hana_log_asd-lv_hana_log_asd rw')
    _mock_io "8:1" 131072 524288  # 128 KiB x 4 stripes (wrong)
    _mock_io "8:2" 131072 524288

    # act
    check_5560_xfs_mount_stripe_size_azure
    local rc=$?

    # assert
    assert_check_processed "${rc}" "wrong log stripe size"
    assert_exit_code 2 '' "${rc}"
}

function test_lv_not_striped() {
    # arrange
    _microsoft_rc=0
    hana_mountinfo+=('2 1 8:1 / /hana/data     rw - xfs /dev/mapper/vg_hana_data-lv_hana_data rw')
    hana_mountinfo+=('3 1 8:2 / /hana/data/BTP rw - xfs /dev/mapper/vg_hana_data_btp-lv_hana_data_btp rw')
    _mock_io "8:1" 4096 0  # linear, not striped
    _mock_io "8:2" 4096 0

    # act
    check_5560_xfs_mount_stripe_size_azure
    local rc=$?

    # assert
    assert_check_processed "${rc}" "unstriped volume"
    assert_exit_code 3 '' "${rc}"
}

function test_data_striped_log_not_striped() {
    # arrange - /hana/data is striped correctly; /hana/log is linear (not striped)
    # expected: per-volume <OK> for data, <SKIP> for log â†’ summary "At least one correct" â†’ RC=0
    _microsoft_rc=0
    hana_mountinfo+=('2 1 8:1 / /hana/data rw - xfs /dev/mapper/vg_hana_data-lv_hana_data rw')
    hana_mountinfo+=('3 1 8:2 / /hana/log  rw - xfs /dev/mapper/vg_hana_log-lv_hana_log rw')
    _mock_io "8:1" 262144 1048576  # 256 KiB x 4 stripes (correct)
    _mock_io "8:2" 4096 0          # linear, not striped

    # act
    check_5560_xfs_mount_stripe_size_azure
    local rc=$?

    # assert
    assert_check_processed "${rc}" "data striped and log unstriped"
    assert_exit_code 0 '' "${rc}"
}

function test_data_correct_log_wrong_stripe_size() {
    # arrange
    _microsoft_rc=0
    hana_mountinfo+=('2 1 8:1 / /hana/data     rw - xfs /dev/mapper/vg_hana_data-lv_hana_data rw')
    hana_mountinfo+=('3 1 8:2 / /hana/log      rw - xfs /dev/mapper/vg_hana_log-lv_hana_log rw')
    hana_mountinfo+=('4 1 8:3 / /hana/data/BTP rw - xfs /dev/mapper/vg_hana_data_btp-lv_hana_data_btp rw')
    hana_mountinfo+=('5 1 8:4 / /hana/log/ASD  rw - xfs /dev/mapper/vg_hana_log_asd-lv_hana_log_asd rw')
    _mock_io "8:1" 262144 1048576  # 256 KiB x 4 (correct)
    _mock_io "8:2" 131072 524288   # 128 KiB x 4 (wrong)
    _mock_io "8:3" 262144 1048576
    _mock_io "8:4" 131072 524288

    # act
    check_5560_xfs_mount_stripe_size_azure
    local rc=$?

    # assert
    assert_check_processed "${rc}" "wrong log stripe size with correct data"
    assert_exit_code 2 '' "${rc}"
}

function set_up_before_script() {
    set +eE

    [[ -n "${_5560_test_loaded:-}" ]] && return 0
    _5560_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/5560_xfs_mount_stripe_size_azure.check
    source "${PROGRAM_DIR}/../../lib/check/5560_xfs_mount_stripe_size_azure.check"
}

function set_up() {
    _microsoft_rc=1
    hana_mountinfo=()
    TEST_SYSFS_DEV_BLOCK_ROOT=$(mktemp -d)
}

function _mock_io() {
    local device=$1
    local min_io=$2
    local opt_io=$3
    local queue_path="${TEST_SYSFS_DEV_BLOCK_ROOT}/${device}/queue"

    mkdir -p "${queue_path}"
    printf '%s\n' "${min_io}" > "${queue_path}/minimum_io_size"
    printf '%s\n' "${opt_io}" > "${queue_path}/optimal_io_size"
}

function tear_down() {
    if [[ -n "${TEST_SYSFS_DEV_BLOCK_ROOT:-}" && -d "${TEST_SYSFS_DEV_BLOCK_ROOT}" ]]; then
        rm -rf "${TEST_SYSFS_DEV_BLOCK_ROOT}"
    fi
}

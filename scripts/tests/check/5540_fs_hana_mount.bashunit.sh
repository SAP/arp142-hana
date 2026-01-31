#!/usr/bin/env bash
#------------------------------------------------------------------
# bashunit migration: 5540_fs_hana_mount_test.sh
# Tests for HANA filesystem mount check
#------------------------------------------------------------------
set -u

if [[ -z "${PROGRAM_DIR:-}" ]]; then
    PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
    [[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
fi

# Guard to avoid reloading
[[ -n "${_5540_fs_hana_mount_test_loaded:-}" ]] && return 0
_5540_fs_hana_mount_test_loaded=true

# mock PREREQUISITE functions
LIB_FUNC_STRINGCONTAIN() { [[ -z "${1##*"$2"*}" ]] && [[ -z "$2" || -n "$1" ]]; }

hana_mounts=()

# override grep to simulate /proc/mounts
grep() {
    case "$*" in
        *'/proc/mounts'* )
            printf -- '%s\n' "${hana_mounts[@]}" | command grep "$1" "$2" ;;
        *)
            command grep "$@" ;;
    esac
}

function test_no_hana_mounts() {
    # arrange
    hana_mounts=()
    hana_mounts+=('/mnt/cpsapnfsstoracc01 cifs nofail,vers=3.0,credentials=/etc/smbcredentials/cpsapnfsstoracc01.cred,dir_mode=0777')

    # act
    check_5540_fs_hana_mount
    local rc=$?

    # assert
    if [[ "$rc" != '3' ]]; then
        bashunit::fail "Expected CheckSkipped RC=3 but got RC=$rc"
    fi
}

function test_all_supported_fs() {
    # arrange
    hana_mounts=()
    hana_mounts+=('server:/vol /hana/data xfs rw,noatime')
    hana_mounts+=('server:/vol /hana/data gpfs rw,noatime')
    hana_mounts+=('server:/vol /hana/data nfs rw,noatime')
    hana_mounts+=('server:/vol /hana/data nfs4 rw,noatime')
    hana_mounts+=('server:/vol /hana/log xfs rw,noatime')
    hana_mounts+=('server:/vol /hana/log gpfs rw,noatime')
    hana_mounts+=('server:/vol /hana/log nfs rw,noatime')
    hana_mounts+=('server:/vol /hana/log nfs4 rw,noatime')
    hana_mounts+=('0.0.0.0:/vol /hana/data/OQL xfs rw,noatime')
    hana_mounts+=('0.0.0.0:/vol /hana/data/OQL gpfs rw,noatime')
    hana_mounts+=('0.0.0.0:/vol /hana/data/OQL nfs rw,noatime')
    hana_mounts+=('0.0.0.0:/vol /hana/data/OQL nfs4 rw,noatime')
    hana_mounts+=('0.0.0.0:/vol /hana/log/OQL xfs rw,noatime')
    hana_mounts+=('0.0.0.0:/vol /hana/log/OQL nfs rw,noatime')
    hana_mounts+=('0.0.0.0:/vol /hana/log/OQL nfs4 rw,noatime')
    hana_mounts+=('0.0.0.0:/vol /hana/log/OQL gpfs rw,noatime')
    hana_mounts+=('0.0.0.0:/hana/data /hana/data nfs4 rw,relatime,vers=4.1,rsize=262144,wsize=262144')
    hana_mounts+=('0.0.0.0:/hana/log /hana/log nfs4 rw,relatime,vers=4.1,rsize=262144,wsize=262144')

    # act
    check_5540_fs_hana_mount
    local rc=$?

    # assert
    if [[ "$rc" != '0' ]]; then
        bashunit::fail "Expected CheckOk RC=0 but got RC=$rc"
    fi
}

function test_expired_certification_fs() {
    # arrange
    hana_mounts=()
    hana_mounts+=('0.0.0.0:/vol /hana/log ext3 rw,noatime')
    hana_mounts+=('0.0.0.0:/vol /hana/log ocfs2 rw,noatime')
    hana_mounts+=('0.0.0.0:/vol /hana/log mpfs rw,noatime')
    hana_mounts+=('0.0.0.0:/vol /hana/data ext3 rw,noatime')
    hana_mounts+=('0.0.0.0:/vol /hana/data ocfs2 rw,noatime')
    hana_mounts+=('0.0.0.0:/vol /hana/data mpfs rw,noatime')

    # act
    check_5540_fs_hana_mount
    local rc=$?

    # assert
    if [[ "$rc" != '1' ]]; then
        bashunit::fail "Expected CheckWarn RC=1 but got RC=$rc"
    fi
}

function test_unsupported_fs() {
    # arrange
    hana_mounts=()
    hana_mounts+=('server:/vol /hana/data ext4 rw,noatime')
    hana_mounts+=('server:/vol /hana/log ext4 defaults')
    hana_mounts+=('server:/vol /hana/data btrfs rw,noatime')
    hana_mounts+=('server:/vol /hana/log btrfs defaults')

    # act
    check_5540_fs_hana_mount
    local rc=$?

    # assert
    if [[ "$rc" != '2' ]]; then
        bashunit::fail "Expected CheckError RC=2 but got RC=$rc"
    fi
}

function set_up_before_script() {
    set +eE

    [[ -n "${HANA_HELPER_PROGVERSION:-}" ]] && return 0

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/5540_fs_hana_mount.check
    source "${PROGRAM_DIR}/../../lib/check/5540_fs_hana_mount.check"
}

function set_up() {
    hana_mounts=()
}

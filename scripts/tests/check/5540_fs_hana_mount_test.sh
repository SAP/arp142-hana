#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
readonly PROGRAM_DIR

# mock PREREQUISITE functions
LIB_FUNC_STRINGCONTAIN() { [[ -z "${1##*"$2"*}" ]] && [[ -z "$2" || -n "$1" ]]; }

# override grep to simulate /proc/mounts
grep() {
    case "$*" in
        *'/proc/mounts'* )
            printf -- '%s\n' "${hana_mounts[@]}" | command grep "$1" "$2"
            ;;
        *)
            command grep "$@"
            ;;
    esac
}

hana_mounts=()

test_no_hana_mounts() {

    # arrange
    hana_mounts=()
    hana_mounts+=('/mnt/cpsapnfsstoracc01 cifs nofail,vers=3.0,credentials=/etc/smbcredentials/cpsapnfsstoracc01.cred,dir_mode=0777')

    # act
    check_5540_fs_hana_mount

    # assert
    assertEquals "CheckSkipped? RC" '3' "$?"
}

test_all_supported_fs() {

    # arrange
    hana_mounts=()
    hana_mounts+=('server:/vol /hana/data xfs rw,noatime')
    hana_mounts+=('server:/vol /hana/data gpfs rw,noatime')
    hana_mounts+=('server:/vol /hana/data nfs rw,noatime')
    hana_mounts+=('server:/vol /hana/log xfs rw,noatime')
    hana_mounts+=('server:/vol /hana/log gpfs rw,noatime')
    hana_mounts+=('server:/vol /hana/log nfs rw,noatime')
    hana_mounts+=('server:/vol /hana/shared nfs ro,noexec,nosuid')
    hana_mounts+=('server:/vol /hana/shared gpfs ro,noexec,nosuid')
    hana_mounts+=('server:/vol /hana/shared xfs ro,noexec,nosuid')
    hana_mounts+=('0.0.0.0:/vol /hana/data/OQL xfs rw,noatime')
    hana_mounts+=('0.0.0.0:/vol /hana/data/OQL gpfs rw,noatime')
    hana_mounts+=('0.0.0.0:/vol /hana/data/OQL nfs rw,noatime')
    hana_mounts+=('0.0.0.0:/vol /hana/log/OQL xfs rw,noatime')
    hana_mounts+=('0.0.0.0:/vol /hana/log/OQL nfs rw,noatime')
    hana_mounts+=('0.0.0.0:/vol /hana/log/OQL gpfs rw,noatime')
    hana_mounts+=('0.0.0.0:/vol /hana/shared/OQL xfs rw,noatime')
    hana_mounts+=('0.0.0.0:/vol /hana/shared/OQL nfs rw,noatime')
    hana_mounts+=('0.0.0.0:/vol /hana/shared/OQL gpfs rw,noatime')

    # act
    check_5540_fs_hana_mount

    # assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_expired_certification_fs() {

    # arrange
    hana_mounts=()
    hana_mounts+=('0.0.0.0:/vol /hana/log ext3 rw,noatime')
    hana_mounts+=('0.0.0.0:/vol /hana/log ocfs2 rw,noatime')
    hana_mounts+=('0.0.0.0:/vol /hana/log mpfs rw,noatime')
    hana_mounts+=('0.0.0.0:/vol /hana/data ext3 rw,noatime')
    hana_mounts+=('0.0.0.0:/vol /hana/data ocfs2 rw,noatime')
    hana_mounts+=('0.0.0.0:/vol /hana/data mpfs rw,noatime')
    hana_mounts+=('0.0.0.0:/vol /hana/shared ext3 rw,noatime')
    hana_mounts+=('0.0.0.0:/vol /hana/shared ocfs2 rw,noatime')
    hana_mounts+=('0.0.0.0:/vol /hana/shared mpfs rw,noatime')

    # act
    check_5540_fs_hana_mount

    # assert
    assertEquals "CheckWarn? RC" '1' "$?"
}

test_unsupported_fs() {

    # arrange
    hana_mounts=()
    hana_mounts+=('server:/vol /hana/data ext4 rw,noatime')
    hana_mounts+=('server:/vol /hana/log ext4 defaults')
    hana_mounts+=('server:/vol /hana/shared ext4 ro,noexec,nosuid')
    hana_mounts+=('server:/vol /hana/data btrfs rw,noatime')
    hana_mounts+=('server:/vol /hana/log btrfs defaults')
    hana_mounts+=('server:/vol /hana/shared btrfs ro,noexec,nosuid')

    # act
    check_5540_fs_hana_mount

    # assert
    assertEquals "CheckError? RC" '2' "$?"
}

oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/5540_fs_hana_mount.check
    source "${PROGRAM_DIR}/../../lib/check/5540_fs_hana_mount.check"
}

setUp() {
    hana_mounts=()
}

# Load shUnit2
#shellcheck source=../shunit2
source "${PROGRAM_DIR}/../shunit2"

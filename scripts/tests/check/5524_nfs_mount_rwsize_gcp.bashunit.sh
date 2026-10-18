#!/usr/bin/env bash
# shellcheck disable=SC2329
#------------------------------------------------------------------
# Tests for NFS mount rsize/wsize check on Google Cloud Platform
#------------------------------------------------------------------
set -u

if [[ -z "${PROGRAM_DIR:-}" ]]; then
    PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
    [[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
fi

#mock PREREQUISITE functions
LIB_FUNC_IS_CLOUD_GOOGLE() { return 0 ; }
LIB_FUNC_STRINGCONTAIN() { [[ -z "${1##*"$2"*}" ]] && [[ -z "$2" || -n "$1" ]]; }

assert_check_processed() {
    local rc=$1
    local context="${2:-}"
    assert_not_equals 99 "${rc}" "Check must be processed${context:+ in }${context}"
}

nfs_mounts=()

grep() {
    case "$*" in
        *'/proc/mounts')
            printf -- '%s\n' "${nfs_mounts[@]}" | command grep "$1" "$2" ;;
        *)
            command grep "$@" ;;
    esac
}

function test_nfs_not_mounted() {
    #arrange
    nfs_mounts=()
    nfs_mounts+=('//cpsapnfsstoracc01/cgadmin /mnt/cpsapnfsstoracc01 cifs nofail,vers=3.0,credentials=/etc/smbcredentials/cpsapnfsstoracc01.cred,dir_mode=0777')

    #act
    check_5524_nfs_mount_rwsize_gcp
    local rc=$?

    #assert
    assert_check_processed "${rc}" 'no NFS filesystem mounted'
    assert_exit_code 3 '' "${rc}"
}

function test_not_on_google_cloud() {
    #arrange
    LIB_FUNC_IS_CLOUD_GOOGLE() { return 1; }

    #act
    check_5524_nfs_mount_rwsize_gcp
    local rc=$?

    #assert
    assert_check_processed "${rc}" 'not on Google Cloud'
    assert_exit_code 3 '' "${rc}"
}

function test_nfs_ok() {
    #arrange
    nfs_mounts=()
    nfs_mounts+=('0.0.0.0:/vol /SID/mnt00001 nfs4 rw,noatime,vers=4.1,rsize=262144,wsize=262144,hard,proto=tcp')
    nfs_mounts+=('0.0.0.0:/vol /SID/mnt00001 nfs rw,noatime,vers=4.1,rsize=262144,wsize=262144,hard,proto=tcp')
    nfs_mounts+=('0.0.0.0:/vol /SID/mnt00001 nfs rw,noatime,vers=3,rsize=262144,wsize=262144,hard,proto=tcp')

    #act
    check_5524_nfs_mount_rwsize_gcp
    local rc=$?

    #assert
    assert_check_processed "${rc}" 'correct NFS mount options'
    assert_exit_code 0 '' "${rc}"
}

function test_nfs_rsize_wrong() {
    #arrange
    nfs_mounts=()
    nfs_mounts+=('0.0.0.0:/vol /SID/mnt00001 nfs4 rw,noatime,vers=4.1,rsize=1048576,wsize=262144,hard,proto=tcp')

    #act
    check_5524_nfs_mount_rwsize_gcp
    local rc=$?

    #assert
    assert_check_processed "${rc}" 'incorrect rsize'
    assert_exit_code 1 '' "${rc}"
}

function test_nfs_wsize_wrong() {
    #arrange
    nfs_mounts=()
    nfs_mounts+=('0.0.0.0:/vol /SID/mnt00001 nfs4 rw,noatime,vers=4.1,rsize=262144,wsize=1048576,hard,proto=tcp')

    #act
    check_5524_nfs_mount_rwsize_gcp
    local rc=$?

    #assert
    assert_check_processed "${rc}" 'incorrect wsize'
    assert_exit_code 1 '' "${rc}"
}

function test_nfs_wrong_all() {
    #arrange
    nfs_mounts=()
    nfs_mounts+=('0.0.0.0:/vol /SID/mnt00001 nfs4 rw,noatime,vers=4.1,rsize=64000,wsize=64000,hard,proto=tcp')
    nfs_mounts+=('0.0.0.0:/vol /SID/mnt00001 nfs rw,noatime,vers=4.1,rsize=262144,wsize=262144,hard,proto=tcp')
    nfs_mounts+=('0.0.0.0:/vol /SID/mnt00001 nfs rw,noatime,vers=3,rsize=262144,wsize=262144,hard,proto=tcp')

    #act
    check_5524_nfs_mount_rwsize_gcp
    local rc=$?

    #assert
    assert_check_processed "${rc}" 'incorrect rsize and wsize'
    assert_exit_code 1 '' "${rc}"
}

function set_up_before_script() {
    set +eE

    [[ -n "${_5524_test_loaded:-}" ]] && return 0
    _5524_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/5524_nfs_mount_rwsize_gcp.check
    source "${PROGRAM_DIR}/../../lib/check/5524_nfs_mount_rwsize_gcp.check"
}

function set_up() {
    nfs_mounts=()
    LIB_FUNC_IS_CLOUD_GOOGLE() { return 0; }
}
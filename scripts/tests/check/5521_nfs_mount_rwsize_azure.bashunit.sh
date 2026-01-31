#!/usr/bin/env bash
#------------------------------------------------------------------
# bashunit migration: 5521_nfs_mount_rwsize_azure_test.sh
# Tests for NFS mount rsize/wsize check on Azure
#------------------------------------------------------------------
set -u

if [[ -z "${PROGRAM_DIR:-}" ]]; then
    PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
    [[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
fi

# Guard to avoid reloading
[[ -n "${_5521_nfs_mount_azure_test_loaded:-}" ]] && return 0
_5521_nfs_mount_azure_test_loaded=true

#mock PREREQUISITE functions
LIB_FUNC_IS_CLOUD_MICROSOFT() { return 0 ; }
LIB_FUNC_STRINGCONTAIN() { [[ -z "${1##*"$2"*}" ]] && [[ -z "$2" || -n "$1" ]]; }

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
    check_5521_nfs_mount_rwsize_azure
    local rc=$?

    #assert
    if [[ "$rc" != '3' ]]; then
        bashunit::fail "Expected CheckSkipped RC=3 but got RC=$rc"
    fi
}

function test_nfs_ok() {
    #arrange
    nfs_mounts=()
    nfs_mounts+=('0.0.0.0:/vol /SID/mnt00001 nfs4 rw,noatime,vers=4.1,rsize=262144,wsize=262144,hard,proto=tcp')
    nfs_mounts+=('0.0.0.0:/vol /SID/mnt00001 nfs rw,noatime,vers=4.1,rsize=262144,wsize=262144,hard,proto=tcp')
    nfs_mounts+=('0.0.0.0:/vol /SID/mnt00001 nfs rw,noatime,vers=3,rsize=262144,wsize=262144,hard,proto=tcp')

    #act
    check_5521_nfs_mount_rwsize_azure
    local rc=$?

    #assert
    if [[ "$rc" != '0' ]]; then
        bashunit::fail "Expected CheckOk RC=0 but got RC=$rc"
    fi
}

function test_nfs_rsize_wrong() {
    #arrange
    nfs_mounts=()
    nfs_mounts+=('0.0.0.0:/vol /SID/mnt00001 nfs4 rw,noatime,vers=4.1,rsize=1048576,wsize=262144,hard,proto=tcp')

    #act
    check_5521_nfs_mount_rwsize_azure
    local rc=$?

    #assert
    if [[ "$rc" != '1' ]]; then
        bashunit::fail "Expected CheckWarn RC=1 but got RC=$rc"
    fi
}

function test_nfs_wsize_wrong() {
    #arrange
    nfs_mounts=()
    nfs_mounts+=('0.0.0.0:/vol /SID/mnt00001 nfs4 rw,noatime,vers=4.1,rsize=262144,wsize=1048576,hard,proto=tcp')

    #act
    check_5521_nfs_mount_rwsize_azure
    local rc=$?

    #assert
    if [[ "$rc" != '1' ]]; then
        bashunit::fail "Expected CheckWarn RC=1 but got RC=$rc"
    fi
}

function test_nfs_wrong_all() {
    #arrange
    nfs_mounts=()
    nfs_mounts+=('0.0.0.0:/vol /SID/mnt00001 nfs4 rw,noatime,vers=4.1,rsize=64000,wsize=64000,hard,proto=tcp')
    nfs_mounts+=('0.0.0.0:/vol /SID/mnt00001 nfs rw,noatime,vers=4.1,rsize=1048576,wsize=1048576,hard,proto=tcp')
    nfs_mounts+=('0.0.0.0:/vol /SID/mnt00001 nfs rw,noatime,vers=3,rsize=1048576,wsize=1048576,hard,proto=tcp')

    #act
    check_5521_nfs_mount_rwsize_azure
    local rc=$?

    #assert
    if [[ "$rc" != '1' ]]; then
        bashunit::fail "Expected CheckWarn RC=1 but got RC=$rc"
    fi
}

function set_up_before_script() {
    set +eE

    [[ -n "${HANA_HELPER_PROGVERSION:-}" ]] && return 0

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/5521_nfs_mount_rwsize_azure.check
    source "${PROGRAM_DIR}/../../lib/check/5521_nfs_mount_rwsize_azure.check"
}

function set_up() {
    nfs_mounts=()
}

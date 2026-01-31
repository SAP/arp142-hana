#!/usr/bin/env bash
#------------------------------------------------------------------
# bashunit migration: 5530_nfs_mount_nconnect_test.sh
# Tests for NFS mount nconnect parameter check
#------------------------------------------------------------------
set -u

if [[ -z "${PROGRAM_DIR:-}" ]]; then
    PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
    [[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
fi

# Guard to avoid reloading
[[ -n "${_5530_nfs_mount_nconnect_test_loaded:-}" ]] && return 0
_5530_nfs_mount_nconnect_test_loaded=true

#mock PREREQUISITE functions
LIB_FUNC_STRINGCONTAIN() { [[ -z "${1##*"$2"*}" ]] && [[ -z "$2" || -n "$1" ]]; }

LIB_FUNC_IS_SLES() { return 0 ; }
LIB_FUNC_IS_RHEL() { return 1 ; }
LIB_FUNC_IS_CLOUD_AMAZON() { return 1 ; }

OS_VERSION='15.5'
nfs_mounts=()

grep() {
    case "$*" in
        *'/proc/mounts' )
            printf -- '%s\n' "${nfs_mounts[@]}" | command grep "$1" "$2" ;;
        *)
            command grep "$@" ;;
    esac
}

function test_nfs_not_mounted() {
    #arrange
    nfs_mounts=()
    nfs_mounts+=('/mnt/cpsapnfsstoracc01 cifs nofail,vers=3.0,credentials=/etc/smbcredentials/cpsapnfsstoracc01.cred,dir_mode=0777')

    #act
    check_5530_nfs_mount_nconnect
    local rc=$?

    #assert
    if [[ "$rc" != '3' ]]; then
        bashunit::fail "Expected CheckSkipped RC=3 but got RC=$rc"
    fi
}

function test_nfs_ok() {
    #arrange
    nfs_mounts=()
    nfs_mounts+=('0.0.0.0:/vol /hana/data nfs4 rw,noatime,vers=4.1,nconnect=4,hard,proto=tcp')
    nfs_mounts+=('0.0.0.0:/vol /hana/data2 nfs4 rw,noatime,vers=4.1,nconnect=8,hard,proto=tcp')
    nfs_mounts+=('0.0.0.0:/vol /hana/log nfs4 rw,noatime,vers=4.1,nconnect=2,hard,proto=tcp')
    nfs_mounts+=('0.0.0.0:/vol /hana/shared nfs rw,noatime,vers=3,nconnect=2,hard,proto=tcp')
    nfs_mounts+=('0.0.0.0:/vol /usr/sap nfs rw,noatime,vers=3,nconnect=2,hard,proto=tcp')

    #act
    check_5530_nfs_mount_nconnect
    local rc=$?

    #assert
    if [[ "$rc" != '0' ]]; then
        bashunit::fail "Expected CheckOk RC=0 but got RC=$rc"
    fi
}

function test_nfs_nconnect_hanalog_wrong() {
    #arrange
    nfs_mounts=()
    nfs_mounts+=('0.0.0.0:/vol /hana/log nfs4 rw,noatime,vers=4.1,nconnect=4,hard,proto=tcp')

    #act
    check_5530_nfs_mount_nconnect
    local rc=$?

    #assert
    if [[ "$rc" != '1' ]]; then
        bashunit::fail "Expected CheckWarn RC=1 but got RC=$rc"
    fi
}

function test_nfs_nconnect_hanadata_wrong() {
    #arrange
    nfs_mounts=()
    nfs_mounts+=('0.0.0.0:/vol /hana/data nfs4 rw,noatime,vers=4.1,nconnect=2,hard,proto=tcp')

    #act
    check_5530_nfs_mount_nconnect
    local rc=$?

    #assert
    if [[ "$rc" != '1' ]]; then
        bashunit::fail "Expected CheckWarn RC=1 but got RC=$rc"
    fi
}

function test_nfs_wrong_all() {
    #arrange
    nfs_mounts=()
    nfs_mounts+=('0.0.0.0:/vol /hana/data nfs4 rw,noatime,vers=4.1,nconnect=4,hard,proto=tcp')
    nfs_mounts+=('0.0.0.0:/vol /hana/log nfs rw,noatime,vers=4.1,nconnect=4,hard,proto=tcp')
    nfs_mounts+=('0.0.0.0:/vol /hana/shared nfs rw,noatime,vers=3,nconnect=4,hard,proto=tcp')

    #act
    check_5530_nfs_mount_nconnect
    local rc=$?

    #assert
    if [[ "$rc" != '1' ]]; then
        bashunit::fail "Expected CheckWarn RC=1 but got RC=$rc"
    fi
}

function test_nfs_nconnect_not_supported() {
    #arrange
    OS_VERSION='12.4'

    nfs_mounts=()
    nfs_mounts+=('0.0.0.0:/vol /hana/data nfs4 rw,noatime,vers=4.1,nconnect=4,hard,proto=tcp')
    nfs_mounts+=('0.0.0.0:/vol /hana/log nfs rw,noatime,vers=4.1,hard,proto=tcp')

    #act
    check_5530_nfs_mount_nconnect
    local rc=$?

    #assert
    if [[ "$rc" != '2' ]]; then
        bashunit::fail "Expected CheckError RC=2 but got RC=$rc"
    fi
}

function set_up_before_script() {
    set +eE

    [[ -n "${HANA_HELPER_PROGVERSION:-}" ]] && return 0

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/5530_nfs_mount_nconnect.check
    source "${PROGRAM_DIR}/../../lib/check/5530_nfs_mount_nconnect.check"
}

function set_up() {
    OS_VERSION='15.5'
    nfs_mounts=()
}

#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
readonly PROGRAM_DIR

#mock PREREQUISITE functions
LIB_FUNC_IS_CLOUD_MICROSOFT() { return 0 ; }
LIB_FUNC_STRINGCONTAIN() { [[ -z "${1##*$2*}" ]] && [[ -z "$2" || -n "$1" ]]; }

grep() {

     case "$*" in
        '-qsE \snfs'*)  #[[ ${#nfs_mounts[@]} -ge 1 ]] && return 0 ;;
                        printf -- '%s\n' "${nfs_mounts[@]}" | command grep "$1" "$2" ;;

        '-sE \snfs'*)   #fake $(grep -sE nfs /proc/mounts)
                        #printf "%s\n" "${nfs_mounts[@]:-}" ;;
                        printf -- '%s\n' "${nfs_mounts[@]}" | command grep "$1" "$2" ;;

        *)              command grep "$*" ;; # shunit2 also requires grep
    esac

}

nfs_mounts=()

test_nfs_not_mounted() {

    #arrange
    nfs_mounts=()
    nfs_mounts+=('//cpsapnfsstoracc01/cgadmin /mnt/cpsapnfsstoracc01 cifs nofail,vers=3.0,credentials=/etc/smbcredentials/cpsapnfsstoracc01.cred,dir_mode=0777')

    #act
    check_5521_nfs_mount_rwsize_azure

    #assert
    assertEquals "CheckSkipped? RC" '3' "$?"
}

test_nfs_ok() {

    #arrange
    nfs_mounts=()
    nfs_mounts+=('0.0.0.0:/vol /SID/mnt00001 nfs4 rw,noatime,vers=4.1,rsize=262144,wsize=262144,hard,proto=tcp')
    nfs_mounts+=('0.0.0.0:/vol /SID/mnt00001 nfs rw,noatime,vers=4.1,rsize=262144,wsize=262144,hard,proto=tcp')
    nfs_mounts+=('0.0.0.0:/vol /SID/mnt00001 nfs rw,noatime,vers=3,rsize=262144,wsize=262144,hard,proto=tcp')

    #act
    check_5521_nfs_mount_rwsize_azure

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_nfs_rsize_wrong() {

    #arrange
    nfs_mounts=()
    nfs_mounts+=('0.0.0.0:/vol /SID/mnt00001 nfs4 rw,noatime,vers=4.1,rsize=1048576,wsize=262144,hard,proto=tcp')

    #act
    check_5521_nfs_mount_rwsize_azure

    #assert
    assertEquals "CheckWarn? RC" '1' "$?"
}

test_nfs_wsize_wrong() {

    #arrange
    nfs_mounts=()
    nfs_mounts+=('0.0.0.0:/vol /SID/mnt00001 nfs4 rw,noatime,vers=4.1,rsize=262144,wsize=1048576,hard,proto=tcp')

    #act
    check_5521_nfs_mount_rwsize_azure

    #assert
    assertEquals "CheckWarn? RC" '1' "$?"
}

test_nfs_wrong_all() {

    #arrange
    nfs_mounts=()
    nfs_mounts+=('0.0.0.0:/vol /SID/mnt00001 nfs4 rw,noatime,vers=4.1,rsize=64000,wsize=64000,hard,proto=tcp')
    nfs_mounts+=('0.0.0.0:/vol /SID/mnt00001 nfs rw,noatime,vers=4.1,rsize=1048576,wsize=1048576,hard,proto=tcp')
    nfs_mounts+=('0.0.0.0:/vol /SID/mnt00001 nfs rw,noatime,vers=3,rsize=1048576,wsize=1048576,hard,proto=tcp')

    #act
    check_5521_nfs_mount_rwsize_azure

    #assert
    assertEquals "CheckWarn? RC" '1' "$?"
}

oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/5521_nfs_mount_rwsize_azure.check
    source "${PROGRAM_DIR}/../../lib/check/5521_nfs_mount_rwsize_azure.check"

}

# oneTimeTearDown
# setUp
# tearDown

#Import Libraries
# - order is important - sourcing shunit triggers testing
# - that's also the reason, why it could not be done during oneTimeSetup

#Load and run shUnit2
#shellcheck source=../shunit2
source "${PROGRAM_DIR}/../shunit2"

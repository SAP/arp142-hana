#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
readonly PROGRAM_DIR

#mock PREREQUISITE functions
LIB_FUNC_STRINGCONTAIN() { [[ -z "${1##*"$2"*}" ]] && [[ -z "$2" || -n "$1" ]]; }

LIB_FUNC_IS_SLES() { return 0 ; }
LIB_FUNC_IS_RHEL() { return 1 ; }
LIB_FUNC_IS_CLOUD_AMAZON() { return 1 ; }

grep() {

    case "$*" in
        *'/proc/mounts' )   #fake $(grep -sE nfs /proc/mounts)
                        printf -- '%s\n' "${nfs_mounts[@]}" | command grep "$1" "$2" ;;

        *)              command grep "$@" ;; # shunit2 also requires grep
    esac

}

nfs_mounts=()

test_nfs_not_mounted() {

    #arrange
    nfs_mounts=()
    nfs_mounts+=('/mnt/cpsapnfsstoracc01 cifs nofail,vers=3.0,credentials=/etc/smbcredentials/cpsapnfsstoracc01.cred,dir_mode=0777')

    #act
    check_5530_nfs_mount_nconnect

    #assert
    assertEquals "CheckSkipped? RC" '3' "$?"
}

test_nfs_ok() {

    #arrange
    nfs_mounts=()
    nfs_mounts+=('0.0.0.0:/vol /hana/data nfs4 rw,noatime,vers=4.1,nconnect=4,hard,proto=tcp')
    nfs_mounts+=('0.0.0.0:/vol /hana/data2 nfs4 rw,noatime,vers=4.1,nconnect=8,hard,proto=tcp')
    nfs_mounts+=('0.0.0.0:/vol /hana/log nfs4 rw,noatime,vers=4.1,nconnect=2,hard,proto=tcp')
    nfs_mounts+=('0.0.0.0:/vol /hana/shared nfs rw,noatime,vers=3,nconnect=2,hard,proto=tcp')
    nfs_mounts+=('0.0.0.0:/vol /usr/sap nfs rw,noatime,vers=3,nconnect=2,hard,proto=tcp')

    #act
    check_5530_nfs_mount_nconnect

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_nfs_nconnect_hanalog_wrong() {

    #arrange
    nfs_mounts=()
    nfs_mounts+=('0.0.0.0:/vol /hana/log nfs4 rw,noatime,vers=4.1,nconnect=4,hard,proto=tcp')

    #act
    check_5530_nfs_mount_nconnect

    #assert
    assertEquals "CheckWarn? RC" '1' "$?"
}

test_nfs_nconnect_hanadata_wrong() {

    #arrange
    nfs_mounts=()
    nfs_mounts+=('0.0.0.0:/vol /hana/data nfs4 rw,noatime,vers=4.1,nconnect=2,hard,proto=tcp')

    #act
    check_5530_nfs_mount_nconnect

    #assert
    assertEquals "CheckWarn? RC" '1' "$?"
}

test_nfs_wrong_all() {

    #arrange
    nfs_mounts=()
    nfs_mounts+=('0.0.0.0:/vol /hana/data nfs4 rw,noatime,vers=4.1,nconnect=4,hard,proto=tcp')
    nfs_mounts+=('0.0.0.0:/vol /hana/log nfs rw,noatime,vers=4.1,nconnect=4,hard,proto=tcp')
    nfs_mounts+=('0.0.0.0:/vol /hana/shared nfs rw,noatime,vers=3,nconnect=4,hard,proto=tcp')

    #act
    check_5530_nfs_mount_nconnect

    #assert
    assertEquals "CheckWarn? RC" '1' "$?"
}

test_nfs_nconnect_not_supported() {

    #arrange
    OS_VERSION='12.4'

    nfs_mounts=()
    nfs_mounts+=('0.0.0.0:/vol /hana/data nfs4 rw,noatime,vers=4.1,nconnect=4,hard,proto=tcp')
    nfs_mounts+=('0.0.0.0:/vol /hana/log nfs rw,noatime,vers=4.1,hard,proto=tcp')

    #act
    check_5530_nfs_mount_nconnect

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/5530_nfs_mount_nconnect.check
    source "${PROGRAM_DIR}/../../lib/check/5530_nfs_mount_nconnect.check"

}

# oneTimeTearDown
setUp() {

    OS_VERSION='15.5'

}
# tearDown

#Import Libraries
# - order is important - sourcing shunit triggers testing
# - that's also the reason, why it could not be done during oneTimeSetup

#Load and run shUnit2
#shellcheck source=../shunit2
source "${PROGRAM_DIR}/../shunit2"

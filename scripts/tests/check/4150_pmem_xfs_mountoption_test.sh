#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
readonly PROGRAM_DIR

#mock PREREQUISITE functions
LIB_FUNC_STRINGCONTAIN() { [[ -z "${1##*"$2"*}" ]] && [[ -z "$2" || -n "$1" ]]; }

grep() {

     case "$*" in
        '-qs ^/dev/pmem'*)  [[ ${#pmem_xfs_mounts[@]} -ge 1 ]] && return 0 ;;

       '-s ^/dev/pmem'*)    #fake $(grep -s '^/dev/pmem.*xfs' /proc/mounts)
                            printf "%s\n" "${pmem_xfs_mounts[@]:-}" ;;

        *)                  command grep "$@" ;; # shunit2 requires grep
    esac

}

pmem_xfs_mounts=()

test_pmem_xfs_not_mounted() {

    #arrange
    pmem_xfs_mounts=()

    #act
    check_4150_pmem_xfs_mountoption_dax

    #assert
    assertEquals "CheckSkipped? RC" '3' "$?"
}


test_pmem_xfs_ok_dax_always() {

    #arrange
    pmem_xfs_mounts=()
    pmem_xfs_mounts+=('/dev/pmem0 /hana/pmem/XXX/pmem0 xfs rw,relatime,attr2,dax=always,inode64,noquota 0 0')

    #act
    check_4150_pmem_xfs_mountoption_dax

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_pmem_xfs_warn_dax_legacy() {

    #arrange
    pmem_xfs_mounts=()
    pmem_xfs_mounts+=('/dev/pmem0 /hana/pmem/XXX/pmem0 xfs rw,relatime,attr2,dax=always,inode64,noquota 0 0')
    pmem_xfs_mounts+=('/dev/pmem1 /hana/pmem/XXX/pmem1 xfs rw,relatime,attr2,dax,inode64,noquota 0 0')

    #act
    check_4150_pmem_xfs_mountoption_dax

    #assert
    assertEquals "CheckWarn? RC" '1' "$?"
}

test_pmem_xfs_wrong_no_dax() {

    #arrange
    pmem_xfs_mounts=()
    pmem_xfs_mounts+=('/dev/pmem3 /hana/pmem/YYY/pmem3 xfs rw,relatime,attr2,inode64,noquota 0 0')

    #act
    check_4150_pmem_xfs_mountoption_dax

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_pmem_xfs_wrong_dax_inode() {

    #arrange
    pmem_xfs_mounts=()
    pmem_xfs_mounts+=('/dev/pmem4 /hana/pmem/YYY/pmem4 xfs rw,relatime,attr2,dax=inode,inode64,noquota 0 0')

    #act
    check_4150_pmem_xfs_mountoption_dax

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_pmem_xfs_wrong_dax_never() {

    #arrange
    pmem_xfs_mounts=()
    pmem_xfs_mounts+=('/dev/pmem5 /hana/pmem/YYY/pmem5 xfs rw,relatime,attr2,dax=never,inode64,noquota 0 0')

    #act
    check_4150_pmem_xfs_mountoption_dax

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_pmem_xfs_wrong_dax_all() {

    #arrange
    pmem_xfs_mounts=()
    pmem_xfs_mounts+=('/dev/pmem3 /hana/pmem/YYY/pmem3 xfs rw,relatime,attr2,inode64,noquota 0 0')
    pmem_xfs_mounts+=('/dev/pmem4 /hana/pmem/YYY/pmem4 xfs rw,relatime,attr2,dax=inode,inode64,noquota 0 0')
    pmem_xfs_mounts+=('/dev/pmem5 /hana/pmem/YYY/pmem5 xfs rw,relatime,attr2,dax=never,inode64,noquota 0 0')

    #act
    check_4150_pmem_xfs_mountoption_dax

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/4150_pmem_xfs_mountoption_dax.check
    source "${PROGRAM_DIR}/../../lib/check/4150_pmem_xfs_mountoption_dax.check"

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

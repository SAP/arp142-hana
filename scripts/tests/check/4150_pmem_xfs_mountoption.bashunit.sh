#!/usr/bin/env bash
#------------------------------------------------------------------
# bashunit migration notes:
# 1. PROGRAM_DIR not readonly - bashunit runs all tests in same session
# 2. Guard check skips if already loaded to avoid readonly variable conflicts
#------------------------------------------------------------------
set -u  # treat unset variables as an error

if [[ -z "${PROGRAM_DIR:-}" ]]; then
    PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
    [[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
fi

# Mock variables
pmem_xfs_mounts=()

# Mock functions
LIB_FUNC_STRINGCONTAIN() { [[ -z "${1##*"$2"*}" ]] && [[ -z "$2" || -n "$1" ]]; }

grep() {

    case "$*" in
        '-qs ^/dev/pmem'*)  [[ ${#pmem_xfs_mounts[@]} -ge 1 ]] && return 0 ;;

        '-s ^/dev/pmem'*)   #fake $(grep -s '^/dev/pmem.*xfs' /proc/mounts)
                            printf "%s\n" "${pmem_xfs_mounts[@]:-}" ;;

        *)                  command grep "$@" ;; # bashunit requires grep
    esac

}


function test_pmem_xfs_not_mounted() {

    #arrange
    pmem_xfs_mounts=()

    #act
    check_4150_pmem_xfs_mountoption_dax

    #assert
    if [[ $? -ne 3 ]]; then
        bashunit::fail "Expected RC=3 (skipped) for pmem xfs not mounted"
    fi
}

function test_pmem_xfs_ok_dax_always() {

    #arrange
    pmem_xfs_mounts=()
    pmem_xfs_mounts+=('/dev/pmem0 /hana/pmem/XXX/pmem0 xfs rw,relatime,attr2,dax=always,inode64,noquota 0 0')

    #act
    check_4150_pmem_xfs_mountoption_dax

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for dax=always"
    fi
}

function test_pmem_xfs_warn_dax_legacy() {

    #arrange
    pmem_xfs_mounts=()
    pmem_xfs_mounts+=('/dev/pmem0 /hana/pmem/XXX/pmem0 xfs rw,relatime,attr2,dax=always,inode64,noquota 0 0')
    pmem_xfs_mounts+=('/dev/pmem1 /hana/pmem/XXX/pmem1 xfs rw,relatime,attr2,dax,inode64,noquota 0 0')

    #act
    check_4150_pmem_xfs_mountoption_dax

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for legacy dax"
    fi
}

function test_pmem_xfs_wrong_no_dax() {

    #arrange
    pmem_xfs_mounts=()
    pmem_xfs_mounts+=('/dev/pmem3 /hana/pmem/YYY/pmem3 xfs rw,relatime,attr2,inode64,noquota 0 0')

    #act
    check_4150_pmem_xfs_mountoption_dax

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for no dax"
    fi
}

function test_pmem_xfs_wrong_dax_inode() {

    #arrange
    pmem_xfs_mounts=()
    pmem_xfs_mounts+=('/dev/pmem4 /hana/pmem/YYY/pmem4 xfs rw,relatime,attr2,dax=inode,inode64,noquota 0 0')

    #act
    check_4150_pmem_xfs_mountoption_dax

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for dax=inode"
    fi
}

function test_pmem_xfs_wrong_dax_never() {

    #arrange
    pmem_xfs_mounts=()
    pmem_xfs_mounts+=('/dev/pmem5 /hana/pmem/YYY/pmem5 xfs rw,relatime,attr2,dax=never,inode64,noquota 0 0')

    #act
    check_4150_pmem_xfs_mountoption_dax

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for dax=never"
    fi
}

function test_pmem_xfs_wrong_dax_all() {

    #arrange
    pmem_xfs_mounts=()
    pmem_xfs_mounts+=('/dev/pmem3 /hana/pmem/YYY/pmem3 xfs rw,relatime,attr2,inode64,noquota 0 0')
    pmem_xfs_mounts+=('/dev/pmem4 /hana/pmem/YYY/pmem4 xfs rw,relatime,attr2,dax=inode,inode64,noquota 0 0')
    pmem_xfs_mounts+=('/dev/pmem5 /hana/pmem/YYY/pmem5 xfs rw,relatime,attr2,dax=never,inode64,noquota 0 0')

    #act
    check_4150_pmem_xfs_mountoption_dax

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for all wrong dax settings"
    fi
}


function set_up_before_script() {

    # Disable errexit - bashunit enables it but sourced files may return non-zero
    set +eE

    # Skip if already loaded (bashunit runs all tests in same session)
    [[ -n "${_4150_test_loaded:-}" ]] && return 0
    _4150_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/4150_pmem_xfs_mountoption_dax.check
    source "${PROGRAM_DIR}/../../lib/check/4150_pmem_xfs_mountoption_dax.check"

}

function set_up() {

    # Reset mock variables
    pmem_xfs_mounts=()

}

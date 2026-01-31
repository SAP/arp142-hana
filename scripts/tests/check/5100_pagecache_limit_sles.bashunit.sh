#!/usr/bin/env bash
#------------------------------------------------------------------
# bashunit migration: 5100_pagecache_limit_sles_test.sh
# Tests for SLES pagecache limit check
#------------------------------------------------------------------
set -u

if [[ -z "${PROGRAM_DIR:-}" ]]; then
    PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
    [[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
fi

# Guard to avoid reloading
[[ -n "${_5100_pagecache_limit_test_loaded:-}" ]] && return 0
_5100_pagecache_limit_test_loaded=true

#mock PREREQUISITE functions
LIB_FUNC_IS_SLES() { return 0 ; }
LIB_FUNC_IS_SLES4SAP() {
    # shellcheck disable=SC2086
    return $sles4sap_rc ;
}

declare -i sles4sap_rc=1
declare LIB_PLATF_RAM_MiB_AVAILABLE=0

function test_pgc_limit_not_configurable() {
    #arrange
    path_to_pgcache_limit_mb='tmp123456$'

    #act
    check_5100_pagecache_limit_sles
    local rc=$?

    #assert
    if [[ "$rc" != '3' ]]; then
        bashunit::fail "Expected CheckSkip RC=3 but got RC=$rc"
    fi
}

function test_pgc_limit_ok_zero() {
    #arrange
    path_to_pgcache_limit_mb="${PROGRAM_DIR}/mock_pagecache_limit_mb_5100"
    echo 0 > "${path_to_pgcache_limit_mb}"
    LIB_PLATF_RAM_MiB_AVAILABLE=262144

    #act
    check_5100_pagecache_limit_sles
    local rc=$?

    #assert
    if [[ "$rc" != '0' ]]; then
        bashunit::fail "Expected CheckOk RC=0 but got RC=$rc"
    fi
}

function test_pgc_limit_sles4sap_ok_256G() {
    #arrange
    sles4sap_rc=0
    path_to_pgcache_limit_mb="${PROGRAM_DIR}/mock_pagecache_limit_mb_5100"
    echo 4096 > "${path_to_pgcache_limit_mb}"
    LIB_PLATF_RAM_MiB_AVAILABLE=262144

    #act
    check_5100_pagecache_limit_sles
    local rc=$?

    #assert
    if [[ "$rc" != '1' ]]; then
        bashunit::fail "Expected CheckWarning RC=1 but got RC=$rc"
    fi
}

function test_pgc_limit_sles4sap_ok_512G() {
    #arrange
    sles4sap_rc=0
    path_to_pgcache_limit_mb="${PROGRAM_DIR}/mock_pagecache_limit_mb_5100"
    echo 10486 > "${path_to_pgcache_limit_mb}"
    LIB_PLATF_RAM_MiB_AVAILABLE=524288

    #act
    check_5100_pagecache_limit_sles
    local rc=$?

    #assert
    if [[ "$rc" != '1' ]]; then
        bashunit::fail "Expected CheckWarning RC=1 but got RC=$rc"
    fi
}

function test_pgc_limit_sles4sap_wrong_256G() {
    #arrange
    sles4sap_rc=0
    path_to_pgcache_limit_mb="${PROGRAM_DIR}/mock_pagecache_limit_mb_5100"
    echo 4000 > "${path_to_pgcache_limit_mb}"
    LIB_PLATF_RAM_MiB_AVAILABLE=262144

    #act
    check_5100_pagecache_limit_sles
    local rc=$?

    #assert
    if [[ "$rc" != '2' ]]; then
        bashunit::fail "Expected CheckError RC=2 but got RC=$rc"
    fi
}

function test_pgc_limit_sles_ok_256G_but_not_supported() {
    #arrange
    sles4sap_rc=1
    path_to_pgcache_limit_mb="${PROGRAM_DIR}/mock_pagecache_limit_mb_5100"
    echo 4096 > "${path_to_pgcache_limit_mb}"
    LIB_PLATF_RAM_MiB_AVAILABLE=262144

    #act
    check_5100_pagecache_limit_sles
    local rc=$?

    #assert
    if [[ "$rc" != '2' ]]; then
        bashunit::fail "Expected CheckError RC=2 but got RC=$rc"
    fi
}

function test_pgc_limit_sles_ok_512G_but_not_supported() {
    #arrange
    sles4sap_rc=1
    path_to_pgcache_limit_mb="${PROGRAM_DIR}/mock_pagecache_limit_mb_5100"
    echo 10486 > "${path_to_pgcache_limit_mb}"
    LIB_PLATF_RAM_MiB_AVAILABLE=524288

    #act
    check_5100_pagecache_limit_sles
    local rc=$?

    #assert
    if [[ "$rc" != '2' ]]; then
        bashunit::fail "Expected CheckError RC=2 but got RC=$rc"
    fi
}

function test_pgc_limit_sles_wrong_256G_also_not_supported() {
    #arrange
    sles4sap_rc=1
    path_to_pgcache_limit_mb="${PROGRAM_DIR}/mock_pagecache_limit_mb_5100"
    echo 4000 > "${path_to_pgcache_limit_mb}"
    LIB_PLATF_RAM_MiB_AVAILABLE=262144

    #act
    check_5100_pagecache_limit_sles
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

    #shellcheck source=../../lib/check/5100_pagecache_limit_sles.check
    source "${PROGRAM_DIR}/../../lib/check/5100_pagecache_limit_sles.check"
}

function set_up() {
    sles4sap_rc=1
    LIB_PLATF_RAM_MiB_AVAILABLE=0
    echo 0 > "${PROGRAM_DIR}/mock_pagecache_limit_mb_5100"
}

function tear_down_after_script() {
    rm -f "${PROGRAM_DIR}/mock_pagecache_limit_mb_5100"
}

#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
readonly PROGRAM_DIR

#fake PREREQUISITE functions
LIB_FUNC_IS_SLES() { return 0 ; }
LIB_FUNC_IS_SLES4SAP() {
    # shellcheck disable=SC2086
    return $sles4sap_rc ;
}

declare -i sles4sap_rc

test_pgc-limit_not_configurable() {

    #arrange
    path_to_pgcache_limit_mb='tmp123456$'

    #act
    check_5100_pagecache_limit_sles

    #assert
    assertEquals "CheckSkip? RC" '3' "$?"
}

test_pgc-limit_ok_zero() {

    #arrange
    path_to_pgcache_limit_mb="${PROGRAM_DIR}/mock_pagecache_limit_mb"
    echo 0 > "${path_to_pgcache_limit_mb}"
    LIB_PLATF_RAM_MiB_AVAILABLE=262144

    #act
    check_5100_pagecache_limit_sles

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_pgc-limit_sles4sap_ok_256G() {

    #arrange
    sles4sap_rc=0
    path_to_pgcache_limit_mb="${PROGRAM_DIR}/mock_pagecache_limit_mb"
    echo 4096 > "${path_to_pgcache_limit_mb}"
    LIB_PLATF_RAM_MiB_AVAILABLE=262144

    #act
    check_5100_pagecache_limit_sles

    #assert
    assertEquals "CheckWarning? RC" '1' "$?"
}

test_pgc-limit_sles4sap_ok_512G() {

    #arrange
    sles4sap_rc=0
    path_to_pgcache_limit_mb="${PROGRAM_DIR}/mock_pagecache_limit_mb"
    echo 10486 > "${path_to_pgcache_limit_mb}"
    LIB_PLATF_RAM_MiB_AVAILABLE=524288

    #act
    check_5100_pagecache_limit_sles

    #assert
    assertEquals "CheckWarning? RC" '1' "$?"
}

test_pgc-limit_sles4sap_wrong_256G() {

    #arrange
    sles4sap_rc=0
    path_to_pgcache_limit_mb="${PROGRAM_DIR}/mock_pagecache_limit_mb"
    echo 4000 > "${path_to_pgcache_limit_mb}"
    LIB_PLATF_RAM_MiB_AVAILABLE=262144

    #act
    check_5100_pagecache_limit_sles

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_pgc-limit_sles_ok_256G_but_not_supported() {

    #arrange
    sles4sap_rc=1
    path_to_pgcache_limit_mb="${PROGRAM_DIR}/mock_pagecache_limit_mb"
    echo 4096 > "${path_to_pgcache_limit_mb}"
    LIB_PLATF_RAM_MiB_AVAILABLE=262144

    #act
    check_5100_pagecache_limit_sles

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_pgc-limit_sles_ok_512G_but_not_supported() {

    #arrange
    sles4sap_rc=1
    path_to_pgcache_limit_mb="${PROGRAM_DIR}/mock_pagecache_limit_mb"
    echo 10486 > "${path_to_pgcache_limit_mb}"
    LIB_PLATF_RAM_MiB_AVAILABLE=524288

    #act
    check_5100_pagecache_limit_sles

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_pgc-limit_sles_wrong_256G_also_not_supported() {

    #arrange
    sles4sap_rc=1
    path_to_pgcache_limit_mb="${PROGRAM_DIR}/mock_pagecache_limit_mb"
    echo 4000 > "${path_to_pgcache_limit_mb}"
    LIB_PLATF_RAM_MiB_AVAILABLE=262144

    #act
    check_5100_pagecache_limit_sles

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}


oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/5100_pagecache_limit_sles.check
    source "${PROGRAM_DIR}/../../lib/check/5100_pagecache_limit_sles.check"

    export avoidDoubleTearDownExecution=true

}

oneTimeTearDown() {

    if ${avoidDoubleTearDownExecution:-false}; then

        rm -f "${PROGRAM_DIR}/mock_pagecache_limit_mb"

        unset -v avoidDoubleTearDownExecution
    fi
}

setUp() {

    sles4sap_rc=
    LIB_PLATF_RAM_MiB_AVAILABLE=
    echo 0 > "${PROGRAM_DIR}/mock_pagecache_limit_mb"

}

#tearDown

#Import Libraries
# - order is important - sourcing shunit triggers testing
# - that's also the reason, why it could not be done during oneTimeSetup

#Load and run shUnit2
#shellcheck source=../shunit2
source "${PROGRAM_DIR}/../shunit2"

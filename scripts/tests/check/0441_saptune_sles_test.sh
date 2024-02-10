#!/usr/bin/env bash
set -u  # treat unset variables as an error

PROGRAM_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
readonly PROGRAM_DIR

#fake PREREQUISITE functions
LIB_FUNC_IS_SLES() { return 0 ; }
LIB_FUNC_NORMALIZE_RPM() { : ; }

LIB_FUNC_COMPARE_VERSIONS() {
    # shellcheck disable=SC2086
    return $compare_version_rc ;
}

rpm() {
    return "${rpm_rc}"
}

systemctl() {
    return "${isused_rc}"
}

grep() {
    case "$*" in
        '-qs saptune'*)     return "${isused_rc}" ;;

        *)                  command grep "$@" ;; # shunit2 requires grep
    esac
}

OS_VERSION='15.4'
LIB_FUNC_NORMALIZE_RPM_RETURN=''
declare -i compare_version_rc
declare -i rpm_rc
declare -i isused_rc

test_saptune_not_installed() {

    #arrange
    rpm_rc=1

    #act
    check_0441_saptune_sles

    #assert
    assertEquals "CheckSkipped? RC" '3' "$?"
}

test_saptune_ok() {

    #arrange
    rpm_rc=0
    compare_version_rc=1

    #act
    check_0441_saptune_sles

    #assert
    assertEquals "CheckOk? RC" '0' "$?"
}

test_saptuneV3_old_but_not_used() {

    #arrange
    rpm_rc=0
    compare_version_rc=2
    LIB_FUNC_NORMALIZE_RPM_RETURN='99.'
    isused_rc=1

    #act
    check_0441_saptune_sles

    #assert
    assertEquals "CheckWarning? RC" '1' "$?"
}

test_saptuneV_3old_and_used() {

    #arrange
    rpm_rc=0
    compare_version_rc=2
    LIB_FUNC_NORMALIZE_RPM_RETURN='99.'
    isused_rc=0

    #act
    check_0441_saptune_sles

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}

test_saptuneV2_old_but_not_used() {

    #arrange
    rpm_rc=0
    compare_version_rc=2
    LIB_FUNC_NORMALIZE_RPM_RETURN='2.'
    isused_rc=1

    #act
    check_0441_saptune_sles

    #assert
    assertEquals "CheckWarning? RC" '1' "$?"
}

test_saptuneV2_old_and_used() {

    #arrange
    rpm_rc=0
    compare_version_rc=2
    LIB_FUNC_NORMALIZE_RPM_RETURN='2.'

    #act
    check_0441_saptune_sles

    #assert
    assertEquals "CheckError? RC" '2' "$?"
}



oneTimeSetUp() {

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/0441_saptune_sles.check
    source "${PROGRAM_DIR}/../../lib/check/0441_saptune_sles.check"

}

# oneTimeTearDown

setUp() {

    #reset before each test
    rpm_rc=
    compare_version_rc=
    isused_rc=

}

# tearDown

#Import Libraries
# - order is important - sourcing shunit triggers testing
# - that's also the reason, why it could not be done during oneTimeSetup

#Load and run shUnit2
#shellcheck source=../shunit2
source "${PROGRAM_DIR}/../shunit2"

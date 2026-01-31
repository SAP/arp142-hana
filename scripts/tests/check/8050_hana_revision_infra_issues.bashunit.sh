#!/usr/bin/env bash
#------------------------------------------------------------------
# bashunit migration: 8050_hana_revision_infra_issues_test.sh
# Tests for HANA revision infrastructure issues check
#------------------------------------------------------------------
set -u

if [[ -z "${PROGRAM_DIR:-}" ]]; then
    PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
    [[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
fi

# Guard to avoid reloading
[[ -n "${_8050_hana_revision_test_loaded:-}" ]] && return 0
_8050_hana_revision_test_loaded=true

#mock PREREQUISITE functions
LIB_FUNC_IS_INTEL() { return 0 ; }

function LIB_FUNC_COMPARE_VERSIONS {

    logTrace "<${BASH_SOURCE[0]}:${FUNCNAME[*]}>"

    local -i _retval=0
    local version1
    local version2
    version1="$1"
    version2="$2"

    version1=${version1//\-/\.}
    version2=${version2//\-/\.}

    if [[ "${version1}" == "${version2}" ]]; then
        _retval=0
    else
        local IFS=.
        local -a ver1
        local -a ver2
        read -r -a ver1 <<< "${version1}"
        read -r -a ver2 <<< "${version2}"

        local -i i
        for ((i=0; i<${#ver2[@]}; i++)); do
            [[ -z ${ver1[i]:-} ]] && ver1[i]=0
        done

        for ((i=0; i<${#ver1[@]}; i++)); do
            [[ -z ${ver2[i]:-} ]] && ver2[i]=0

            if ((10#${ver1[i]} > 10#${ver2[i]})); then
                _retval=1
                break
            fi
            if ((10#${ver1[i]} < 10#${ver2[i]})); then
                _retval=2
                break
            fi
        done
    fi

    return ${_retval}
}

# get a value from the associative array
function GET_HANA_ARRAY_KV {

    local array_name="$1"
    local key="$2"

    if __assoc_array_key_exists "${array_name}" "${key}" ; then
        # shellcheck disable=SC1087
        eval "echo \${$array_name[\"$key\"]}"
    else
        echo 'n/a'
    fi
}

__assoc_array_key_exists() { return 0 ; }

declare -ag HANA_SIDS=()

function test_hana_not_found() {
    #arrange
    HANA_SIDS=()

    #act
    check_8050_hana_revision_infra_issues
    local rc=$?

    #assert
    if [[ "$rc" != '3' ]]; then
        bashunit::fail "Expected CheckSkipped RC=3 but got RC=$rc"
    fi
}

function test_hana_release_not_affected() {
    #arrange
    HANA_SIDS=()
    HANA_SIDS+=('HA1')

    declare -gA HANA_HA1
    # shellcheck disable=SC2154,SC2034
    HANA_HA1[release]='2.00.060.00'

    #act
    check_8050_hana_revision_infra_issues
    local rc=$?

    #assert
    if [[ "$rc" != '0' ]]; then
        bashunit::fail "Expected CheckOk RC=0 but got RC=$rc"
    fi
}

function test_hana_release_affected1() {
    #arrange
    HANA_SIDS=()
    HANA_SIDS+=('HA1')

    declare -gA HANA_HA1
    # shellcheck disable=SC2154,SC2034
    HANA_HA1[release]='2.00.059.06'

    #act
    check_8050_hana_revision_infra_issues
    local rc=$?

    #assert
    if [[ "$rc" != '1' ]]; then
        bashunit::fail "Expected CheckWarn RC=1 but got RC=$rc"
    fi
}

function test_hana_releases_affected2() {
    #arrange
    HANA_SIDS=()
    HANA_SIDS+=('HA1')
    HANA_SIDS+=('HA2')

    declare -gA HANA_HA1
    declare -gA HANA_HA2

    # shellcheck disable=SC2154,SC2034
    HANA_HA1[release]='2.00.059.06'
    # shellcheck disable=SC2154,SC2034
    HANA_HA2[release]='2.00.064.00'

    #act
    check_8050_hana_revision_infra_issues
    local rc=$?

    #assert
    if [[ "$rc" != '1' ]]; then
        bashunit::fail "Expected CheckWarn RC=1 but got RC=$rc"
    fi
}

function test_hana_releases_affected3() {
    #arrange
    HANA_SIDS=()
    HANA_SIDS+=('HA1')
    HANA_SIDS+=('HA2')
    HANA_SIDS+=('HA3')

    declare -gA HANA_HA1
    declare -gA HANA_HA2
    declare -gA HANA_HA3

    # shellcheck disable=SC2154,SC2034
    HANA_HA1[release]='2.00.059.06'
    # shellcheck disable=SC2154,SC2034
    HANA_HA2[release]='2.00.067.03'
    # shellcheck disable=SC2154,SC2034
    HANA_HA3[release]='2.00.079.00'

    #act
    check_8050_hana_revision_infra_issues
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

    #shellcheck source=../../lib/check/8050_hana_revision_infra_issues.check
    source "${PROGRAM_DIR}/../../lib/check/8050_hana_revision_infra_issues.check"
}

function set_up() {
    HANA_SIDS=()
}

#!/usr/bin/env bash
set -u

if [[ -z "${PROGRAM_DIR:-}" ]]; then
    PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
    [[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
fi

# shellcheck disable=SC2034
HANA_SIDS=()
# shellcheck disable=SC2034
OS_VERSION=''
HANA_RELEASE=''

LIB_FUNC_IS_RHEL() { return 0 ; }
LIB_FUNC_STRINGCONTAIN() { [[ "$1" == *"$2"* ]] ; }
GET_HANA_ARRAY_KV() { printf '%s' "$HANA_RELEASE" ; }
LIB_FUNC_COMPARE_VERSIONS() {
    [[ "$1" == "$2" ]] && return 0
    return 2
}

assert_check_processed() {
    local rc=$1
    local context="${2:-}"
    assert_not_equals 99 "${rc}" "Check must be processed${context:+ in }${context}"
}

function test_rhel102_sps7_minimum_supported() {
    # shellcheck disable=SC2034
    OS_VERSION='10.2'
    # shellcheck disable=SC2034
    HANA_SIDS=('HDB')
    HANA_RELEASE='2.00.079.11'

    local rc=0
    check_0007_os_hana_release_rhel || rc=$?
    assert_check_processed "${rc}" 'RHEL 10.2 HANA SPS 07 minimum'
    assert_exit_code 0 'RHEL 10.2 should support HANA 2.00.079.11' "${rc}"
}

function test_rhel102_sps8_minimum_supported() {
    # shellcheck disable=SC2034
    OS_VERSION='10.2'
    # shellcheck disable=SC2034
    HANA_SIDS=('HDB')
    HANA_RELEASE='2.00.089.05'

    local rc=0
    check_0007_os_hana_release_rhel || rc=$?
    assert_check_processed "${rc}" 'RHEL 10.2 HANA SPS 08 minimum'
    assert_exit_code 0 'RHEL 10.2 should support HANA 2.00.089.05' "${rc}"
}

function set_up_before_script() {
    set +eE
    [[ -n "${_0007_test_loaded:-}" ]] && return 0
    _0007_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/0007_os_hana_release_rhel.check
    source "${PROGRAM_DIR}/../../lib/check/0007_os_hana_release_rhel.check"
}
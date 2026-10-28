#!/usr/bin/env bash
set -u

if [[ -z "${PROGRAM_DIR:-}" ]]; then
    PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
    [[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
fi

# shellcheck disable=SC2034
OS_VERSION=''
# shellcheck disable=SC2034
LIB_PLATF_VENDOR='Generic platform'

LIB_FUNC_IS_INTEL() { return 0 ; }
LIB_FUNC_IS_RHEL() { return 0 ; }

assert_check_processed() {
    local rc=$1
    local context="${2:-}"
    assert_not_equals 99 "${rc}" "Check must be processed${context:+ in }${context}"
}

function test_rhel102_supported_on_generic_intel_platform() {
    # shellcheck disable=SC2034
    OS_VERSION='10.2'
    # shellcheck disable=SC2034
    LIB_PLATF_VENDOR='Generic platform'

    local rc=0
    check_0003_os_hana_support_rhel_intel || rc=$?
    assert_check_processed "${rc}" 'RHEL 10.2 on Intel'
    assert_exit_code 0 'RHEL 10.2 should be supported on a generic Intel platform' "${rc}"
}

function set_up_before_script() {
    set +eE
    [[ -n "${_0003_test_loaded:-}" ]] && return 0
    _0003_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/0003_os_hana_support_rhel_intel.check
    source "${PROGRAM_DIR}/../../lib/check/0003_os_hana_support_rhel_intel.check"
}
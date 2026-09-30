#!/usr/bin/env bash
set -u

if [[ -z "${PROGRAM_DIR:-}" ]]; then
    PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
    [[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
fi

timer_enabled_rc=1

systemctl() {
    case "$*" in
        'is-enabled fstrim.timer --quiet') return "${timer_enabled_rc}" ;;
        *)                                 return 1 ;;
    esac
}

assert_check_processed() {
    local rc=$1
    local context="${2:-}"
    assert_not_equals 99 "${rc}" "Check must be processed${context:+ in }${context}"
}

function test_disabled_timer_is_ok() {

    #arrange
    timer_enabled_rc=1

    #act
    check_5600_fstrim_service
    local rc=$?

    #assert
    assert_check_processed ${rc} 'disabled timer'
    assert_exit_code 0 'Expected RC=0 (ok) for disabled fstrim.timer' "${rc}"
    assert_true true
}

function test_enabled_timer_is_error() {

    #arrange
    timer_enabled_rc=0

    #act
    check_5600_fstrim_service
    local rc=$?

    #assert
    assert_check_processed ${rc} 'enabled timer'
    assert_exit_code 2 'Expected RC=2 (error) for enabled fstrim.timer' "${rc}"
    assert_true true
}

function set_up_before_script() {
    set +eE

    [[ -n "${_5600_test_loaded:-}" ]] && return 0
    _5600_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/5600_fstrim_service.check
    source "${PROGRAM_DIR}/../../lib/check/5600_fstrim_service.check"
}

function set_up() {
    timer_enabled_rc=1
}
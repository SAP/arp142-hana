#!/usr/bin/env bash
#------------------------------------------------------------------
# Unit tests for check_3100_ip_port_sysctl
#------------------------------------------------------------------
set -u

if [[ -z "${PROGRAM_DIR:-}" ]]; then
    PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
    [[ "${PROGRAM_DIR}" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
fi

# Mock variables
TEST_3100_SCENARIO='none'
TEST_3100_GREP_COUNT_FILE=''

assert_check_processed() {
    local rc=$1
    local context="${2:-}"
    if [[ ${rc} -eq 99 ]]; then
        bashunit::fail "RC=99 (unprocessed) - check logic did not reach a conclusion${context:+ in }${context}"
    fi
}

define_3100_grep_mock() {
    # Simulate grep output for deterministic tests without reading /etc/sysctl*
    grep() {
        local all_args
        local is_recursive=1
        all_args="${*}"

        for arg in "$@"; do
            if [[ "${arg}" == '-r' || "${arg}" == '-rE' || "${arg}" == '-rEh' || "${arg}" == '-Erh' ]]; then
                is_recursive=0
                break
            fi
        done

        if [[ ${is_recursive} -ne 0 ]]; then
            command grep "$@"
            return $?
        fi

        printf '1\n' >> "${TEST_3100_GREP_COUNT_FILE}"

        if [[ "${all_args}" == *'ip_local_port_range|ip_local_reserved_ports'* ]]; then
            case "${TEST_3100_SCENARIO}" in
                none)
                    return 1
                    ;;
                range_only)
                    printf '%s\n' 'net.ipv4.ip_local_port_range = 9000 65500'
                    return 0
                    ;;
                reserved_only)
                    printf '%s\n' 'net.ipv4.ip_local_reserved_ports = 40000,40001'
                    return 0
                    ;;
                both)
                    printf '%s\n' 'net.ipv4.ip_local_port_range = 9000 65500'
                    printf '%s\n' 'net.ipv4.ip_local_reserved_ports = 40000,40001'
                    return 0
                    ;;
                whitespace_both)
                    printf '%s\n' '   net.ipv4.ip_local_port_range    = 9000 65500'
                    printf '%s\n' $'\tnet.ipv4.ip_local_reserved_ports\t=\t40000,40001'
                    return 0
                    ;;
                *)
                    return 1
                    ;;
            esac
        fi

        if [[ "${all_args}" == *'ip_local_port_range'* ]]; then
            case "${TEST_3100_SCENARIO}" in
                range_only|both|whitespace_both)
                    printf '%s\n' 'net.ipv4.ip_local_port_range = 9000 65500'
                    return 0
                    ;;
                *)
                    return 1
                    ;;
            esac
        fi

        if [[ "${all_args}" == *'ip_local_reserved_ports'* ]]; then
            case "${TEST_3100_SCENARIO}" in
                reserved_only|both|whitespace_both)
                    printf '%s\n' 'net.ipv4.ip_local_reserved_ports = 40000,40001'
                    return 0
                    ;;
                *)
                    return 1
                    ;;
            esac
        fi

        return 1
    }
}

run_and_assert_3100() {
    local scenario="${1}"
    local expected_rc="${2}"

    TEST_3100_SCENARIO="${scenario}"
    : > "${TEST_3100_GREP_COUNT_FILE}"

    check_3100_ip_port_sysctl
    local rc=$?

    assert_check_processed "${rc}" "${scenario}"
    if [[ ${rc} -ne ${expected_rc} ]]; then
        bashunit::fail "Expected RC=${expected_rc} for ${scenario}, got RC=${rc}"
    fi

    local grep_calls
    grep_calls=$(wc -l < "${TEST_3100_GREP_COUNT_FILE}")
    if [[ ${grep_calls} -ne 1 ]]; then
        bashunit::fail "Expected a single grep call for ${scenario}, got ${grep_calls}"
    fi

    assert_true true
}

function test_none_configured_ok() {
    run_and_assert_3100 'none' 0
}

function test_port_range_only_warning() {
    run_and_assert_3100 'range_only' 1
}

function test_reserved_ports_only_warning() {
    run_and_assert_3100 'reserved_only' 1
}

function test_both_configured_warning() {
    run_and_assert_3100 'both' 1
}

function test_both_configured_with_whitespace_warning() {
    run_and_assert_3100 'whitespace_both' 1
}

function set_up_before_script() {
    set +eE

    [[ -n "${_3100_test_loaded:-}" ]] && return 0
    _3100_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/3100_ip_port_sysctl.check
    source "${PROGRAM_DIR}/../../lib/check/3100_ip_port_sysctl.check"
}

function set_up() {
    TEST_3100_SCENARIO='none'
    TEST_3100_GREP_COUNT_FILE="${PROGRAM_DIR}/mock_3100_grep_count"
    : > "${TEST_3100_GREP_COUNT_FILE}"
    define_3100_grep_mock
}

function tear_down() {
    unset -f grep
    rm -f "${PROGRAM_DIR}/mock_3100_grep_count"
}
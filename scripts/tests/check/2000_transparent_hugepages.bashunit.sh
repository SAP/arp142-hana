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

# Mock directory for test files
_mock_dir=''

# Mock variables
OS_VERSION=''
_is_sles=1
_is_rhel=1

# Mock functions
LIB_FUNC_IS_SLES() { return "${_is_sles}"; }
LIB_FUNC_IS_RHEL() { return "${_is_rhel}"; }
LIB_FUNC_TRIM_LEFT() { echo "${1## }"; }

# Mock grep for /proc/vmstat
grep() {
    case "$*" in
        *'nr_anon_transparent_hugepages'*)
            echo 'nr_anon_transparent_hugepages 0'
            ;;
        *)
            command grep "$@"
            ;;
    esac
}

function test_thp_not_configurable() {

    #arrange - no mock files created

    #act
    check_2000_transparent_hugepages

    #assert
    if [[ $? -ne 3 ]]; then
        bashunit::fail "Expected RC=3 (skipped) when THP not configurable"
    fi
}

function test_thp_sles15sp5_madvise_ok() {

    #arrange
    _is_sles=0
    _is_rhel=1
    OS_VERSION='15.5'
    mkdir -p "${_mock_dir}/sys/kernel/mm/transparent_hugepage"
    echo 'always [madvise] never' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/enabled"

    #act
    check_2000_transparent_hugepages

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for SLES 15.5 with madvise"
    fi
}

function test_thp_sles15sp5_never_warning() {

    #arrange
    _is_sles=0
    _is_rhel=1
    OS_VERSION='15.5'
    mkdir -p "${_mock_dir}/sys/kernel/mm/transparent_hugepage"
    echo 'always madvise [never]' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/enabled"

    #act
    check_2000_transparent_hugepages

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for SLES 15.5 with never"
    fi
}

function test_thp_sles15sp5_always_error() {

    #arrange
    _is_sles=0
    _is_rhel=1
    OS_VERSION='15.5'
    mkdir -p "${_mock_dir}/sys/kernel/mm/transparent_hugepage"
    echo '[always] madvise never' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/enabled"

    #act
    check_2000_transparent_hugepages

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for SLES 15.5 with always"
    fi
}

function test_thp_sles12_never_ok() {

    #arrange
    _is_sles=0
    _is_rhel=1
    OS_VERSION='12.5'
    mkdir -p "${_mock_dir}/sys/kernel/mm/transparent_hugepage"
    echo 'always madvise [never]' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/enabled"

    #act
    check_2000_transparent_hugepages

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for SLES 12.5 with never"
    fi
}

function test_thp_sles12_madvise_error() {

    #arrange
    _is_sles=0
    _is_rhel=1
    OS_VERSION='12.5'
    mkdir -p "${_mock_dir}/sys/kernel/mm/transparent_hugepage"
    echo 'always [madvise] never' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/enabled"

    #act
    check_2000_transparent_hugepages

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for SLES 12.5 with madvise"
    fi
}

function test_thp_sles15sp4_never_ok() {

    #arrange
    _is_sles=0
    _is_rhel=1
    OS_VERSION='15.4'
    mkdir -p "${_mock_dir}/sys/kernel/mm/transparent_hugepage"
    echo 'always madvise [never]' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/enabled"

    #act
    check_2000_transparent_hugepages

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for SLES 15.4 with never"
    fi
}

function test_thp_rhel92_madvise_ok() {

    #arrange
    _is_sles=1
    _is_rhel=0
    OS_VERSION='9.2'
    mkdir -p "${_mock_dir}/sys/kernel/mm/transparent_hugepage"
    echo 'always [madvise] never' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/enabled"

    #act
    check_2000_transparent_hugepages

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for RHEL 9.2 with madvise"
    fi
}

function test_thp_rhel92_never_warning() {

    #arrange
    _is_sles=1
    _is_rhel=0
    OS_VERSION='9.2'
    mkdir -p "${_mock_dir}/sys/kernel/mm/transparent_hugepage"
    echo 'always madvise [never]' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/enabled"

    #act
    check_2000_transparent_hugepages

    #assert
    if [[ $? -ne 1 ]]; then
        bashunit::fail "Expected RC=1 (warning) for RHEL 9.2 with never"
    fi
}

function test_thp_rhel8_never_ok() {

    #arrange
    _is_sles=1
    _is_rhel=0
    OS_VERSION='8.8'
    mkdir -p "${_mock_dir}/sys/kernel/mm/transparent_hugepage"
    echo 'always madvise [never]' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/enabled"

    #act
    check_2000_transparent_hugepages

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for RHEL 8.8 with never"
    fi
}

function test_thp_rhel8_madvise_error() {

    #arrange
    _is_sles=1
    _is_rhel=0
    OS_VERSION='8.8'
    mkdir -p "${_mock_dir}/sys/kernel/mm/transparent_hugepage"
    echo 'always [madvise] never' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/enabled"

    #act
    check_2000_transparent_hugepages

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) for RHEL 8.8 with madvise"
    fi
}

function test_thp_rhel91_never_ok() {

    #arrange
    _is_sles=1
    _is_rhel=0
    OS_VERSION='9.1'
    mkdir -p "${_mock_dir}/sys/kernel/mm/transparent_hugepage"
    echo 'always madvise [never]' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/enabled"

    #act
    check_2000_transparent_hugepages

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) for RHEL 9.1 with never"
    fi
}

function set_up_before_script() {

    # Disable errexit - bashunit enables it but sourced files may return non-zero
    set +eE

    # Skip if already loaded (bashunit runs all tests in same session)
    [[ -n "${_2000_test_loaded:-}" ]] && return 0
    _2000_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/2000_transparent_hugepages.check
    source "${PROGRAM_DIR}/../../lib/check/2000_transparent_hugepages.check"

}

function set_up() {

    # Reset mock variables
    OS_VERSION=''
    _is_sles=1
    _is_rhel=1

    # Create a temporary mock directory for each test
    _mock_dir=$(mktemp -d)

    # Override the check function to use mock paths using bash parameter expansion
    local _func_def
    local _orig_path='/sys/kernel/mm/transparent_hugepage'
    local _mock_path="${_mock_dir}/sys/kernel/mm/transparent_hugepage"
    _func_def=$(declare -f check_2000_transparent_hugepages)
    _func_def=${_func_def//$_orig_path/$_mock_path}
    eval "$_func_def"

}

function tear_down() {

    # Clean up mock directory after each test
    if [[ -n "${_mock_dir}" ]] && [[ -d "${_mock_dir}" ]]; then
        rm -rf "${_mock_dir}"
    fi
    _mock_dir=''

    # Restore original check function
    source "${PROGRAM_DIR}/../../lib/check/2000_transparent_hugepages.check"

}

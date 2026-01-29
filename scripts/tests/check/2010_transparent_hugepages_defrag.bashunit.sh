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

function test_thp_defrag_not_configurable() {

    #arrange - no mock files created

    #act
    check_2010_transparent_hugepages_defrag

    #assert
    if [[ $? -ne 3 ]]; then
        bashunit::fail "Expected RC=3 (skipped) when THP defrag not configurable"
    fi
}

function test_thp_disabled_skip_defrag_check() {

    #arrange - THP is disabled (set to never)
    mkdir -p "${_mock_dir}/sys/kernel/mm/transparent_hugepage/khugepaged"
    echo 'always madvise [never]' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/enabled"
    echo '[always] defer defer+madvise madvise never' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/defrag"
    echo '1' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/khugepaged/defrag"

    #act
    check_2010_transparent_hugepages_defrag

    #assert
    if [[ $? -ne 3 ]]; then
        bashunit::fail "Expected RC=3 (skipped) when THP is disabled"
    fi
}

function test_thp_defrag_all_ok_never_and_0() {

    #arrange
    mkdir -p "${_mock_dir}/sys/kernel/mm/transparent_hugepage/khugepaged"
    echo 'always [madvise] never' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/enabled"
    echo 'always defer defer+madvise madvise [never]' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/defrag"
    echo '0' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/khugepaged/defrag"

    #act
    check_2010_transparent_hugepages_defrag

    #assert
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) when all parameters are correct"
    fi
}

function test_thp_defrag_first_wrong_always() {

    #arrange
    mkdir -p "${_mock_dir}/sys/kernel/mm/transparent_hugepage/khugepaged"
    echo 'always [madvise] never' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/enabled"
    echo '[always] defer defer+madvise madvise never' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/defrag"
    echo '0' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/khugepaged/defrag"

    #act
    check_2010_transparent_hugepages_defrag

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) when THP defrag is not never"
    fi
}

function test_thp_defrag_first_wrong_madvise() {

    #arrange
    mkdir -p "${_mock_dir}/sys/kernel/mm/transparent_hugepage/khugepaged"
    echo 'always [madvise] never' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/enabled"
    echo 'always defer defer+madvise [madvise] never' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/defrag"
    echo '0' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/khugepaged/defrag"

    #act
    check_2010_transparent_hugepages_defrag

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) when THP defrag is madvise"
    fi
}

function test_thp_defrag_second_wrong_1() {

    #arrange
    mkdir -p "${_mock_dir}/sys/kernel/mm/transparent_hugepage/khugepaged"
    echo 'always [madvise] never' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/enabled"
    echo 'always defer defer+madvise madvise [never]' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/defrag"
    echo '1' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/khugepaged/defrag"

    #act
    check_2010_transparent_hugepages_defrag

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) when khugepaged defrag is 1"
    fi
}

function test_thp_defrag_both_wrong() {

    #arrange
    mkdir -p "${_mock_dir}/sys/kernel/mm/transparent_hugepage/khugepaged"
    echo 'always [madvise] never' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/enabled"
    echo '[always] defer defer+madvise madvise never' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/defrag"
    echo '1' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/khugepaged/defrag"

    #act
    check_2010_transparent_hugepages_defrag

    #assert
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) when both parameters are wrong"
    fi
}

function test_thp_defrag_khugepaged_not_available() {

    #arrange - only create first file, not khugepaged
    mkdir -p "${_mock_dir}/sys/kernel/mm/transparent_hugepage"
    echo 'always [madvise] never' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/enabled"
    echo 'always defer defer+madvise madvise [never]' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/defrag"
    # khugepaged/defrag file does not exist

    #act
    check_2010_transparent_hugepages_defrag

    #assert
    # Should still return OK since first parameter is correct and second is just skipped with info
    if [[ $? -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) when khugepaged not available but THP defrag is correct"
    fi
}

function set_up_before_script() {

    # Disable errexit - bashunit enables it but sourced files may return non-zero
    set +eE

    # Skip if already loaded (bashunit runs all tests in same session)
    [[ -n "${_2010_test_loaded:-}" ]] && return 0
    _2010_test_loaded=true

    #shellcheck source=../saphana-logger-stubs
    source "${PROGRAM_DIR}/../saphana-logger-stubs"

    #shellcheck source=../../lib/check/2010_transparent_hugepages_defrag.check
    source "${PROGRAM_DIR}/../../lib/check/2010_transparent_hugepages_defrag.check"

}

function set_up() {

    # Create a temporary mock directory for each test
    _mock_dir=$(mktemp -d)

    # Override the check function to use mock paths using bash parameter expansion
    local _func_def
    local _orig_path='/sys/kernel/mm/transparent_hugepage'
    local _mock_path="${_mock_dir}/sys/kernel/mm/transparent_hugepage"
    _func_def=$(declare -f check_2010_transparent_hugepages_defrag)
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
    source "${PROGRAM_DIR}/../../lib/check/2010_transparent_hugepages_defrag.check"

}


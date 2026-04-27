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

# Mock variables for kernel version check
OS_VERSION=''
OS_LEVEL=''

# Mock functions - defaults: not SLES, no kernel normalization/comparison
LIB_FUNC_IS_SLES() { return 1; }
LIB_FUNC_NORMALIZE_KERNELn() { :; }
LIB_FUNC_COMPARE_VERSIONS() { return 0; }

function test_thp_defrag_not_configurable() {

    #arrange - no mock files created

    #act
    check_2010_transparent_hugepages_defrag

    #assert
    if [[ $? -ne 3 ]]; then
        bashunit::fail "Expected RC=3 (skipped) when THP defrag not configurable"
    fi
    assert_true true
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
    assert_true true
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
    assert_true true
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
    assert_true true
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
    assert_true true
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
    assert_true true
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
    assert_true true
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
    assert_true true
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

    # Reset mock variables
    OS_VERSION=''
    OS_LEVEL=''

    # Default: not SLES (existing tests don't need kernel version logic)
    LIB_FUNC_IS_SLES() { return 1; }
    LIB_FUNC_NORMALIZE_KERNELn() { :; }
    LIB_FUNC_COMPARE_VERSIONS() { return 0; }

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

#------------------------------------------------------------------
# Tests for SLES fixed kernel - checks against madvise/1 defaults
#------------------------------------------------------------------

function test_sles15sp5_fixed_kernel_defaults_ok() {

    #arrange - SLES 15.5 with fixed kernel, defaults madvise/1
    LIB_FUNC_IS_SLES() { return 0; }
    OS_VERSION='15.5'
    OS_LEVEL='5.14.21-150500.55.136.1-default'
    LIB_FUNC_NORMALIZE_KERNELn() { :; }
    # 1st call: OS_VERSION 15.5 < 15.8 -> 2, 2nd call: kernel equal -> 0
    local -i _cmp_call=0
    LIB_FUNC_COMPARE_VERSIONS() { ((_cmp_call++)); [[ ${_cmp_call} -eq 1 ]] && return 2; return 0; }

    mkdir -p "${_mock_dir}/sys/kernel/mm/transparent_hugepage/khugepaged"
    echo 'always [madvise] never' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/enabled"
    echo 'always defer defer+madvise [madvise] never' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/defrag"
    echo '1' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/khugepaged/defrag"

    #act
    check_2010_transparent_hugepages_defrag
    local rc=$?

    #assert - should pass (RC=0) because fixed kernel defaults madvise/1 are correct
    if [[ ${rc} -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) when SLES 15.5 fixed kernel has defaults, got RC=${rc}"
    fi
    assert_true true
}

function test_sles15sp6_fixed_kernel_defaults_ok() {

    #arrange - SLES 15.6 with newer-than-fixed kernel, defaults madvise/1
    LIB_FUNC_IS_SLES() { return 0; }
    OS_VERSION='15.6'
    OS_LEVEL='6.4.0-150600.23.90.1-default'
    LIB_FUNC_NORMALIZE_KERNELn() { :; }
    # 1st call: OS_VERSION 15.6 < 15.8 -> 2, 2nd call: kernel higher -> 1
    local -i _cmp_call=0
    LIB_FUNC_COMPARE_VERSIONS() { ((_cmp_call++)); [[ ${_cmp_call} -eq 1 ]] && return 2; return 1; }

    mkdir -p "${_mock_dir}/sys/kernel/mm/transparent_hugepage/khugepaged"
    echo 'always [madvise] never' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/enabled"
    echo 'always defer defer+madvise [madvise] never' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/defrag"
    echo '1' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/khugepaged/defrag"

    #act
    check_2010_transparent_hugepages_defrag
    local rc=$?

    #assert - should pass because kernel is newer than fix and defaults are correct
    if [[ ${rc} -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) when SLES 15.6 kernel is newer than fix, got RC=${rc}"
    fi
    assert_true true
}

function test_sles15sp5_fixed_kernel_wrong_defrag_always() {

    #arrange - SLES 15.5 with fixed kernel, but defrag set to always instead of madvise
    LIB_FUNC_IS_SLES() { return 0; }
    OS_VERSION='15.5'
    OS_LEVEL='5.14.21-150500.55.136.1-default'
    LIB_FUNC_NORMALIZE_KERNELn() { :; }
    # 1st call: OS_VERSION 15.5 < 15.8 -> 2, 2nd call: kernel equal -> 0
    local -i _cmp_call=0
    LIB_FUNC_COMPARE_VERSIONS() { ((_cmp_call++)); [[ ${_cmp_call} -eq 1 ]] && return 2; return 0; }

    mkdir -p "${_mock_dir}/sys/kernel/mm/transparent_hugepage/khugepaged"
    echo 'always [madvise] never' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/enabled"
    echo '[always] defer defer+madvise madvise never' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/defrag"
    echo '1' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/khugepaged/defrag"

    #act
    check_2010_transparent_hugepages_defrag
    local rc=$?

    #assert - should fail because defrag is always, should be madvise on fixed kernel
    if [[ ${rc} -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) when fixed kernel has defrag=always, got RC=${rc}"
    fi
    assert_true true
}

function test_sles15sp5_fixed_kernel_wrong_defrag_never() {

    #arrange - SLES 15.5 with fixed kernel, but defrag still set to never (old recommendation)
    LIB_FUNC_IS_SLES() { return 0; }
    OS_VERSION='15.5'
    OS_LEVEL='5.14.21-150500.55.136.1-default'
    LIB_FUNC_NORMALIZE_KERNELn() { :; }
    # 1st call: OS_VERSION 15.5 < 15.8 -> 2, 2nd call: kernel equal -> 0
    local -i _cmp_call=0
    LIB_FUNC_COMPARE_VERSIONS() { ((_cmp_call++)); [[ ${_cmp_call} -eq 1 ]] && return 2; return 0; }

    mkdir -p "${_mock_dir}/sys/kernel/mm/transparent_hugepage/khugepaged"
    echo 'always [madvise] never' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/enabled"
    echo 'always defer defer+madvise madvise [never]' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/defrag"
    echo '0' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/khugepaged/defrag"

    #act
    check_2010_transparent_hugepages_defrag
    local rc=$?

    #assert - should fail because defrag=never/0 is wrong on fixed kernel (should be madvise/1)
    if [[ ${rc} -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) when fixed kernel still has old defrag=never, got RC=${rc}"
    fi
    assert_true true
}

function test_sles15sp5_old_kernel_checks_defrag() {

    #arrange - SLES 15.5 with old kernel (before fix)
    LIB_FUNC_IS_SLES() { return 0; }
    OS_VERSION='15.5'
    OS_LEVEL='5.14.21-150500.55.100.1-default'
    LIB_FUNC_NORMALIZE_KERNELn() { :; }
    # Both calls return 2: OS_VERSION < 15.8, kernel < fixed
    LIB_FUNC_COMPARE_VERSIONS() { return 2; }

    mkdir -p "${_mock_dir}/sys/kernel/mm/transparent_hugepage/khugepaged"
    echo 'always [madvise] never' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/enabled"
    echo '[always] defer defer+madvise madvise never' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/defrag"
    echo '1' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/khugepaged/defrag"

    #act
    check_2010_transparent_hugepages_defrag
    local rc=$?

    #assert - should fail (RC=2) because old kernel requires defrag=never
    if [[ ${rc} -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) when SLES 15.5 kernel is old, got RC=${rc}"
    fi
    assert_true true
}

function test_sles15sp7_fixed_kernel_defaults_ok() {

    #arrange - SLES 15.7 with exact fixed kernel, defaults madvise/1
    LIB_FUNC_IS_SLES() { return 0; }
    OS_VERSION='15.7'
    OS_LEVEL='6.4.0-150700.53.31.1-default'
    LIB_FUNC_NORMALIZE_KERNELn() { :; }
    # 1st call: OS_VERSION 15.7 < 15.8 -> 2, 2nd call: kernel equal -> 0
    local -i _cmp_call=0
    LIB_FUNC_COMPARE_VERSIONS() { ((_cmp_call++)); [[ ${_cmp_call} -eq 1 ]] && return 2; return 0; }

    mkdir -p "${_mock_dir}/sys/kernel/mm/transparent_hugepage/khugepaged"
    echo 'always [madvise] never' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/enabled"
    echo 'always defer defer+madvise [madvise] never' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/defrag"
    echo '1' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/khugepaged/defrag"

    #act
    check_2010_transparent_hugepages_defrag
    local rc=$?

    #assert
    if [[ ${rc} -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) when SLES 15.7 fixed kernel has defaults, got RC=${rc}"
    fi
    assert_true true
}

function test_sles_unknown_version_checks_defrag() {

    #arrange - SLES version not in fixed kernel list and below fixed_from
    LIB_FUNC_IS_SLES() { return 0; }
    OS_VERSION='15.4'
    OS_LEVEL='5.14.21-150400.24.100.1-default'
    LIB_FUNC_NORMALIZE_KERNELn() { :; }
    # OS_VERSION 15.4 < 15.8 -> 2, no matching version in list so no 2nd call
    LIB_FUNC_COMPARE_VERSIONS() { return 2; }

    mkdir -p "${_mock_dir}/sys/kernel/mm/transparent_hugepage/khugepaged"
    echo 'always [madvise] never' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/enabled"
    echo '[always] defer defer+madvise madvise never' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/defrag"
    echo '1' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/khugepaged/defrag"

    #act
    check_2010_transparent_hugepages_defrag
    local rc=$?

    #assert - should fail because SLES 15.4 has no fixed kernel, falls through to defrag check
    if [[ ${rc} -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) when SLES version not in fixed kernel list, got RC=${rc}"
    fi
    assert_true true
}

function test_sles15sp5_old_kernel_defrag_ok() {

    #arrange - SLES 15.5 with old kernel but defrag correctly configured
    LIB_FUNC_IS_SLES() { return 0; }
    OS_VERSION='15.5'
    OS_LEVEL='5.14.21-150500.55.100.1-default'
    LIB_FUNC_NORMALIZE_KERNELn() { :; }
    # Both calls return 2: OS_VERSION < 15.8, kernel < fixed
    LIB_FUNC_COMPARE_VERSIONS() { return 2; }

    mkdir -p "${_mock_dir}/sys/kernel/mm/transparent_hugepage/khugepaged"
    echo 'always [madvise] never' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/enabled"
    echo 'always defer defer+madvise madvise [never]' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/defrag"
    echo '0' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/khugepaged/defrag"

    #act
    check_2010_transparent_hugepages_defrag
    local rc=$?

    #assert - should pass because defrag is correctly set even on old kernel
    if [[ ${rc} -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) when defrag is correct on old SLES kernel, got RC=${rc}"
    fi
    assert_true true
}

#------------------------------------------------------------------
# Tests for future SLES versions (>= fixed_from) - always fixed
#------------------------------------------------------------------

function test_sles15sp8_always_fixed_defaults_ok() {

    #arrange - SLES 15.8 (>= fixed_from), defaults madvise/1
    LIB_FUNC_IS_SLES() { return 0; }
    OS_VERSION='15.8'
    OS_LEVEL='6.4.0-150800.10.1.1-default'
    LIB_FUNC_NORMALIZE_KERNELn() { :; }
    # OS_VERSION 15.8 == 15.8 -> 0 (equal, not less), no kernel check
    LIB_FUNC_COMPARE_VERSIONS() { return 0; }

    mkdir -p "${_mock_dir}/sys/kernel/mm/transparent_hugepage/khugepaged"
    echo 'always [madvise] never' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/enabled"
    echo 'always defer defer+madvise [madvise] never' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/defrag"
    echo '1' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/khugepaged/defrag"

    #act
    check_2010_transparent_hugepages_defrag
    local rc=$?

    #assert - should pass because SLES 15.8 always has the fix
    if [[ ${rc} -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) when SLES 15.8 has defaults, got RC=${rc}"
    fi
    assert_true true
}

function test_sles16_always_fixed_defaults_ok() {

    #arrange - SLES 16.0 (>= fixed_from), defaults madvise/1
    LIB_FUNC_IS_SLES() { return 0; }
    OS_VERSION='16.0'
    OS_LEVEL='6.6.0-160000.1.1-default'
    LIB_FUNC_NORMALIZE_KERNELn() { :; }
    # OS_VERSION 16.0 > 15.8 -> 1 (first higher, not less), no kernel check
    LIB_FUNC_COMPARE_VERSIONS() { return 1; }

    mkdir -p "${_mock_dir}/sys/kernel/mm/transparent_hugepage/khugepaged"
    echo 'always [madvise] never' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/enabled"
    echo 'always defer defer+madvise [madvise] never' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/defrag"
    echo '1' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/khugepaged/defrag"

    #act
    check_2010_transparent_hugepages_defrag
    local rc=$?

    #assert - should pass because SLES 16.0 always has the fix
    if [[ ${rc} -ne 0 ]]; then
        bashunit::fail "Expected RC=0 (ok) when SLES 16.0 has defaults, got RC=${rc}"
    fi
    assert_true true
}

function test_sles15sp8_wrong_defrag_always() {

    #arrange - SLES 15.8 (>= fixed_from) but defrag wrongly set to always
    LIB_FUNC_IS_SLES() { return 0; }
    OS_VERSION='15.8'
    OS_LEVEL='6.4.0-150800.10.1.1-default'
    LIB_FUNC_NORMALIZE_KERNELn() { :; }
    # OS_VERSION 15.8 == 15.8 -> 0
    LIB_FUNC_COMPARE_VERSIONS() { return 0; }

    mkdir -p "${_mock_dir}/sys/kernel/mm/transparent_hugepage/khugepaged"
    echo 'always [madvise] never' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/enabled"
    echo '[always] defer defer+madvise madvise never' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/defrag"
    echo '1' > "${_mock_dir}/sys/kernel/mm/transparent_hugepage/khugepaged/defrag"

    #act
    check_2010_transparent_hugepages_defrag
    local rc=$?

    #assert - should fail because defrag=always is wrong even on fixed SLES 15.8
    if [[ ${rc} -ne 2 ]]; then
        bashunit::fail "Expected RC=2 (error) when SLES 15.8 has defrag=always, got RC=${rc}"
    fi
    assert_true true
}


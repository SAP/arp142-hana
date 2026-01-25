#!/usr/bin/env bash
#------------------------------------------------------------------
# bashunit migration notes:
# 1. PROGRAM_DIR not readonly - bashunit runs all tests in same session
# 2. set +eE in setup - bashunit enables errexit which breaks library sourcing
# 3. Stub functions (LIB_FUNC_IS_SLES/RHEL) defined BEFORE guard check so
#    they're always available even when library loading is skipped
# 4. Pre-load os-validation-config and set SUPPORTED_DISTRIBUTIONS to prevent
#    LIB_FUNC_VALIDATE_OS from re-sourcing (which fails on readonly arrays)
#------------------------------------------------------------------
set -u      # treat unset variables as an error

if [[ -z "${PROGRAM_DIR:-}" ]]; then
    PROGRAM_DIR="${BASH_SOURCE[0]%/*}"
    [[ "$PROGRAM_DIR" == "${BASH_SOURCE[0]}" ]] && PROGRAM_DIR="."
fi

function test_validate_os_sles_supported() {
    # Test supported SLES versions

    OS_NAME='Linux SLES'
    OS_VERSION='15.5'
    LIB_FUNC_VALIDATE_OS
    if [[ $? -ne 0 ]]; then
        bashunit::fail "SLES 15.5 should be supported"
    fi

    OS_VERSION='15.7'
    LIB_FUNC_VALIDATE_OS
    if [[ $? -ne 0 ]]; then
        bashunit::fail "SLES 15.7 should be supported"
    fi

    OS_VERSION='12.5'
    LIB_FUNC_VALIDATE_OS
    if [[ $? -ne 0 ]]; then
        bashunit::fail "SLES 12.5 should be supported"
    fi
}

function test_validate_os_sles_eol() {
    # Test EOL SLES versions

    OS_NAME='Linux SLES'
    OS_VERSION='11.4'
    LIB_FUNC_VALIDATE_OS
    if [[ $? -ne 1 ]]; then
        bashunit::fail "SLES 11.4 should return EOL (code 1)"
    fi

    OS_VERSION='12.4'
    LIB_FUNC_VALIDATE_OS
    if [[ $? -ne 1 ]]; then
        bashunit::fail "SLES 12.4 should return EOL (code 1)"
    fi

    OS_VERSION='15.2'
    LIB_FUNC_VALIDATE_OS
    if [[ $? -ne 1 ]]; then
        bashunit::fail "SLES 15.2 should return EOL (code 1)"
    fi
}

function test_validate_os_rhel_supported() {
    # Test supported RHEL versions

    OS_NAME='Linux RHEL'
    OS_VERSION='9.2'
    LIB_FUNC_VALIDATE_OS
    if [[ $? -ne 0 ]]; then
        bashunit::fail "RHEL 9.2 should be supported"
    fi

    OS_VERSION='8.6'
    LIB_FUNC_VALIDATE_OS
    if [[ $? -ne 0 ]]; then
        bashunit::fail "RHEL 8.6 should be supported"
    fi

    OS_VERSION='7.9'
    LIB_FUNC_VALIDATE_OS
    if [[ $? -ne 0 ]]; then
        bashunit::fail "RHEL 7.9 should be supported"
    fi
}

function test_validate_os_rhel_eol() {
    # Test EOL RHEL versions

    OS_NAME='Linux RHEL'
    OS_VERSION='7.8'
    LIB_FUNC_VALIDATE_OS
    if [[ $? -ne 1 ]]; then
        bashunit::fail "RHEL 7.8 should return EOL (code 1)"
    fi

    OS_VERSION='6.10'
    LIB_FUNC_VALIDATE_OS
    if [[ $? -ne 1 ]]; then
        bashunit::fail "RHEL 6.10 should return EOL (code 1)"
    fi
}

function test_validate_os_unsupported_distribution() {
    # Test unsupported distributions
    OS_NAME='Linux OLS'
    OS_VERSION='9.6'
    LIB_FUNC_VALIDATE_OS
    if [[ $? -ne 2 ]]; then
        bashunit::fail "OLS should be unsupported (code 2)"
    fi

    OS_NAME='Linux Ubuntu'
    OS_VERSION='22.04'
    LIB_FUNC_VALIDATE_OS
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Ubuntu should be unsupported (code 2)"
    fi

    OS_NAME='Linux CentOS'
    OS_VERSION='8.0'
    LIB_FUNC_VALIDATE_OS
    if [[ $? -ne 2 ]]; then
        bashunit::fail "CentOS should be unsupported (code 2)"
    fi

    OS_NAME='Linux UNKNOWN'
    OS_VERSION='0.0'
    LIB_FUNC_VALIDATE_OS
    if [[ $? -ne 2 ]]; then
        bashunit::fail "Linux UNKNOWN should be unsupported (code 2)"
    fi
}

function test_validate_os_future_versions() {
    # Test future/unknown versions - should allow with warning

    OS_NAME='Linux SLES'
    OS_VERSION='16.0'
    LIB_FUNC_VALIDATE_OS
    if [[ $? -ne 0 ]]; then
        bashunit::fail "SLES 16.0 (future) should be allowed"
    fi

    OS_NAME='Linux RHEL'
    OS_VERSION='10.0'
    LIB_FUNC_VALIDATE_OS
    if [[ $? -ne 0 ]]; then
        bashunit::fail "RHEL 10.0 (future) should be allowed"
    fi
}

function set_up_before_script() {

    # Disable errexit - bashunit enables it but our sourced files have commands
    # that may return non-zero as part of normal operation
    set +eE

    # Set up stub functions for distribution detection ALWAYS
    # (even if libraries are already loaded, we need our custom stubs)
    LIB_FUNC_IS_SLES() {
        [[ "${OS_NAME}" == 'Linux SLES' ]] && return 0
        return 1
    }

    LIB_FUNC_IS_RHEL() {
        [[ "${OS_NAME}" == 'Linux RHEL' ]] && return 0
        return 1
    }

    # Prevent LIB_FUNC_VALIDATE_OS from re-sourcing os-validation-config
    # by setting SUPPORTED_DISTRIBUTIONS if not already set
    if [[ -z "${SUPPORTED_DISTRIBUTIONS:-}" ]]; then
        # Set this guard variable to prevent os-validation-config from being sourced
        # We need to source it ourselves first (only if not already done)
        if [[ -z "${SLES_EOL_VERSIONS:-}" ]]; then
            #shellcheck source=../bin/os-validation-config
            source "${PROGRAM_DIR}/../bin/os-validation-config"
        fi
        # Set SUPPORTED_DISTRIBUTIONS to prevent re-sourcing
        SUPPORTED_DISTRIBUTIONS=('Linux SLES' 'Linux RHEL')
    fi

    # Skip library loading if already loaded (bashunit runs all tests in same session)
    [[ -n "${HANA_HELPER_PROGVERSION:-}" ]] && return 0

    # prevent loading of original libraries
    # shellcheck disable=SC2034
    LIB_LINUX_RELEASE='dont load'
    # shellcheck disable=SC2034
    LIB_PLATF_x86_64_RELEASE='dont load'
    # shellcheck disable=SC2034
    LIB_PLATF_POWER_RELEASE='dont load'

    LIB_PLATF_RAM_MIB_PHYS=1024
    LIB_PLATF_RAM_MiB_AVAILABLE=1024
    LIB_PLATF_RAM_KiB_AVAILABLE=1024

    #shellcheck source=./saphana-logger-stubs
    source "${PROGRAM_DIR}/./saphana-logger-stubs"

    #shellcheck source=../bin/saphana-helper-funcs
    source "${PROGRAM_DIR}/../bin/saphana-helper-funcs"

}

# tear_down_after_script
# set_up
# tear_down

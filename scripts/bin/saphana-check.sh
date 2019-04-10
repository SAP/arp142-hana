#!/bin/bash
umask 0027
set -u # treat unset variables as an error

#------------------------------------------------------------------
# SAP HANA OS checks
#------------------------------------------------------------------
# (C) Copyright SAP 2017-2019
# Author: DBS - CoE EMEA HANA Platform & Technical Infrastructure
#
# Script name: "saphana-check.sh"
#
# tool to check OS parameter recommendations for SAP HANA environments
# supports SLES and RHEL on Intel and SLES on Power
#
# inspired by Lenovo's saphana-support-lenovo.sh Support script
#------------------------------------------------------------------

PROGVERSION='1903.0-dev'
PROGDATE='2019-FEB-06'
#------------------------------------------------------------------


function die {
    [ $# -gt 0 ] && echo "error: $*" >&2
    exit 1
}

# Make sure only root can run our script
[[ ${UID} -ne 0 ]] && die 'This script must be run as root'

#set POSIX/C locales - date/time/regex format normalized for all platforms
LC_ALL=POSIX
export LC_ALL

PROGRAM_NAME=${0##*/}
readonly PROGRAM_NAME

PROGRAM_CMDLINE="$*"
readonly PROGRAM_CMDLINE

PROGRAM_DIR="$(cd "${BASH_SOURCE[0]%/*}" && pwd)"
readonly PROGRAM_DIR

PROGRAM_BINDIR="${PROGRAM_DIR}"
readonly PROGRAM_BINDIR

# configure shflags - define flags
#shellcheck source=./shflags
source "${PROGRAM_BINDIR}/shflags" || die 'unable to load shflags library'

DEFINE_string	'checks'	''		'<\"check1 check2 ...\">  A space-separated list of checks that will be performed.'	'c'
DEFINE_string	'checkset'	''		'<Checkset>  A textfile containing the various checks to perform.'	'C'
DEFINE_integer	'loglevel'	4		'notify/silent=0 (always), error=1, warn=2, info=3, debug=5, trace=6'	'l'
DEFINE_boolean	'verbose'	false	'enable chk_verbose mode (set loglevel=4)' 'v'
DEFINE_boolean	'debug'		false	'enable debug mode (set loglevel=5)' 'd'
DEFINE_boolean	'trace'		false	'enable trace mode (set loglevel=6)' 't'
DEFINE_boolean	'color'		false	'enable color mode'
DEFINE_boolean  'timestamp' false   'show timestamp (default for debug/trace)'
# shellcheck disable=SC2034
FLAGS_HELP="USAGE: $0 [flags]"

PROGRAM_LIBDIR="$(cd "${PROGRAM_BINDIR}/../lib" && pwd)"
readonly PROGRAM_LIBDIR

OS_NAME=''
OS_VERSION=''
OS_LEVEL=''

declare -a CHECKLIST=()
declare -a CHECKFILELIST=()

NUMBER_CHECKS=0
NUMBER_CHECKS_SKIPPED=0
NUMBER_CHECKS_INFO=0
NUMBER_CHECKS_OK=0
NUMBER_CHECKS_WARNING=0
NUMBER_CHECKS_ERROR=0
NUMBER_CHECKS_UNKNOWN=0

#============================================================
# utility stuff
#============================================================
function evaluate_cmdline_options {

    [[ ${FLAGS_loglevel:?} -lt 7 ]] && LOG_VERBOSE_LVL=${FLAGS_loglevel}

    [[ ${FLAGS_verbose:?} -eq ${FLAGS_TRUE} ]] && LOG_VERBOSE_LVL=4

    [[ ${FLAGS_debug:?} -eq ${FLAGS_TRUE} ]] && LOG_VERBOSE_LVL=5

    [[ ${FLAGS_trace:?} -eq ${FLAGS_TRUE} ]] && LOG_VERBOSE_LVL=6

    [[ ${FLAGS_color:?} -eq ${FLAGS_TRUE} ]] && LOG_COLOR_CHECK=0

    [[ ${FLAGS_timestamp:?} -eq ${FLAGS_TRUE} ]] && LOG_TIMESTAMP=0

    [[ ${LOG_VERBOSE_LVL} -ge 5 ]] && LOG_TIMESTAMP=0

    logDebug "<${BASH_SOURCE[0]}:${FUNCNAME[0]}> # LOG_VERBOSE_LVL=${LOG_VERBOSE_LVL}"
}

function update_check_counters {

    local -i _rc="$1"
    shift 1

    case "${_rc}" in
    0)
        ((NUMBER_CHECKS++))
        ((NUMBER_CHECKS_OK++))
        ;;

    1)
        ((NUMBER_CHECKS++))
        ((NUMBER_CHECKS_WARNING++))
        ;;

    2)
        ((NUMBER_CHECKS++))
        ((NUMBER_CHECKS_ERROR++))
        ;;

    3)
        ((NUMBER_CHECKS_SKIPPED++))
        ;;

    99)
        ((NUMBER_CHECKS_INFO++))
        ;;

    *)
        ((NUMBER_CHECKS_UNKNOWN++))
        ;;
    esac

}
#============================================================
# Check handling
#============================================================
function generate_checkfilelist_checks {

    local checklist="$1"
    shift 1

    local check

    for check in ${checklist}; do
        if [[ -f "${PROGRAM_LIBDIR}/check/${check}.check" ]]; then

            CHECKFILELIST+=("${PROGRAM_LIBDIR}/check/${check}.check")
        fi
    done
}

function generate_checkfilelist_checkset {

    local checksetfile="${PROGRAM_LIBDIR}/checkset/${FLAGS_checkset:?}.checkset"
    local checkset

    if [[ ! -f "${checksetfile}" ]]; then
        logError "${checksetfile} does not exist."
        exit 1
    fi

    if ! checkset=$(<"${checksetfile}"); then
        logError "Could not load checkset file ${checksetfile}"
        exit 1
    fi

    generate_checkfilelist_checks "${checkset}"
}

function generate_checklist {

    logTrace "<${BASH_SOURCE[0]}:${FUNCNAME[*]}>"

    # generate checklist
    if [[ "${FLAGS_checks:-}" != "" ]]; then

        generate_checkfilelist_checks "${FLAGS_checks}"

    elif [[ "${FLAGS_checkset}" != "" ]]; then

        generate_checkfilelist_checkset

    else
        CHECKFILELIST=("$(ls -1 "${PROGRAM_LIBDIR}"/check/*.check)")
    fi

    local checkfile
    local checkname
    local safetycheck

    for checkfile in ${CHECKFILELIST[*]:-}; do

        checkfileshort=${checkfile##*/}

        if ! safetycheck=$(LIB_FUNC_CHECK_CHECK_SECURITY "$checkfile"); then
            logWarn "Skipping check ${checkfileshort}. Reason: ${safetycheck}"
            continue
        fi

        if ! [[ -r "${checkfile}" && -w "${checkfile}" ]]; then
            logWarn "Skipping check ${checkfileshort},
                                        could not read check file ${checkfile}"
            continue
        else
            CHECKLIST+=("${checkfile}")
        fi

    done
}

function run_checklist {

    logTrace "<${BASH_SOURCE[0]}:${FUNCNAME[*]}>"

    local -i RC_CHECK
    for checkfile in ${CHECKLIST[*]:-}; do

        checkfileshort=${checkfile##*/}
        checkname="check_${checkfileshort%.check}"

        # printCheckHeader "Checking " $check

        printf '\n'

        (#run Subshell to forget sourcing

            # shellcheck source=/dev/null
            if ! source "${checkfile}"; then
                logWarn "Skipping check ${checkfileshort},
                                        could not load check file ${checkfile}"
                return 3
            else
                ${checkname}
                return $?
            fi
        )

        RC_CHECK=$?
        update_check_counters ${RC_CHECK}

        # printCheckHeader $line
    done

}

function print_counters {

    local -i check_run
    local -i check_count
    local percent_skipped=0
    local percent_info=0
    local percent_ok=0
    local percent_warning=0
    local percent_error=0

    check_run=$((NUMBER_CHECKS_INFO + NUMBER_CHECKS_OK + NUMBER_CHECKS_WARNING + NUMBER_CHECKS_ERROR))
    check_count=$((NUMBER_CHECKS_SKIPPED + check_run))

    if [[ "${check_count}" -gt 0 ]]; then
        percent_skipped=$((100 * NUMBER_CHECKS_SKIPPED / check_count))
        if [ "${check_run}" -gt 0 ]; then
            percent_info=$((100 * NUMBER_CHECKS_INFO / check_count))
            percent_ok=$((100 * NUMBER_CHECKS_OK / check_count))
            percent_warning=$((100 * NUMBER_CHECKS_WARNING / check_count))
            percent_error=$((100 * NUMBER_CHECKS_ERROR / check_count))
        fi
    fi

    local _line_formated

    printf -v _line_formated '%-7s|%6s |%8s |%5s |%8s |%6s' 'Status' 'Error' 'Warning' 'OK' 'Skipped' 'Info'
    logNotify "## ${_line_formated}"

    printf -v _line_formated '%-7s|%6s |%8s |%5s |%8s |%6s' '%' $percent_error $percent_warning $percent_ok $percent_skipped $percent_info
    logNotify "## ${_line_formated}"

    printf -v _line_formated '%-7s|%6s |%8s |%5s |%8s |%6s' '#' $NUMBER_CHECKS_ERROR $NUMBER_CHECKS_WARNING $NUMBER_CHECKS_OK $NUMBER_CHECKS_SKIPPED $NUMBER_CHECKS_INFO
    logNotify "## ${_line_formated}"

}

#============================================================
# main
#============================================================
function main {

    logTrace "<${BASH_SOURCE[0]}:${FUNCNAME[*]}>"

    local _line_formated
    local -r _line='------------------------------------------------------------------------'

    logNotify "## ${_line}"
    logNotify "## SAP HANA OS checks"
    logNotify "## Scriptversion:  ${PROGVERSION} Scriptdate: ${PROGDATE}"
    logNotify "## ${_line}"
    logNotify "## CMD:            ${PROGRAM_DIR}/${PROGRAM_NAME} ${PROGRAM_CMDLINE}"
    logNotify '##'
    logNotify "## Host:           $(hostname -f)"
    logNotify "## TimeLOC:        $(date +"%Y-%m-%d %H:%M:%S")"
    logNotify "## TimeUTC:        $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    logNotify "## ${_line}"

    printf -v _line_formated '%-17s - %-11s %-20s' "${LIB_PLATF_VENDOR:-}" 'Type:' "${LIB_PLATF_NAME:-}"
    logNotify "## Vendor:         ${_line_formated}"
    printf -v _line_formated '%-17s - %-11s %-20s' "${LIB_PLATF_ARCHITECTURE:-}" 'Byte Order:' "${LIB_PLATF_BYTEORDER:-}"
    logNotify "## Architecture:   ${_line_formated}"
    logNotify '##'

    printf -v _line_formated '%-17s - %-11s %-20s' "${LIB_PLATF_VIRT_HYPER:-none}" 'Type:' "${LIB_PLATF_VIRT_TYPE:-none}"
    logNotify "## Virtualization: ${_line_formated}"
    logNotify '##'

    logNotify "## CPU:            ${LIB_PLATF_CPU:-}"
    logNotify '##'
    printf -v _line_formated '%-17s - %-11s %-20s' "${LIB_PLATF_CPU_SOCKETS:-}" 'Cores:' "${LIB_PLATF_CPU_CORESPERSOCKET:-}"
    logNotify "## Sockets:        ${_line_formated}"
    printf -v _line_formated '%-17s - %-11s %-20s' "${LIB_PLATF_CPU_NUMANODES:-}" 'Threads:' "${LIB_PLATF_CPU_THREADSPERCORE:-}"
    logNotify "## Numa nodes:     ${_line_formated}"
    logNotify '##'

    #need awk - because of float number
    _line_formated=$(awk -v RAM_MiB="${LIB_PLATF_RAM_MIB_PHYS}" \
        'BEGIN {printf "%.0f GiB (%d MiB)", RAM_MiB/1024, RAM_MiB}')
    logNotify "## Memory:         ${_line_formated}"
    logNotify '##'

    printf -v _line_formated '%-17s - %-11s %-20s' "${OS_NAME} ${OS_VERSION}" 'Kernel:' "${OS_LEVEL}"
    logNotify "## OS:             ${_line_formated}"

    logNotify "## ${_line}"

    printf '\n'

    generate_checklist
    run_checklist

    if [[ ${#CHECKLIST[@]} -eq 0 ]] ; then
        logError "## NOTHING to EXECUTE - revise check/checkset parameter !!!"
        exit 1
    fi

    printf '\n'
    logNotify "## ${_line}"
    print_counters

    printf '\n'
    logNotify '## Exit'

    exit 0
}

#Import logger
#shellcheck source=./saphana-logger
source "${PROGRAM_BINDIR}/saphana-logger" ||
    die 'unable to load saphana-logger library'

# parse the command-line - shflags
FLAGS "$@" || exit 1
eval set -- "${FLAGS_ARGV}"
evaluate_cmdline_options

#Import remaining Libraries - logging is now active
#shellcheck source=./saphana-helper-funcs
source "${PROGRAM_BINDIR}/saphana-helper-funcs" ||
    die 'unable to load saphana-helper-funcs library'

# call main
main "$@"

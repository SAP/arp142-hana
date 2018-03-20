#!/bin/bash
umask 022
set -u 		# treat unset variables as an error

#------------------------------------------------------------------
# SAP HANA OS checks
#------------------------------------------------------------------
# (C) Copyright SAP 2017-2018
# Author: DBS - CoE EMEA HANA Platform & Technical Infrastructure
#
# Script name: "saphana-check.sh"
#
# tool to check OS parameter recommendations for SAP HANA environments
# supports SLES and RHEL on Intel and SLES on Power
#
# inspired by Lenovo's saphana-support-lenovo.sh Support script
#------------------------------------------------------------------

PROGVERSION='0.5dev'
PROGDATE='2018-MAR-07'
#------------------------------------------------------------------


function die {
    [ $# -gt 0 ] && echo "error: $*" >&2
    exit 1
}

# Make sure only root can run our script
# [[ ${UID}} -ne 0 ]] && die 'This script must be run as root'

#set POSIX/C locales - date/time/regex format normalized for all platforms
LC_ALL=POSIX
export LC_ALL

PROGRAM_NAME=${0##*/}
readonly PROGRAM_NAME

PROGRAM_CMDLINE="$*"
readonly PROGRAM_CMDLINE

PROGRAM_DIR="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
readonly PROGRAM_DIR

PROGRAM_BINDIR="${PROGRAM_DIR}"
readonly PROGRAM_BINDIR

# configure shflags - define flags
#shellcheck source=scripts/bin/shflags
source "${PROGRAM_BINDIR}/shflags" || die 'unable to load shflags library'

DEFINE_string	'checks'	''		'<\"check1 check2 ...\">  A space-separated list of checks that will be performed.'	'c'
DEFINE_string	'checkset'	''		'<Checkset>  A textfile containing the various checks to perform.'	'C'
DEFINE_integer	'loglevel'	4		'notify/silent=0 (always), error=1, warn=2, info=3, debug=5, trace=6'	'l'
DEFINE_boolean	'verbose'	false	'enable chk_verbose mode (set loglevel=4)' 'v'
DEFINE_boolean	'debug'		false	'enable debug mode (set loglevel=5)' 'd'
DEFINE_boolean	'trace'		false	'enable trace mode (set loglevel=6)' 't'
DEFINE_boolean	'color'		false	'enable color mode'
# shellcheck disable=SC2034
FLAGS_HELP="USAGE: $0 [flags]"


PROGRAM_LIBDIR="$( cd "${PROGRAM_BINDIR}/../lib" && pwd )"
readonly PROGRAM_LIBDIR

OS_NAME=''
OS_VERSION=''
OS_LEVEL=''

declare -a CHECKLIST=()
declare -a CHECKFILELIST=()


#============================================================
# utility stuff
#============================================================
function evaluate_cmdline_options {

    [[ ${FLAGS_loglevel:?} -lt 7 ]] && LOG_VERBOSE_LVL=${FLAGS_loglevel}

    [[ ${FLAGS_verbose:?} -eq ${FLAGS_TRUE} ]] && LOG_VERBOSE_LVL=4

    [[ ${FLAGS_debug:?} -eq ${FLAGS_TRUE} ]] && LOG_VERBOSE_LVL=5

    [[ ${FLAGS_trace:?} -eq ${FLAGS_TRUE} ]] && LOG_VERBOSE_LVL=6

    [[ ${FLAGS_color:?} -eq ${FLAGS_TRUE} ]] && LOG_COLOR_CHECK=0

    logDebug "<${BASH_SOURCE[0]}:${FUNCNAME[0]}> # LOG_VERBOSE_LVL=${LOG_VERBOSE_LVL}"
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

    if ! checkset=$(<"${checksetfile}") ; then
        logError "Could not load checkset file ${checksetfile}"
        exit 1
    fi

    generate_checkfilelist_checks "${checkset}"
}

function generate_checklist {

    logTrace "<${BASH_SOURCE[0]}:${FUNCNAME[*]}>"

    # generate checklist
    if [[ "${FLAGS_checks:?}" != "" || "${FLAGS_checkset:?}" != "" ]]; then

        [[ "${FLAGS_checks}" != "" ]] && generate_checkfilelist_checks "${FLAGS_checks}"

        [[ "${FLAGS_checkset}" != "" ]] && generate_checkfilelist_checkset

    else
        CHECKFILELIST=( "$(ls -1 "${PROGRAM_LIBDIR}"/check/*.check)" )
    fi

    local checkfile
    local checkname
    local safetycheck

    for checkfile in ${CHECKFILELIST[*]:-}; do

        checkname=${checkfile##*/}
        checkname="check_${checkname%.check}"

        if ! safetycheck=$(LIB_FUNC_CHECK_CHECK_SECURITY "$checkfile") ; then
            logCheckSkipped "Skipping check ${checkname}. Reason: ${safetycheck}"
            continue;
        fi

        # shellcheck source=/dev/null
        if ! source "${checkfile}" ; then
            logCheckSkipped "Skipping check ${checkname},
                                        could not load check file ${checkfile}"
        else
            CHECKLIST+=("${checkname}")
        fi
    done
}

function run_checklist {

    logTrace "<${BASH_SOURCE[0]}:${FUNCNAME[*]}>"

    #empty = unbound variable but count works "${#arr[@]}" = 0
    for check in ${CHECKLIST[*]:-}; do
        # printCheckHeader "Checking " $check
        # if ! isCheckBlacklisted $check ; then
            printf '\n'
            ${check}
            #ToDo: count_error, count_warning - removed from logger
        # else
        #     logCheckSkipped "Skipping blacklisted check $check."
        # fi
        # printCheckHeader $line
    done

}



#============================================================
# main
#============================================================
function main {

    logTrace "<${BASH_SOURCE[0]}:${FUNCNAME[*]}>"

    local -r _line='-------------------------------------------------------------------'

    logNotify "## ${_line}"
    logNotify "## SAP HANA OS checks"
    logNotify "## Scriptversion: ${PROGVERSION} Scriptdate: ${PROGDATE}"
    logNotify "## ${_line}"
    logNotify "## CMD:           ${PROGRAM_DIR}/${PROGRAM_NAME} ${PROGRAM_CMDLINE}"
    logNotify '##'
    logNotify "## Host:          $(hostname -f)"
    logNotify "## TimeLOC:       $(date +"%Y-%m-%d %H:%M:%S")"
    logNotify "## TimeUTC:       $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    logNotify "## ${_line}"
    logNotify "## Vendor:        ${LIB_PLATF_VENDOR:-} - Type: ${LIB_PLATF_NAME:-}"
    logNotify "## Architecture:  ${LIB_PLATF_ARCHITECTURE:-} - Byte Order: ${LIB_PLATF_BYTEORDER:-}"

    if LIB_FUNC_IS_BARE_METAL
    then
        logNotify '##                Running on Bare-Metal'
    else
        logNotify '##                Running Virtualized'
    fi

    if LIB_FUNC_IS_IBMPOWER
    then
        logNotify '##                Running on IBM Power'
    fi

    logNotify "## CPU:           ${LIB_PLATF_CPU:-}"
    logNotify "## Memory:        $(awk -v RAM_MiB="${LIB_PLATF_RAM_MiB_PHYS}" \
                'BEGIN {printf "%.0f GiB (%d MiB)", RAM_MiB/1024, RAM_MiB }')"
    logNotify '##'
    logNotify "## OS:            ${OS_NAME} ${OS_VERSION} - Kernel: ${OS_LEVEL}"

    printf '\n'

    generate_checklist
    run_checklist

    printf '\n'
    logNotify '## Exit'

    exit 0
}

#Import logger
#shellcheck source=scripts/bin/saphana-logger
source "${PROGRAM_BINDIR}/saphana-logger" ||
                            die 'unable to load saphana-logger library'

# parse the command-line - shflags
FLAGS "$@" || exit 1
eval set -- "${FLAGS_ARGV}"
evaluate_cmdline_options

#Import remaining Libraries - logging is now active
#shellcheck source=scripts/bin/saphana-helper-funcs
source "${PROGRAM_BINDIR}/saphana-helper-funcs" ||
                            die 'unable to load saphana-helper-funcs library'

# call main
main "$@"

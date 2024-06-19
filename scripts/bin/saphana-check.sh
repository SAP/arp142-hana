#!/usr/bin/env bash
umask 0027
set -u # treat unset variables as an error

#------------------------------------------------------------------
# SAP HANA OS checks
#------------------------------------------------------------------
# Script name: "saphana-check.sh"
#
# tool to check OS parameter recommendations for SAP HANA environments
# supports SLES and RHEL on Intel and IBM Power
#
#------------------------------------------------------------------

PROGVERSION='2101.0-dev'
PROGDATE='2020-DEC-01'
#------------------------------------------------------------------

function die {
    [ $# -gt 0 ] && echo "error: $*" >&2
    exit 1
}

[[ -z "${BASH_VERSION:-}" ]] && die 'This script requires a bash shell'
[[ ${POSIXLY_CORRECT:-} = 'y' ]] && die 'This script requires bash in non-posix mode, use <bash> not <sh>'

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

DEFINE_string   'checks'    ''      '<\"check1,check2,...\"> a comma-separated list of checks that will be performed.'  'c'
DEFINE_string   'checkset'  ''      '<Checkset> a textfile stored within lib/checkset containing the various checks to perform.'    'C'
DEFINE_boolean  'showchecks'      false   'show listing of checks to be executed'  's'
DEFINE_boolean  'showchecksets'   false   'show listing of checksets available'    'S'
DEFINE_integer  'loglevel'  4       'notify/silent=0 (always), error=1, warn=2, info=3, debug=5, trace=6'   'l'
DEFINE_boolean  'verbose'   false   'enable chk_verbose mode (set loglevel=4)' 'v'
DEFINE_boolean  'debug'     false   'enable debug mode (set loglevel=5)' 'd'
DEFINE_boolean  'trace'     false   'enable trace mode (set loglevel=6)' 't'
DEFINE_boolean  'color'     false   'enable color mode'
DEFINE_boolean  'timestamp' false   'show timestamp (default for debug/trace)'
# shellcheck disable=SC2034
IFS='' read -r -d '' FLAGS_HELP <<<"
USAGE: ${PROGRAM_NAME} [flags]

examples:

    ${PROGRAM_NAME}                         (all checks)
    ${PROGRAM_NAME} -c 0800_sap_host_agent  (single check - fully specified checkname)
    ${PROGRAM_NAME} -c 0800                 (single check - fully specified checkid)
    ${PROGRAM_NAME} -c 08*                  (multiple checks - beginning with 08)
    ${PROGRAM_NAME} -c 0*                   (multiple checks - all checks from category 0)
    ${PROGRAM_NAME} -c 0010,0020            (multiple checks - ids seperated by comma)
    ${PROGRAM_NAME} -c 0010,5*              (combination of above examples)


    ${PROGRAM_NAME} -C RHELonPoweronly      (only checks relevant for RHEL on Power )"

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

    logTrace "<${BASH_SOURCE[0]}:${FUNCNAME[*]}>"

    local check

    for check in ${checklist//,/ }; do

        [[ ${#check} -eq 4 ]] && check+='*'

        #specify full check name or only complete check number or part of it with * appended
        #${check} must not be quoted !!!
        for file in "${PROGRAM_LIBDIR}"/check/${check}.check; do

            if [[ -f "${file}" ]]; then

                CHECKFILELIST+=("${file}")

            else
                logWarn "Skipping check ${check}. Check file not found. <${file}>"
            fi

        done
    done
}

function generate_checkfilelist_checkset {

    local checkset="$1"
    shift 1

    logTrace "<${BASH_SOURCE[0]}:${FUNCNAME[*]}>"

    local checksetfile="${PROGRAM_LIBDIR}/checkset/${checkset:?}.checkset"
    local checklist

    if [[ ! -f "${checksetfile}" ]]; then
        logError "Checkset file not found.
                    ${checksetfile}"
        exit 1
    fi

    if ! checklist=$(<"${checksetfile}"); then
        logError "Could not load checkset file.
                    ${checksetfile}"
        exit 1
    fi

    generate_checkfilelist_checks "${checklist}"
}

function generate_checklist {

    logTrace "<${BASH_SOURCE[0]}:${FUNCNAME[*]}>"

    # generate checklist
    if [[ "${FLAGS_checks:-}" != "" ]]; then

        generate_checkfilelist_checks "${FLAGS_checks}"

    elif [[ "${FLAGS_checkset:-}" != "" ]]; then

        generate_checkfilelist_checkset "${FLAGS_checkset}"

    else
        CHECKFILELIST=("${PROGRAM_LIBDIR}"/check/*.check)
    fi

    local checkfile
    local checkname
    local safetycheck

    if [[ ! ${CHECKFILELIST[*]:-} ]]; then
        logTrace "<${FUNCNAME[0]}> # check file list empty, no files to process>"
        return
    fi

    #would run at least once in case of beeing empty
    for checkfile in "${CHECKFILELIST[@]}"; do

        checkfileshort=${checkfile##*/}
        checkfileid=${checkfileshort:0:4}
        logTrace "<${FUNCNAME[0]}> # filename:<${checkfileshort}> fullpath:<${checkfile}>"

        if ! safetycheck=$(LIB_FUNC_CHECK_CHECK_SECURITY "$checkfile"); then

            logWarn "Skipping check ${checkfileshort}. Reason: ${safetycheck}"

        elif [[ ! -r "${checkfile}" ]]; then

            logWarn "Skipping check ${checkfileshort}. Check file not readable.
                        ${checkfile}"

        elif [[ "${checkfileid:-}" == "${checkfileid_old:-}" ]]; then

            logError "Check with ID <${checkfileid}> listed twice. saphana-check installation error - please clean up."
            logError "Most probably mixed rpm and zip installations - remove saphana-check rpm, clean up /opt/sap/saphana-checks and reinstall"
            exit 1

        else

            CHECKLIST+=("${checkfile}")
            checkfileid_old=${checkfileid}

        fi

    done

    logTrace "<${FUNCNAME[0]}> # Number of check files validated: <${#CHECKFILELIST[@]}>"
    logTrace "<${FUNCNAME[0]}> # Number of checks added:          <${#CHECKLIST[@]}>"
}

function run_checklist {

    logTrace "<${BASH_SOURCE[0]}:${FUNCNAME[*]}>"

    local -i RC_CHECK
    for checkfile in "${CHECKLIST[@]:-}"; do

        checkfileshort=${checkfile##*/}
        checkname="check_${checkfileshort%.check}"

        logNewLine

            # shellcheck source=/dev/null
            if ! source "${checkfile}"; then
                logWarn "Skipping check ${checkfileshort}. Could not load check file.
                            ${checkfile}"
                RC_CHECK=3
            else
                ${checkname}
                RC_CHECK=$?
            fi

        update_check_counters ${RC_CHECK}

    done

}

function show_checklist {

    for checkfile in "${CHECKLIST[@]:-}"; do

        checkfileshort=${checkfile##*/}
        checkname="${checkfileshort%.check}"

        printf '%s\n' "${checkname}"

    done
    printf '\n'

}

function show_checksetlist {

    for checksetfile in "${PROGRAM_LIBDIR}"/checkset/*.checkset; do

        checksetfileshort=${checksetfile##*/}
        checksetname="${checksetfileshort%.checkset}"

        printf '%s\n' "${checksetname}"

    done
    printf '\n'

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

    printf -v _line_formated '%-7s|%6s |%8s |%5s |%8s |%5s |%6s' 'Status' 'Error' 'Warning' 'OK' 'Skipped' 'Info' 'Total'
    logNotify "## ${_line_formated}"

    printf -v _line_formated '%-7s|%6s |%8s |%5s |%8s |%5s |%6s' '%' $percent_error $percent_warning $percent_ok $percent_skipped $percent_info '100'
    logNotify "## ${_line_formated}"

    # shellcheck disable=SC2086
    printf -v _line_formated '%-7s|%6s |%8s |%5s |%8s |%5s |%6s' '#' $NUMBER_CHECKS_ERROR $NUMBER_CHECKS_WARNING $NUMBER_CHECKS_OK $NUMBER_CHECKS_SKIPPED $NUMBER_CHECKS_INFO $check_count
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
    printf -v _line_formated '%-17s' "${LIB_PLATF_ARCHITECTURE:-}"
    logNotify "## Architecture:   ${_line_formated}"
    logNotify '##'

    printf -v _line_formated '%-17s - %-11s %-20s' "${LIB_PLATF_VIRT_HYPER:-none}" 'Type:' "${LIB_PLATF_VIRT_TYPE:-none}"
    logNotify "## Virtualization: ${_line_formated}"
    logNotify '##'

    logNotify "## CPU:            ${LIB_PLATF_CPU:-}"
    logNotify '##'
    printf -v _line_formated '%-17s - %-11s %-20s' "${LIB_PLATF_CPU_SOCKETS:-}" 'CoresPerSocket:' "${LIB_PLATF_CPU_CORESPERSOCKET:-}"
    logNotify "## Sockets:        ${_line_formated}"
    printf -v _line_formated '%-17s - %-11s %-20s' "${LIB_PLATF_CPU_NUMANODES:-}" 'ThreadsPerCore:' "${LIB_PLATF_CPU_THREADSPERCORE:-}"
    logNotify "## Numa nodes:     ${_line_formated}"
    logNotify '##'

    #round up a divided number - Ceiling rounding (x+y-1)/y
    printf -v _line_formated "%5.0f GiB (%d MiB)" $(((LIB_PLATF_RAM_MiB_AVAILABLE + 1023) / 1024)) "${LIB_PLATF_RAM_MiB_AVAILABLE}"
    logNotify "## Memory usable:  ${_line_formated}"
    printf -v _line_formated "%5.0f GiB (%d MiB)" $(((LIB_PLATF_PMEM_MiB + 1023) / 1024)) "${LIB_PLATF_PMEM_MiB}"
    logNotify "## PMEM attached:  ${_line_formated}"
    printf -v _line_formated "1 : %.0f" "$(( 10**1 * LIB_PLATF_PMEM_MiB/LIB_PLATF_RAM_MiB_AVAILABLE ))e-1"
    logNotify "## DRAM / PMEM ratio:  ${_line_formated}"
    logNotify '##'

    local _ext_support
    LIB_FUNC_IS_SLES4SAP || LIB_FUNC_IS_RHEL4SAP && _ext_support='(4SAP)'

    printf -v _line_formated '%-17s - %-11s %-20s' "${OS_NAME/Linux /}${_ext_support:-} ${OS_VERSION}" 'Kernel:' "${OS_LEVEL}"

    logNotify "## OS:             ${_line_formated}"

    logNotify "## ${_line}"

    logNewLine

    generate_checklist
    if [[ ${#CHECKLIST[@]} -eq 0 ]]; then

        logError "## NOTHING to EXECUTE - revise check/checkset parameter !!!"
        exit 1

    elif [[ ${FLAGS_showchecks:?} -eq ${FLAGS_TRUE} ]]; then

        show_checklist

    elif [[ ${FLAGS_showchecksets:?} -eq ${FLAGS_TRUE} ]]; then

        show_checksetlist

    else

        run_checklist

    fi

    logNewLine
    logNotify "## ${_line}"
    print_counters

    logNewLine
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

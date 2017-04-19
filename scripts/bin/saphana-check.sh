#!/bin/bash
umask 022
set -u 		# treat unset variables as an error

#------------------------------------------------------------------
# SAP HANA ...
#------------------------------------------------------------------
# (C) Copyright SAP 2017
#
# Library Functions
# Script name: "saphana-check.sh"
#------------------------------------------------------------------

PROGVERSION="x.y-<dev>"
PROGDATE="YYYY-XXX-ZZ"


die() {
  [ $# -gt 0 ] && echo "error: $@" >&2
  exit 1
}

# # Make sure only root can run our script
# if [ "$(id -u)" -ne 0 ]; then
#    printf "This script must be run as root\n" 1>&2
#    exit 1
# fi

#set POSIX/C locales - date/time format normalized for all platforms
LC_ALL=POSIX
export LC_ALL

# configure shflags - define flags
source ./shflags || die 'unable to load shflags library'

#DEFINE_string	'checks'	''		'<\"check1 check2 ...\">  A space-separated list of checks that will be performed.'	'c'
#DEFINE_string	'checkset'	''		'<Checkset>  A textfile containing the various checks to perform.'	'C'
DEFINE_integer	'loglevel'	3		'notify/silent=0 (always), error=1, warn=2, info=3, debug=5, trace=6'	'l'
DEFINE_boolean	'verbose'	false	'enable chk_verbose mode (set loglevel=4)' 'v'
DEFINE_boolean	'debug'		false	'enable debug mode (set loglevel=5)' 'd'
DEFINE_boolean	'trace'		false	'enable trace mode (set loglevel=6)' 't'
FLAGS_HELP="USAGE: $0 [flags]"


OS_NAME=''
OS_VERSION=''
OS_LEVEL=''

CHECKLIST=''


#============================================================
# utility stuff
#============================================================
evaluate_cmdline_options() {

	[[ ${FLAGS_loglevel} -lt 7 ]] && LOG_VERBOSE_LVL=${FLAGS_loglevel} 

	[[ ${FLAGS_verbose} -eq ${FLAGS_TRUE} ]] && LOG_VERBOSE_LVL=4

	[[ ${FLAGS_debug} -eq ${FLAGS_TRUE} ]] && LOG_VERBOSE_LVL=5

	[[ ${FLAGS_trace} -eq ${FLAGS_TRUE} ]] && LOG_VERBOSE_LVL=6

	logDebug "<${BASH_SOURCE[0]}:${FUNCNAME[0]}> # LOG_VERBOSE_LVL=${LOG_VERBOSE_LVL}"
}

#============================================================
# Check handling
#============================================================
generate_checklist() {

	logTrace "<${BASH_SOURCE[0]}:${FUNCNAME[*]}>"

	local checkfile
	for checkfile in ../lib/check/*.check
	do
		local checkname
		checkname=check_$(basename "${checkfile}" .check)
		#safetycheck=$(lib_func_check_check_security $checkfile)
		if [ $? -ne 0 ]; then
			printf "Skipping check %s. Reason: %s\n"	"${checkname}"	${safetycheck}
			continue;
		fi
		CHECKLIST="${CHECKLIST} ${checkname}"
		source "${checkfile}"
	done
}

run_checklist() {

	logTrace "<${BASH_SOURCE[0]}:${FUNCNAME[*]}>"

    for check in ${CHECKLIST}
    do
        # printCheckHeader "Checking " $check
        # if ! isCheckBlacklisted $check ; then
			printf "\n"
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
main() {

	logTrace "<${BASH_SOURCE[0]}:${FUNCNAME[*]}>"
	
	lib_func_get_linux_distrib
	logNotify "${OS_NAME} ${OS_VERSION} ${OS_LEVEL}"

	logNotify "Architecture: ${LIB_PLATF_ARCHITECTURE}"
	logNotify "Byte Order: ${LIB_PLATF_BYTEORDER}"
	
	logNotify "Memory: ${LIB_PLATF_RAM_MB} MB"
	
	if lib_func_is_bare_metal
	then
		logNotify 'Running on Bare-Metal'
	else
		logNotify 'Running Virtualized'
	fi

	if lib_func_is_ibmpower
	then
		logNotify 'Running on IBM Power'
	fi
	

	printf "\n"

	generate_checklist
	run_checklist
	printf "\n\n"

	exit 0
}

#Import logger
source ./saphana-logger || die 'unable to load saphana-logger library'

# parse the command-line - shflags
FLAGS "$@" || exit 1
eval set -- "${FLAGS_ARGV}"
evaluate_cmdline_options

#Import remaining Libraries - logging is now active
source ./saphana-helper-funcs || die 'unable to load saphana-helper-funcs library'

# call main
main "$@"
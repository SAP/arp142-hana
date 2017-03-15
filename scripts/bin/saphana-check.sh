#!/bin/bash
umask 022

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

# # Make sure only root can run our script
# if [ "$(id -u)" -ne 0 ]; then
#    printf "This script must be run as root\n" 1>&2
#    exit 1
# fi

#set POSIX/C locales - date/time format normalized for all platforms
LC_ALL=POSIX
export LC_ALL


declare -i VERBOSE=6 # #notify/silent=0 (always), critical=1, error=2, warn=3 (default), info=4, debug=5, trace=6

OS_NAME=""
OS_VERSION=""
OS_LEVEL=""

CHECKLIST=""

#Import Libraries
source ./saphana-logger.sh
source ./saphana-helper-funcs.sh


#============================================================
# utility stuff
#============================================================

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

main "$@"
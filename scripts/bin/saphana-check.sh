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
#    echo "This script must be run as root" 1>&2
#    exit 1
# fi

#set POSIX/C locales - date/time format normalized for all platforms
LC_ALL=POSIX
export LC_ALL

#Import Libraries
#source ./saphana-logger.sh
source ./saphana-helper-funcs.sh

#flag defaults
D_DEBUG=TRUE					#debug
D_PRETEND=FALSE					#pretend execution of cmds

#============================================================
# utility stuff
#============================================================

#============================================================
# Check handling
#============================================================
function generate_checklist
{
	local checkfile
	for checkfile in ./lib/check/*.check
	do
		local checkname
		checkname=check_$(basename "${checkfile}" .check)
		#safetycheck=$(lib_func_check_check_security $checkfile)
		if [ $? -ne 0 ]; then
			echo "Skipping check ${checkname}. Reason: ${safetycheck}"
			continue;
		fi
		CHECKLIST="${CHECKLIST} ${checkname}"
		source "${checkfile}"
	done
}

#============================================================
# GLOBAL variables
#============================================================
#set flags to defaults
DEBUG=${D_DEBUG}

OS_NAME=""
OS_VERSION=""
OS_LEVEL=""

# A list of checks is a ... checklist
CHECKLIST=""

#============================================================
# main
#============================================================
main() {

	lib_func_get_linux_distrib

	printf "%s\t%s\t%s"	"${OS_NAME}" "${OS_VERSION}" "${OS_LEVEL}"
	printf "\n\n"
	printf "\n\n"

	exit 0
}

main "$@"
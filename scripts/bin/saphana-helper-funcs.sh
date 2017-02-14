#!/bin/bash
umask 022

#------------------------------------------------------------------
# SAP HANA ...
#------------------------------------------------------------------
# (C) Copyright SAP 2017
#
# Library Functions
# Script name: "saphana-helper-funcs.sh"
#------------------------------------------------------------------

#PROGVERSION="x.y-<dev>"
#PROGDATE="YYYY-XXX-ZZ"

##################################################
# Global functions - to be used in other scripts
##################################################
debug() {
	[ "${DEBUG}" = TRUE ] && echo "[DEBUG] $1" >&2
}


lib_func_get_linux_distrib() {

	#a local variable declared in a function is also visible to functions called by the parent function.
	local -r osfile='/etc/os-release'
	local -r susefile='/etc/SuSE-release'
	local -r redhatfile='/etc/redhat-release'
	local -r oraclefile='/etc/oracle-release'

	local _os_name
	local _os_version

	debug "<${BASH_SOURCE[0]}:${FUNCNAME[*]}>"

	if [ -f ${osfile} ] ; then
		#newer releases contain this file
		__linux_distrib_os_release "${osfile}"

	elif [ -f ${susefile} ] ; then
		__linux_distrib_suse_release "${susefile}"

	elif [ -f ${oraclefile} ] ; then
		#oracle is based on RedHat - redhatfile also exist, but check oracle first
		__linux_distrib_oracle_release "${oraclefile}"

	elif [ -f ${redhatfile} ] ; then
		__linux_distrib_redhat_release "${redhatfile}"

	else
		_os_name='Linux UNKNOWN'
	fi

	OS_NAME="${_os_name}"
	OS_VERSION="${_os_version}"
	OS_LEVEL=$(uname -r)

	debug "<${BASH_SOURCE[0]}:${FUNCNAME[0]}> # ${OS_NAME} ; ${OS_VERSION} ; ${OS_LEVEL}"

}

# Returns 1 on Virtualization, Bare-Metal=0.
# Takes no argument.
lib_func_is_bare_metal() {

	local -i _retval=0

	if [[ ${lib_platf_virtualized} -eq 0 ]] ;
	then
		_retval=1
	fi

	debug "<${BASH_SOURCE[0]}:${FUNCNAME[0]}> # ${_retval}"
	return ${_retval}
}

##########################################################
# Non-global functions - not to be used in other scripts
##########################################################

# $1 - os-release file
__linux_distrib_os_release() {

	local _ostmp
	local _osname
	local _osvers

	while read -r line; do

		debug "<${FUNCNAME[0]}> # ${1}:${line}"

		#NAME=""
		_ostmp=$(echo "${line}" | awk '/^NAME=/ {match($0, /".*"/); print substr($0,RSTART+1,RLENGTH-2)}')
		_osname=${_osname:=$_ostmp}

		#match 12.1 | 12.0.1 | 7.0
		_ostmp=$(echo "${line}" | awk '/^VERSION_ID=/ {match($0, /([0-9]+)(\.([0-9]+))+/); print substr($0,RSTART,RLENGTH) }')
		_osvers=${_osvers:=$_ostmp}

	done < "${1}"

	_os_version="${_osvers}"

	case ${_osname} in
		"SLES"*)
				_os_name='Linux SLES'
				;;

		"Red Hat Enterprise Linux Server")
				_os_name='Linux RHEL'
				;;

		"Oracle Linux Server")
				_os_name='Linux OLS'
				;;

		*)
			_os_name='Linux UNKNOWN'
			;;
	esac
}

# $1 - suse-release file
__linux_distrib_suse_release() {

	local _ostmp
	local _osname
	local _osvers
	local _susepatchl

	while read -r line; do

		debug "<${FUNCNAME[0]}> # ${1}:${line}"

		#Enterprise?
		_ostmp=$(echo "${line}" | awk '/^SUSE Linux Enterprise/ {match($0, /([0-9]+)/); print substr($0,RSTART,RLENGTH) }')
		_osname=${_osname:=$_ostmp}

		#11 - version
		_ostmp=$(echo "${line}" | awk '/^VERSION = / {match($0, /([0-9]+)/); print substr($0,RSTART,RLENGTH) }')
		_osvers=${_osvers:=$_ostmp}

		#2	- patchlevel
		_ostmp=$(echo "${line}" | awk '/^PATCHLEVEL = / {match($0, /([0-9]+)/); print substr($0,RSTART,RLENGTH) }')
		_susepatchl=${_susepatchl:=$_ostmp}

	done < "${1}"

	_os_version="${_osvers}.${_susepatchl}"

	if [ -n "${_osname}" ] ; then
		_os_name='Linux SLES'
	else
		_os_name='Linux Suse UNKNOWN'
	fi
}

# $1 - oracle-release file
__linux_distrib_oracle_release() {

	local _oltmp
	local _olname
	local _olversion

	#oracle is based on RedHat - redhatfile also exist, but check oracle first
	while read -r line; do

		debug "<${FUNCNAME[0]}> # ${1}:${line}"

		#Server within string - match any number
		_oltmp=$(echo "${line}" | awk '/^Oracle Linux Server/ {match($0, /([0-9]+)/); print substr($0,RSTART,RLENGTH) }')
		_olname=${_olname:=$_oltmp}

		#match 6.4
		_oltmp=$(echo "${line}" | awk '/^Oracle Linux/ {match($0, /([0-9]+)\.([0-9]+)/); print substr($0,RSTART,RLENGTH) }')
		_olversion=${_olversion:=$_oltmp}

	done < "${1}"

	_os_version=${_olversion}

	if [ -n "${_olname}" ] ; then
		_os_name='Linux OLS'
	else
		_os_name='Linux Oracle UNKNOWN'
	fi
}

# $1 - redhat-release file
__linux_distrib_redhat_release() {

	local _rhtmp
	local _rhname
	local _rhversion

	while read -r line; do

		debug "<${FUNCNAME[0]}> # ${1}:${line}"

		#Enterprise within string - match any number
		_rhtmp=$(echo "${line}" | awk '/^Red Hat Enterprise Linux/ {match($0, /([0-9]+)/); print substr($0,RSTART,RLENGTH) }')
		_rhname=${_rhname:=$_rhtmp}

		#match 6.4
		_rhtmp=$(echo "${line}" | awk '/^Red Hat/ {match($0, /([0-9]+)\.([0-9]+)/); print substr($0,RSTART,RLENGTH) }')
		_rhversion=${_rhversion:=$_rhtmp}

	done < "${1}"

	_os_version=${_rhversion}

	if [ -n "${_rhname}" ] ; then
		_os_name='Linux RHEL'
	else
		_os_name='Linux Redhat UNKNOWN'
	fi

}


##########################################################
# get System details
##########################################################

# ToDo:	Power platform does not provide 'dmidecode'

# Platform - "x3950 X6 -[6241ZB5]-", "ProLiant DL785 G6", "VMware Virtual Platform"
LIB_PLATF_NAME=$(dmidecode -s system-product-name)
declare -rx LIB_PLATF_NAME

# BIOS vendor of the HW: "LENOVO","HP","IBM Corp.","Phoenix Technologies LTD"
LIB_PLATF_BIOS=$(dmidecode -s bios-vendor | sed -e '/^\s*#/d')
declare -rx LIB_PLATF_BIOS

# ToDo:	verify for AMD processors
lib_platf_virtualized=$(grep -q '^flags.*hypervisor' /proc/cpuinfo; echo $?)
declare -r -i lib_platf_virtualized
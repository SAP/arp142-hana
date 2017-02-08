#!/bin/bash
umask 022

#------------------------------------------------------------------
# SAP HANA ...
#------------------------------------------------------------------
# (C) Copyright SAP 2016
#
# Library Functions
# Script name: "saphana-helper-funcs.sh"
#------------------------------------------------------------------

#PROGVERSION="x.y-<dev>"
#PROGDATE="YYYY-XXX-ZZ"

##################################################
# Global functions - to be used in other scripts #
##################################################
function debug() {
	[ "${DEBUG}" = TRUE ] && echo "DEBUG:<$1>" >&2
}


function lib_func_get_linux_distrib() {

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


##########################################################
# Non-global functions - not to be used in other scripts #
##########################################################

# $1 - os-release file
function __linux_distrib_os_release() {

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
function __linux_distrib_suse_release() {

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
function __linux_distrib_oracle_release() {

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
function __linux_distrib_redhat_release() {

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
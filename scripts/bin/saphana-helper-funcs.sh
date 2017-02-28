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
lib_func_get_linux_distrib() {

	#a local variable declared in a function is also visible to functions called by the parent function.
	local -r osfile='/etc/os-release'
	local -r susefile='/etc/SuSE-release'
	local -r redhatfile='/etc/redhat-release'
	local -r oraclefile='/etc/oracle-release'

	local _os_name
	local _os_version

	logTrace "<${BASH_SOURCE[0]}:${FUNCNAME[*]}>"

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

	logDebug "<${BASH_SOURCE[0]}:${FUNCNAME[0]}> # ${OS_NAME} ; ${OS_VERSION} ; ${OS_LEVEL}"

}

# Returns 0 on SLES, 1 on other
lib_func_is_sles() {

	local -i _retval=0
	
	logTrace "<${BASH_SOURCE[0]}:${FUNCNAME[*]}>"

	if [[ "${OS_NAME}" != 'Linux SLES' ]]; then
		_retval=1
	fi

	logDebug "<${BASH_SOURCE[0]}:${FUNCNAME[0]}> # RC=${_retval}"
	return ${_retval}
}

# Returns 1 on Virtualization, 0 on Bare-Metal
lib_func_is_bare_metal() {

	local -i _retval=0

	logTrace "<${BASH_SOURCE[0]}:${FUNCNAME[*]}>"

	if [[ ${lib_platf_virtualized} -eq 0 ]] ;
	then
		_retval=1
	fi

	logDebug "<${BASH_SOURCE[0]}:${FUNCNAME[0]}> # RC=${_retval}"
	return ${_retval}
}

# Compares two version strings
# Two version strings as parameters.
# Echos & returns 0 if equal, 1 if first is higher, 2 if second is higher
# - no external utilities - factor 10x faster than original (tr,grep are quite expansive)
lib_func_compare_versions() {

    logTrace "<${BASH_SOURCE[0]}:${FUNCNAME[*]}>"

	local -i _retval=0
    local version1=$(lib_func_trim $1)
	local version2=$(lib_func_trim $2)

    #${1//\-/\.} - Variable Substitution (faster then tr,sed or grep) - replace - by .
	#required for 2.11.3-17.95.2 --> 2.11.3.17.95.2
    version1=${version1//\-/\.}
    version2=${version2//\-/\.}

	logTrace "<${BASH_SOURCE[0]}:${FUNCNAME[0]}> # compare <${version1}> to <${version2}>"

    if [[ "${version1}" == "${version2}" ]]; then
        _retval=0
    else

		#to_array, split by .
        local IFS=.
        local ver1=(${version1})
        local ver2=(${version2})

        local -i i 
        # fill empty fields in ver1 with zeros
        for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
        do
            ver1[i]=0
        done
        
        for ((i=0; i<${#ver1[@]}; i++))
        do
            if [[ -z ${ver2[i]} ]]
            then
                # fill empty fields in ver2 with zeros
                ver2[i]=0
            fi
            if ((10#${ver1[i]} > 10#${ver2[i]}))
            then
                _retval=1
                break
            fi
            if ((10#${ver1[i]} < 10#${ver2[i]}))
            then
                _retval=2
                break
            fi
        done

    fi

    logDebug "<${BASH_SOURCE[0]}:${FUNCNAME[0]}> # RC=${_retval}"
	return ${_retval}
}

lib_func_trim() {
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"   
    printf "%s" "$var"
}
##########################################################
# Non-global functions - not to be used in other scripts
##########################################################

# $1 - os-release file
__linux_distrib_os_release() {

	local _ostmp
	local _osname
	local _osvers

	logTrace "<${BASH_SOURCE[0]}:${FUNCNAME[*]}>"

	while read -r line; do

		logTrace "<${FUNCNAME[0]}> # ${1}:${line}"

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

	logTrace "<${BASH_SOURCE[0]}:${FUNCNAME[*]}>"

	while read -r line; do

		logTrace "<${FUNCNAME[0]}> # ${1}:${line}"

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

	logTrace "<${BASH_SOURCE[0]}:${FUNCNAME[*]}>"

	#oracle is based on RedHat - redhatfile also exist, but check oracle first
	while read -r line; do

		logTrace "<${FUNCNAME[0]}> # ${1}:${line}"

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

	logTrace "<${BASH_SOURCE[0]}:${FUNCNAME[*]}>"

	while read -r line; do

		logTrace "<${FUNCNAME[0]}> # ${1}:${line}"

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

#============================================================
# LIB MAIN - initialization
#============================================================
_lib_helper_main() {

	logTrace "<${BASH_SOURCE[0]}:${FUNCNAME[*]}>"

	# get System details

	# ToDo:	Power platform does not provide 'dmidecode'

	# Platform - "x3950 X6 -[6241ZB5]-", "ProLiant DL785 G6", "VMware Virtual Platform"
	LIB_PLATF_NAME=$(dmidecode -s system-product-name)
	readonly LIB_PLATF_NAME

	# BIOS vendor of the HW: "LENOVO","HP","IBM Corp.","Phoenix Technologies LTD"
	LIB_PLATF_BIOS=$(dmidecode -s bios-vendor | sed -e '/^\s*#/d')
	readonly LIB_PLATF_BIOS

	# Installed RAM - meminfo not 100% correct 
	#$(cat /proc/meminfo | awk '/^MemTotal:/ {match($0, /[0-9]+/); print substr($0,RSTART,RLENGTH) }')
	LIB_PLATF_RAM_MB=$(printf "( %s  0)\n" "$(dmidecode -t memory | sed -e '/^\s*#/d' | grep "^\W*Size:.*B" | awk '{ if ($3=="GB") { x=$2*1024; print x } else print $2 }' | tr '\n' '+' )" | bc)
	readonly LIB_PLATF_RAM_MB

	# ToDo:	verify for AMD processors
	lib_platf_virtualized=$(grep -q '^flags.*hypervisor' /proc/cpuinfo;echo $?)
	readonly lib_platf_virtualized

}

##########################################################
#GLOBAL -x --> exported
declare -x LIB_PLATF_NAME
declare -x LIB_PLATF_BIOS
declare -xi LIB_PLATF_RAM_MB

#LIB local
declare -i lib_platf_virtualized

_lib_helper_main

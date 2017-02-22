
exec 3>&2 # logging stream (file descriptor 3) defaults to STDERR

logNotify() {		logger 0 "[N]"	"$1"; } # Always prints
logCritical() {		logger 1 "[C]"	"$1"; }
logError() {		logger 2 "[E]"	"$1"; }
logWarn() {			logger 3 "[W]"	"$1"; }
logInfo() {			logger 4 "[I]"	"$1"; }
logDebug() {		logger 5 "[D]"	"$1"; }
logTrace() {		logger 6 "[T]"	"$1"; }

logger() {
	if [[ ${VERBOSE} -ge "$1" ]]; then

		local logLevel="$2"
		shift 2
		
		local -r  datestring=$(date +'%Y-%m-%d %H:%M:%S')
		#local -ir prefix_length=$((20+4))	#len("2017-02-15 00:04:32")+1 && len("[C]")+1

		# Expand escaped characters, wrap at COLUMNS chars, indent wrapped lines
		printf "%s\t%s\n" "${datestring} ${logLevel}" "$*" | fold -w ${COLUMNS} | sed '2~1s/^/                               /' #>&3
	fi
}


print_folded() {
	local status="$1"
	shift 1

	if [[ -t 1 ]]; then #FD1 = stdout

		local -r  datestring=$(date +'%Y-%m-%d %H:%M:%S')
		local -ir prefix_length=$((20+4))	#len("2017-02-15 00:04:32")+1 && len("[C]")+1

		local -ir status_len=11	
		local line
		echo -e "$*" | fold -w ${COLUMNS} | ( read -r line ; echo "${datestring} ${status} ${line}" ; while read -r line ; do printf "%${prefix_length}s " ' ' ; echo -e "$line" ; done )
	else
		echo "$status" "$*"
	fi
}

#ToDo: remove/revise use_colored_output stuff
use_colored_output() {
	return 1
}

logCheckError() {
	#ToDo: count_error
	if use_colored_output; then
		print_folded "${warn}[ERROR]${norm}    "	"$@"
	else
		print_folded  "[ERROR]    "	"$@"
	fi
}

logCheckWarning() {
	#ToDo: count_warning
	if use_colored_output; then
		print_folded "${attn}${blb}[WARNING]${norm}  "	"$@"
	else
		print_folded "[WARNING]  "	"$@"
	fi
}

logCheckOk() {
	if [[ ${VERBOSE} -ge 4 ]]; then
		if use_colored_output; then
			print_folded "${done}[OK]${norm}       "	"$@"
		else
			print_folded "[OK]       "	"$@"
		fi
	fi
}

logCheckSkipped() {
	if [[ ${VERBOSE} -ge 4 ]]; then
		print_folded  "[SKIPPED]  "	"$@"
	fi
}


#============================================================
# LIB MAIN - initialization
#============================================================
_lib_logger_main() {

	COLUMNS=80 # required before 1st logger usage

	logTrace "<${BASH_SOURCE[0]}:${FUNCNAME[*]}>"

    if [[ -t 1 && -n "$TERM" && "$TERM" != "dumb" ]]; then
        COLUMNS=$(tput cols)
    fi

}

declare -i COLUMNS
_lib_logger_main
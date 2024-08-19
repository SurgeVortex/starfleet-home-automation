#!/bin/bash

PROCESS_ARGUMENTS_PATH="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

COLUMN_PATH="$(dirname ${PROCESS_ARGUMENTS_PATH})/libs/column"

# Script Description
#declare -A arguments
# Short option		arguments[0,0]="-h"
# Long Option		arguments[0,1]="--help"
# Required/Optional	arguments[0,2]="Required"
# Description		arguments[0,3]="This prints a description of the argument"
# Default Value		arguments[0,4]="0.0.1"
# Example		arguments[0,5]="$0 -h"
# Variable		arguments[0,6]="VERSION"
# UserInput		arguments[0,6]="true"

# Default Help message
declare -A arguments
arguments[0,0]="-h"; arguments[0,1]="--help"; arguments[0,3]="This option prints the help message";arguments[0,6]="DISPLAY_HELP";arguments[0,7]="true";

function usage ()
{
	echo
	OLDIFS=${IFS}
	IFS=$'\n'
	for line in "${SCRIPT_DESCRIPTION[@]}"
	do
		echo -e "${line}"
	done
	IFS=${OLDIFS}
	echo
	function add-column ()
	{
		if [[ ${1} == "" ]]
                then
                        LINE+="|"
                else
                        LINE+="${1}|"
                fi
	}
	COUNTER=0
	LINE=""
	while true
	do
		LINE+="|"
		if [[ ${arguments[${COUNTER},0]} == "" ]] && [[ ${arguments[${COUNTER},1]} == "" ]]
		then
			break
		fi
		for column in $(seq 0 5)
		do
			LINE+="${arguments[${COUNTER},${column}]}|"
		done

		LINE+="\n"

		COUNTER=$(( COUNTER + 1 ))
	done
	echo -e "${LINE}" | "${COLUMN_PATH}" \
		--separator '|' \
		--table \
		--table-columns Usage,ShortArg,LongArg,Mandatory,Description,DefaultValue,Example \
		--table-wrap Description,DefaultValue,Example \
		--output-width $(( ${COLUMNS:-200} * 3 / 4))
	echo
}

function process-arguments ()
{
	PARAMS=""
	while (( "${#}" ))
	do
		COUNTER=0
		while true
		do
			if [[ "${arguments[${COUNTER},0]}" == "" ]] && [[ "${arguments[${COUNTER},1]}" == "" ]]
			then
					break
			fi
			ARGUMENT_PROCESSED="false"
			if [[ "${1}" == "${arguments[${COUNTER},0]}" ]] || [[ "${1}" == "${arguments[${COUNTER},1]}" ]]
			then
				if { [[ -n "${2}" ]] && [[ ${2:0:1} != "-" ]]; } || [[ "$(echo "${arguments[${COUNTER},7]}" | tr '[:upper:]' '[:lower:]')" == "true" ]]
				then
					if [[ "$(echo "${arguments[${COUNTER},7]}" | tr '[:upper:]' '[:lower:]')" == "true" ]]
					then
						TMP_VALUE=0
						SHIFT_VALUE=""
					else
						TMP_VALUE="${2}"
						SHIFT_VALUE=2
					fi
					export ${arguments[${COUNTER},6]}="${TMP_VALUE}"
					shift ${SHIFT_VALUE}
					ARGUMENT_PROCESSED="true"
					break
				else
					echo -e "${RED}Argument for ${1} is missing${COLOR_OFF}"
	                                exit 1
				fi
			fi
			COUNTER=$(( COUNTER + 1 ))
		done
		if [[ "${ARGUMENT_PROCESSED}" != "true" ]]
		then
			if [[ "${1}" == "-"* ]]
			then
				eerror "Unsupported flag ${1}"
				usage
				exit 1
			else
				PARAMS+=" ${1}"
				shift
			fi
		fi
	done
	if [[  "${DISPLAY_HELP}" == "0" ]]
	then
		usage
		exit
	fi
	COUNTER=0
	ERROR_LINE=""
	while true
	do
		if [[ "${arguments[${COUNTER},0]}" == "" ]] && [[ "${arguments[${COUNTER},1]}" == "" ]]
		then
			break
		fi
		if [[ "$( echo ${arguments[${COUNTER},2]} | tr '[:upper:]' '[:lower:]')" == "required" ]] && [[ -z "${!arguments[${COUNTER},6]}" ]]
		then
			if [[ -z "${arguments[${COUNTER},0]}" ]] && [[ ! -z "${arguments[${COUNTER},1]}" ]]
			then
				PARAMETER="${arguments[${COUNTER},1]}"
			elif [[ ! -z "${arguments[${COUNTER},0]}" ]] && [[ -z "${arguments[${COUNTER},1]}" ]]
			then
				PARAMETER="${arguments[${COUNTER},0]}"
			else
				PARAMETER="${arguments[${COUNTER},0]}/${arguments[${COUNTER},1]}"
			fi
			ERROR_LINE+="Required parameter ${PARAMETER} not set\n"
		fi
		COUNTER=$(( COUNTER + 1 ))
	done
	if [[ ! -z ${ERROR_LINE} ]]
	then
		echo -e "${RED}${ERROR_LINE}${COLOR_OFF}"
		usage
		exit 1
	fi
	eval set -- "$PARAMS"
}

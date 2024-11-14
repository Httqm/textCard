#!/usr/bin/env bash

abs() {
	# return the absolute value of a number
	# this is done by removing the leading '-', if any
	echo "${1#-}"
	}


colorEcho() {
	# examples :
	#	colorEcho 'This is red + normal text.'   red   0
	#	colorEcho 'This is red + bold text.'     red   1
	#	colorEcho 'This is green + normal text.' green 0
	#	colorEcho 'This is green + bold text'    green 1
	local message="$1"
	local color="$2"
	local bold=${3:-0}					# 0|1. Defaults to "not bold"
	local addTrailingNewline=${4:-1}	# 0|1. Defaults to "yes, add a trailing newline"

	[ $addTrailingNewline -eq 1 ] && newline='' || newline='-n'

	declare -A colors	# required to declare an associative array

	colors['red']="\e[$bold;31m"
	colors['green']="\e[$bold;32m"
	colors['yellow']="\e[$bold;33m"
	colors['blue']="\e[$bold;34m"
	colors['purple']="\e[$bold;35m"
	colors['cyan']="\e[$bold;36m"
	colors['white']="\e[$bold;37m"
	colors['reset']='\e[0m'	# Reset text attributes to normal without clearing screen.

	echo -e $newline "${colors[$color]}$message${colors['reset']}"
	}


message() {
	local messageType=$1
	local messageText=$2
	case "$messageType" in
		ok)
			# use case : inform user that task/function/script is finished + successful
			# Can be silenced out of verbose mode ? Yes.
			color='green'
			icon='✅'
			;;
		error)
			# use case : inform user that some specific action didn't work as expected,
			#            this is generally followed by an 'exit' command
			# Can be silenced out of verbose mode ? No!
			color='red'
			icon='🚩'
			;;
		info)
			# use case : give extra information to the user, while the script is on its "normal" path
			# Can be silenced out of verbose mode ? Yes.
			color='cyan'
			icon='ℹ️'
			;;
		warning)
			# use case : give extra information to the user, when the script is NOT on its "normal" path
			# Can be silenced out of verbose mode ? No.
			color='yellow'
			icon='⚠️'
			;;
		*)
			# use case : fallback when the script developer failed to use one of the message types above,
			#            this should not be visible to users.
			# Can be silenced out of verbose mode ? N/A.
			color='white'
			icon='😲️'
			;;
	esac
	colorEcho "$icon $messageText" "$color" 1 1
	}

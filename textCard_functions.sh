#!/usr/bin/env bash

repeatStringUpToNCharacters() {
	# This function can repeat a string any number of times, including 0.
	# It supports repeating a 'n' chars strings up to 'm' length with n > m thanks to the final crop.
	local stringToRepeat=$1
	local lengthOfStringMadeOfRepetitions=$2
	# when the repeated string is a single character, lengthOfStringMadeOfRepetitions == nb of characters
#	echo -e "\nlengthOfStringMadeOfRepetitions : '$lengthOfStringMadeOfRepetitions'"
	output=''
	local n=$((lengthOfStringMadeOfRepetitions/${#stringToRepeat}))
	for((i=0;i<$n;i++)); do output+="$stringToRepeat"; done
	local extra=$((lengthOfStringMadeOfRepetitions % ${#stringToRepeat}))
	echo -n "$output${stringToRepeat:0:$extra}"
	}


checkStringIsShortherThan() {
	local string=$1
	local maxLength=$2
#	echo "string: '$string', length: '${#string}', maxLength: '$maxLength'"

	if [ "${#string}" -gt "$maxLength" ] ; then

		lineNumber=$(grep -nF "$string" "$inputFile" | cut -d ':' -f 1)
		# NB: this may cause an error when running unit tests :
		#	grep: : No such file or directory
		# explanation + workaround in 'tests/test_makeTextLinePadded.sh',

		message error "The line '$string' is longer (${#string}) than the max length ($maxLength)\ncheck input file '$inputFile' at line $lineNumber"
		exit 1
	fi
	# TODO: some functions call this one with "<string><padding>" because what matters is the total length.
	# But this brings 2 problems :
	# - we can't 'grep' for "<string><padding>" in the input file, and can't report faulty line
	# - the error message is misleading while stating that "<string><padding>" is too long, whatever position was used
	}


makeBlankLine() {
	local outputFile=$1
	echo $(repeatStringUpToNCharacters "$blankCharacter" "$nbColumns") >> "$outputFile"
	# "echo $(...)" to add a trailing 'newline'
	}


makeTextLine1String() {
	local outputFile=$1
	local position=$2
	local string=$3
	local paddingCharacter=${4:-$blankCharacter}
	local stringLength=${#string}

	checkStringIsShortherThan "$string" "$nbColumns"

	# NB: for all 'echo' below :
	#     'echo' discards leading/trailing spaces, which is why the whole strings to 'echo' are quoted
	case "$position" in
		left)
			local rightPadding=$((nbColumns-stringLength))
			echo "$string$(repeatStringUpToNCharacters "$paddingCharacter" "$rightPadding")" >> "$outputFile"
			;;
		right)
			local leftPadding=$((nbColumns-stringLength))
			echo "$(repeatStringUpToNCharacters "$paddingCharacter" "$leftPadding")$string" >> "$outputFile"
			;;
		center)
			# if leftPadding + rightPadding = odd number, let's say leftPadding gets the '+1'
			local leftPadding=$(((nbColumns+1-stringLength)/2))
			local rightPadding=$((nbColumns-stringLength-leftPadding))
			echo "$(repeatStringUpToNCharacters "$paddingCharacter" "$leftPadding")$string$(repeatStringUpToNCharacters "$paddingCharacter" "$rightPadding")" >> "$outputFile"
			;;
	esac
	}


makeTextLine2Strings() {
	local outputFile=$1
	local position=$2
	local string1=$3
	local string2=$4
	local paddingCharacter=${5:-$blankCharacter}

	local string1Length=${#string1}
	local string2Length=${#string2}

	[ "$string1Length" -gt 0 -a "$string2Length" -eq 0 ] && {
		message error "<right> string is empty on line '$string1'\n\t\
useless use of '2strings|leftright|<left>|<right>'\n\t\
use '1string|left|$string1' instead"
		exit 1
		}
	[ "$string1Length" -eq 0 -a "$string2Length" -gt 0 ] && {
		message error "<left> string is empty on line '$string2'\n\t\
useless use of '2strings|leftright|<left>|<right>'\n\t\
use '1string|right|$string2' instead"
		exit 1
		}
	[ "$string1Length" -eq 0 -a "$string2Length" -eq 0 ] && {
		message error "<left> and <right> strings are empty: useless use of '2strings|leftright|<left>|<right>', use 'blank' instead"
		exit 1
		}

	for i in "$string1" "$string2" "$string1$string2"; do
		checkStringIsShortherThan "$i" "$nbColumns"
	done

	case "$position" in
		leftright)
			# if leftPadding + rightPadding = odd number, let's say leftPadding gets the '+1'
			local padding=$((nbColumns-string1Length-string2Length))
			echo "$string1$(repeatStringUpToNCharacters "$paddingCharacter" "$padding")$string2" >> "$outputFile"
			# 'echo' discards leading/trailing spaces, which is why the whole strings to 'echo' are quoted
			;;
	esac
	}


makeTextLinePadded() {
	local outputFile=$1
	local position=$2
	local string=$3
	local paddingWidth=$4
	local paddingCharacter=${5:-$blankCharacter}

	[ -z "$paddingWidth" ] && {
		lineNumber=$(grep -nF "$string$separator" "$inputFile" | cut -d ':' -f 1)
		message error "No padding width specified in input file '$inputFile' at line $lineNumber."
		exit 1
		}

	[ "$paddingWidth" -eq 0 ] && {
		lineNumber=$(grep -nF "$string${separator}0" "$inputFile" | cut -d ':' -f 1)
		message error "Padding width set to 0 in '$inputFile' at line $lineNumber : useless use of 'padded|$position', use '1string|$position' instead."
		exit 1
		}

	padding=$(repeatStringUpToNCharacters "$paddingCharacter" "$paddingWidth")
	checkStringIsShortherThan "$string$padding" "$nbColumns"

	restOfLinePaddingWitdh=$((nbColumns-paddingWidth-${#string}))
	[ "$restOfLinePaddingWitdh" -eq 0 ] && {
		lineNumber=$(grep -nF "$string$separator" "$inputFile" | cut -d ':' -f 1)
		oppositePosition='right'
		[ "$position" == 'right' ] && oppositePosition='left'
		message error "Empty 'rest of line padding' in '$inputFile' at line $lineNumber : useless use of 'padded|$position', use '1string|$oppositePosition' instead."
		exit 1
		}

	restOfLinePadding=$(repeatStringUpToNCharacters "$paddingCharacter" "$restOfLinePaddingWitdh")

	case "$position" in
		left)
			line="$padding$string$restOfLinePadding"
			;;
		right)
			line="$restOfLinePadding$string$padding"
			;;
	esac
	# 'echo' discards leading/trailing spaces, which is why the whole strings to 'echo' are quoted
	echo "$line" >> "$outputFile"
	}

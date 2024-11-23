#!/usr/bin/env bash

usage() {
	cat <<-EOF

	    Layout text on a rectangular area aka 'card'.

	    Usage: $0 -i <inputFile> [other options]

	    Options:
	    -c <lang>        spell [c]heck <inputFile> with 'aspell' and its <lang> dictionary
	    -h               show this [h]elp and exit
	    -i <inputFile>   load text from <[i]nputFile>
	    -o <outputFile>  write result to <outputFile>
	                     - defaults to '/dev/stdout'
	                     - once generated, you may open it in a web browser and
	                       - view next version with [F5]
	                       - convert it to PDF with 'Print to file'

	EOF
	}


getCliParameters() {
	args="$@"
	[ -z "$args" ] && {
		message error "missing mandatory argument '-i <inputFile>'"
		usage
		exit 1
		}

	while getopts ':c:hi:o:' opt; do
		case "$opt" in
			c)
#				message info 'spell check enabled'
				dictionary="$OPTARG"
				aspell dump dicts | grep -Eq "^$dictionary$" \
					&& message info "Dictionary '$dictionary' available" \
					|| { message error "No aspell dictionary '$dictionary' found"; exit 1; }
				# TODO: replace 'dict xx available' with 'spelling (xx) ok' (see below)
				;;
			i)
				cliInputFile="$OPTARG"
#				echo "inputFile : '$cliInputFile'"
				;;
			h)	usage; exit 0 ;;
			o)
				outputFile="$OPTARG"
				;;
			:)	message error "no value given for option '-$OPTARG'"; usage; exit 1 ;;
			\?)	message error "invalid option: '-$OPTARG'"; usage; exit 1 ;;
		esac
	done

	# always check '-i' flag :
	#	- '-i' specified with no value = error
	#	- '-i' omitted = error
	[ ! -e "$cliInputFile" ] && { message error "input file '$cliInputFile' not found"; exit 1; }
	}


makeCard() {
	local inputFile=$1
	local outputFile=$2
	local cliInputFile=$3	# used to report errors
	while read line; do

		[[ "$line" =~ ^(#|$) ]] && continue		# ignore comments and blank lines

		IFS="$commandParametersSeparator" read -a myArray <<< "$line"
#		echo "${myArray[0]} ${myArray[1]}"
		case "${myArray[0]}" in
			blank)
				makeBlankLine "$outputFile"
				((nbLinesOnCard++))
				;;
			1string)
				makeTextLine1String "$cliInputFile" "$outputFile" "${myArray[1]}" "${myArray[2]}" "${myArray[3]}"
				((nbLinesOnCard++))
				;;
			2strings)
				makeTextLine2Strings "$cliInputFile" "$outputFile" "${myArray[1]}" "${myArray[2]}" "${myArray[3]}" "${myArray[4]}"
				((nbLinesOnCard++))
				;;
			padded)
				makeTextLinePadded "$cliInputFile" "$outputFile" "${myArray[1]}" "${myArray[2]}" "${myArray[3]}" "${myArray[4]}"
				((nbLinesOnCard++)) # TODO: factorize the ++ at the end of the 'case'
				;;
			*)
				lineNumber=$(grep -nF "${myArray[0]}" "$cliInputFile" | cut -d ':' -f 1)
				message error "unknown command '${myArray[0]}' in '$cliInputFile' at line $lineNumber"
				exit 1
				;;
		esac
	done < "$inputFile"
	}


checkNbLinesOnCard() {
	nbLinesAvailableOnCard=$((nbLines-nbLinesOnCard))
	[ "$(abs $nbLinesAvailableOnCard)" -gt "1" ] && LINES='lines' || LINES='line'
	messageNbLines="Number of lines = $nbLinesOnCard / $nbLines"
	if [ "$nbLinesAvailableOnCard" -ge "0" ]; then
		message info "$messageNbLines ($nbLinesAvailableOnCard $LINES left)"
	else
		message error "$messageNbLines (cut $(abs $nbLinesAvailableOnCard) $LINES to fit a single page)"
	fi
	}


spellCheckInputFile() {
	local inputFile=$1
	local dictionary=$2
	personalWordList="${inputFile}_personalWordList"
	replacementList="${inputFile}_replacementList"
#	echo "wordLists : '$personalWordList', '$replacementList'"
	aspell \
		-d "$dictionary" \
		--sug-mode=bad-spellers \
		--personal="$personalWordList" \
		--repl="$replacementList" \
		--dont-backup \
		check "$inputFile"
	}


copyPayloadIntoFile() {
	# copy everything from "$sourceFile" into "$destinationFile" EXCEPT
	#	- macros
	#	- comments
	#	- blank lines
	local sourceFile=$1
	local destinationFile=$2
	grep -Ev '^(macro|#|$)' "$sourceFile" > "$destinationFile"
	}


main() {
	directoryOfThisScript="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
	for functionFile in config.sh textCard_functions.sh functions.sh; do
		source "$directoryOfThisScript/$functionFile"
	done

	nbLinesOnCard=0
	dictionary=''						# can be populated by '-c <value>' from CLI
	outputFile="$defaultOutputFile"		# may be overridden by '-o <outputFile>' from CLI

	getCliParameters "$@"

	[ -n "$dictionary" ] && {
		spellCheckInputFile "$cliInputFile" "$dictionary" && message info "Spelling ($dictionary) OK 👍"
		}

	> "$outputFile"
	# TODO: use exec > /path/to/logFile 2>&1 construct (?)

	# handle macros
	if $(grep -Eq "^[^#]*$macroArgumentsSeparator" "$cliInputFile") ; then
		message info 'macro(s) found'

		tmpFile=$(mktemp --tmpdir='/run/shm' $(basename $0).XXXXXXXXXXXX.tmp)
#		echo "$tmpFile"

		copyPayloadIntoFile "$cliInputFile" "$tmpFile"
		runMacros "$cliInputFile" "$tmpFile"

#		cat "$tmpFile"
		makeCard "$tmpFile" "$outputFile" "$cliInputFile"

		[ -f "$tmpFile" ] && rm "$tmpFile"
	else
		message info 'no macro found, working as usual'
		makeCard "$cliInputFile" "$outputFile" "$cliInputFile"
	fi

	checkNbLinesOnCard
	[ "$outputFile" != "$defaultOutputFile" ] && message ok "Output written to: '$outputFile'"
	}


main "$@"
# TODO:
# - add a 'verbose' flag + show 'info' messages accordingly :
#	- transmit "verbose mode" variable to function so that the 'if' is handled there
#	- OR have a 'destinationOfInfoMessages' variable set to :
#		- /dev/stdout if 'verbose mode'
#		- /dev/null otherwise
#		==> no 'if', always 'echo', the only difference is the destination
# - clean commented lines:	grep -riEn '^#' *sh
# - check words of "aspell word list" still exist in input txt file
# - add more formatting functions :
#	- LEFTCENTERRIGHT : 'LEFT     CENTER     RIGHT'
#	- 2COLS :           '    LEFT        RIGHT    '

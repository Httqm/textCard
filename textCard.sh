#!/usr/bin/env bash

usage() {
	cat <<-EOF

	    Layout text on a rectangular area aka 'card'.

	    Usage: $0 -i <inputFile> [options]

	    Options:
	    -c <lang>        spell [c]heck <inputFile> with 'aspell' using its <lang> dictionary
	    -h               show this [h]elp and exit
	    -i <inputFile>   load text from <[i]nputFile>
	    -o <outputFile>  write result to <outputFile>
	                     - defaults to '/dev/stdout'
	                     - once generated, you may open it in a web browser and
	                       - view next version with [F5]
	                       - convert it to PDF with 'Print to file'
	    -v               [v]erbose mode

	EOF
	}


getCliParameters() {
	args="$@"
	[ -z "$args" ] && {
		message error "missing mandatory argument '-i <inputFile>'"
		usage
		exit 1
		}

	while getopts ':c:hi:o:v' opt; do
		case "$opt" in
			c)
				[ "$verbose" -eq 1 ] && message info 'spell check enabled'
				dictionary="$OPTARG"

				aspell dump dicts | grep -Eq "^$dictionary$"
				if [ "$?" -eq 0 ]; then
					[ "$verbose" -eq 1 ] && message info "dictionary '$dictionary' available"
				else
					message error "No aspell dictionary '$dictionary' found"; exit 1;
				fi
				;;
			i)
				cliInputFile="$OPTARG"
#				echo "inputFile : '$cliInputFile'"
				;;
			h)	usage; exit 0 ;;
			o)
				outputFile="$OPTARG"
				;;
			v)	verbose=1 ;;
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
				;;
			1string)
				makeTextLine1String \
					"$cliInputFile" \
					"$outputFile" \
					"${myArray[1]}" \
					"${myArray[2]}" \
					"${myArray[3]}"
				;;
			2strings)
				makeTextLine2Strings \
					"$cliInputFile" \
					"$outputFile" \
					"${myArray[1]}" \
					"${myArray[2]}" \
					"${myArray[3]}" \
					"${myArray[4]}"
				;;
			padded)
				makeTextLinePadded \
					"$cliInputFile" \
					"$outputFile" \
					"${myArray[1]}" \
					"${myArray[2]}" \
					"${myArray[3]}" \
					"${myArray[4]}"
				;;
			*)
				lineNumber=$(grep -nF "${myArray[0]}" "$cliInputFile" | cut -d ':' -f 1)
				message error "unknown command '${myArray[0]}' in '$cliInputFile' at line $lineNumber"
				exit 1
				;;
		esac
		((nbLinesOnCard++))
	done < "$inputFile"
	}


checkNbLinesOnCard() {
	nbLinesAvailableOnCard=$((nbLines-nbLinesOnCard))
	[ "$(abs $nbLinesAvailableOnCard)" -gt "1" ] && LINES='lines' || LINES='line'
	messageNbLines="Number of lines = $nbLinesOnCard / $nbLines"
	if [ "$nbLinesAvailableOnCard" -ge "0" ]; then
		[ "$verbose" -eq 1 ] && message info "$messageNbLines ($nbLinesAvailableOnCard $LINES left)" || :
	else
		message error "$messageNbLines (cut $(abs $nbLinesAvailableOnCard) $LINES to fit a single page)"
	fi
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


cleanPersonalWordList() {
	local fileToSpellCheck=$1
	local personalWordList=$2
	# Words that don't exist in Aspell's dictionary are added to the personal word list upon spell check.
	# But if such words disappear from the spell checked document after edits, they are not removed from
	# the personal list, which may grow out of proportions.
	# This function checks that each word of the personal word list is still used in the document,
	# and removes it from the list otherwise.
	# checking words of our Aspell personal list are still in the document to check
	listOfPersonalWordsToKeep=$(head -1 "$personalWordList")
	listOfPersonalWordsToRemove=''
	nbWordsToRemoveFromPersonalList=0
	while read wordOfPersonalList; do
#		echo "$wordOfPersonalList"
		grep -q "$wordOfPersonalList" "$fileToSpellCheck" \
			&& listOfPersonalWordsToKeep+="\n$wordOfPersonalList" \
			|| {
				listOfPersonalWordsToRemove+="$wordOfPersonalList, "
				((nbWordsToRemoveFromPersonalList++))
				}
	done < <(tail -n +2 "$personalWordList")

	if [ "$nbWordsToRemoveFromPersonalList" -gt 0 ]; then	# i.e. when "at least 1 word found"
		[ "$verbose" -eq 1 ] && {
			[ "$nbWordsToRemoveFromPersonalList" -gt 1 ] && WORD='Words' || WORD='Word'
			message info "$WORD not found anymore in '$fileToSpellCheck' and removed from '$personalWordList' :\n\t$listOfPersonalWordsToRemove"
			}
		echo -e "$listOfPersonalWordsToKeep" > "$personalWordList"
		# This re-writes the header line of the personal word list as-is, including the number of items
		# in the list, which is wrong now. This has no consequence so far.
		# This wrong number can be fixed by removing one of the words from the list + launching a spell check,
		# so that Aspell rewrites the list with the fixed header.
	fi
	}


doSpellCheck() {
	local fileToSpellCheck=$1
	local dictionary=$2

	local personalWordList="${fileToSpellCheck}_personalWordList"
	local replacementList="${fileToSpellCheck}_replacementList"

	cleanPersonalWordList "$fileToSpellCheck" "$personalWordList"

	[ -n "$dictionary" ] && {
		aspell \
			-d "$dictionary" \
			--sug-mode=bad-spellers \
			--personal="$personalWordList" \
			--repl="$replacementList" \
			--dont-backup \
			check "$fileToSpellCheck" && \
				[ "$verbose" -eq 1 ] && \
					message info "spelling ($dictionary) OK 👍"
		}
	}


main() {
	directoryOfThisScript="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
	for functionFile in config.sh textCard_functions.sh functions.sh; do
		source "$directoryOfThisScript/$functionFile"
	done

	verbose=0
	nbLinesOnCard=0
	dictionary=''						# can be populated by '-c <value>' from CLI
	outputFile="$defaultOutputFile"		# may be overridden by '-o <outputFile>' from CLI

	getCliParameters "$@"
	doSpellCheck "$cliInputFile" "$dictionary"
	> "$outputFile"

	# handle macros
	if $(grep -Eq "^[^#]*$macroArgumentsSeparator" "$cliInputFile") ; then
#		echo 'macro(s) found'
		tmpFile=$(mktemp --tmpdir='/run/shm' $(basename $0).XXXXXXXXXXXX.tmp)
		copyPayloadIntoFile "$cliInputFile" "$tmpFile"
		runMacros "$cliInputFile" "$tmpFile"
		makeCard "$tmpFile" "$outputFile" "$cliInputFile"
		[ -f "$tmpFile" ] && rm "$tmpFile"
	else
		[ "$verbose" -eq 1 ] && message info 'no macro found, working as usual'
		makeCard "$cliInputFile" "$outputFile" "$cliInputFile"
	fi

	checkNbLinesOnCard
	[ "$outputFile" != "$defaultOutputFile" ] && message ok "Output written to: '$outputFile'"
	}


main "$@"
# TODO:
# - do all TODOs : grep -riEn 'TODO' *sh
# - clean commented lines:	grep -riEn '^#' *sh
# - add more formatting functions :
#	- LEFTCENTERRIGHT : 'LEFT     CENTER     RIGHT'
#	- 2COLS :           '    LEFT        RIGHT    '

#!/usr/bin/env bash

# macros with 1 arg, change :
#	macro§header§1string|left|$1§
#	header§This is a header§
# into :
#	1string|left|This is a header
#
# macros with 2 args, change :
#	macro§leftAndRight§2strings|leftright|$1|$2|§
#	leftAndRight§LEFT§RIGHT§
# into :
#	2strings|leftright|LEFT|RIGHT
#
# so that it can be fed to 'textCard.sh'


inputFile='macro.txt'
macroArgumentsSeparator='§'
parametersSeparator='|'


copyFileContents() {
	# copy 'inputfile' contents into 'tmpFile' EXCEPT
	#	- macros
	#	- comments
	#	- blank lines
	local sourceFile=$1
	local destinationFile=$2
	grep -Ev '^(macro|#|$)' "$sourceFile" > "$destinationFile"
	}

countOccurrencesOfStringInLine() {
	local string=$1
	local line=$2
	echo "$line" | grep -o "$string" | wc -l
	}


loadAndApplyMacros() {
	local inputFile=$1
	local tmpFile=$2
	# read macros from "$inputfile"

	while IFS="$macroArgumentsSeparator" read macro macroName macroCode; do

		nbArgsInMacro=$(countOccurrencesOfStringInLine '\$' "$macroCode")

		# build sed line
#		search="$macroName$macroArgumentsSeparator(.*)$macroArgumentsSeparator"
#		search="$macroName$macroArgumentsSeparator(.*)$macroArgumentsSeparator(.*)$macroArgumentsSeparator"
		search="$macroName"
		for i in $(seq 1 "$nbArgsInMacro"); do
			search+="$macroArgumentsSeparator(.*)"
		done
		search+="$macroArgumentsSeparator"

		replace=$(echo "$macroCode" | tr '$' '\\')

		cat <<-EOF
		macro name : $macroName
		macro code : $macroCode	   <-- $nbArgsInMacro arguments

		search :  '$search'
		replace : '$replace'

		sed -r "s/$search/$replace/g" "$tmpFile"
		EOF

		#	apply it everywhere on 'new file'
		sed -ri "s/$search/$replace/g" "$tmpFile"

	done < <(grep -E "^macro$macroArgumentsSeparator" "$inputFile")

	echo '======================='
	cat "$tmpFile"
	echo '======================='
	}


makeCard() {
	local sourceFile=$1
	./textCard.sh -i "$sourceFile"
	}


main() {
	tmpFile=$(mktemp --tmpdir='/run/shm' $(basename $0).XXXXXXXXXXXX.tmp)

	copyFileContents "$inputFile" "$tmpFile"
	loadAndApplyMacros "$inputFile" "$tmpFile"

	makeCard "$tmpFile"

	[ -f "$tmpFile" ] && rm "$tmpFile"
	}


main

#!/usr/bin/env bash

BASH_UNIT="$HOME/Dev/GitHub/bash_unit/bash_unit"

while read testFile; do
	[[ "$testFile" =~ ^# ]] && continue		# comment test files in the list below to skip them
	"$BASH_UNIT" "$testFile"
done < <(cat <<-EOF
	test_textCard_functions.sh
	test_makeTextLine1String.sh
	test_makeTextLine2Strings.sh
	test_makeTextLinePadded.sh
	test_functions.sh
	EOF
	)

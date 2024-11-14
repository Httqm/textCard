#!/usr/bin/env bash

# These are tests to be run with 'bash_unit'
#       https://github.com/pgrange/bash_unit
# To run tests :
#       path/to/bash_unit <thisFile>.sh

directoryOfThisScript="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$directoryOfThisScript/../config.sh"
source "$directoryOfThisScript/../textCard_functions.sh"


test_repeatStringUpToNCharacters() {
	for finalLength in {0..27..3}; do
		for stringToRepeat in '1' '22' '333' '55555' 'XXXXXXXXXX'; do
			expected=$(result=''; for((i=0;i<$finalLength;i++)); do result+="$stringToRepeat"; done; echo -n "${result:0:$finalLength}")
			output=$(repeatStringUpToNCharacters "$stringToRepeat" "$finalLength")
#			echo "stringToRepeat: '$stringToRepeat', finalLength: '$finalLength', expected: '$expected', output: '$output'"
			assert_equals "$output" "$expected"
		done
	done
	}


test_checkStringIsShortherThan() {
	# testing the function when given
	#	- a string which length <  max : should be ok
	#	- a string which length == max : should be ok
	#	- a string which length > max  : should be ko
	for lengthToTest in {0..3}; do
		stringToCheck=$(repeatStringUpToNCharacters 'X' "$lengthToTest")
#		echo "lengthToTest: '$lengthToTest', stringToCheck : '$stringToCheck'"
		assert_status_code 0 "checkStringIsShortherThan '$stringToCheck' $((lengthToTest+1))"
		assert_status_code 0 "checkStringIsShortherThan '$stringToCheck' $((lengthToTest))"
		assert_status_code 1 "checkStringIsShortherThan '$stringToCheck' $((lengthToTest-1))"
		# single quotes around $stringToCheck because this can be an empty string
	done
	}

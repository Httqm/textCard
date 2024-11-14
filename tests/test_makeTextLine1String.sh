#!/usr/bin/env bash

# These are tests to be run with 'bash_unit'
#       https://github.com/pgrange/bash_unit
# To run tests :
#       path/to/bash_unit <thisFile>.sh

directoryOfThisScript="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$directoryOfThisScript/../config.sh"
source "$directoryOfThisScript/../textCard_functions.sh"


test_makeTextLine1String_generatedStringLength() {
	for position in left center right; do
		listOfLengthsToTest="0 $nbColumns "$(for i in {1..10}; do echo $(($RANDOM % nbColumns+1))' '; done)
#		echo $listOfLengthsToTest
		for lengthToTest in $listOfLengthsToTest; do
			textSample=$(repeatStringUpToNCharacters 'X' "$lengthToTest")
			output=$(makeTextLine1String '/dev/stdout' "$position" "$textSample")
#			echo "$position $lengthToTest [$output]"
			assert_equals "$nbColumns" "${#output}"
		done
	done
	}


test_makeTextLine1String_inputStringTooLong() {
	# I must get an error if "<textSample>" is longer that "$nbColumns"
	lengthOfTooLongString=$((nbColumns+1))
#	lengthOfTooLongString=11	# with '11', the test "fails at failing"

	textSample=$(repeatStringUpToNCharacters 'X' "$lengthOfTooLongString")
	# This is tested before checking the left/center/right, hence "whatever"
	assert_status_code 1 "makeTextLine1String '/dev/stdout' whatever $textSample"
	}


test_makeTextLine1String_left() {
	# I must get "<textSample><padding up to nbColumns>"
	listOfLengthsToTest="0 $nbColumns "$(for i in {1..10}; do echo $(($RANDOM % nbColumns+1))' '; done)
	for lengthToTest in $listOfLengthsToTest; do
		textSample=$(repeatStringUpToNCharacters 'X' "$lengthToTest")
		textSampleLength=${#textSample}
		padding=$((nbColumns-textSampleLength))
		expected="$textSample"$(repeatStringUpToNCharacters "$blankCharacter" "$padding")
		output=$(makeTextLine1String '/dev/stdout' 'left' "$textSample")
#		echo "$lengthToTest [$output]"
		assert_equals "$expected" "$output"
	done
	}


test_makeTextLine1String_right() {
	# I must get "<padding up to nbColumns><textSample>"
	listOfLengthsToTest="0 $nbColumns "$(for i in {1..10}; do echo $(($RANDOM % nbColumns+1))' '; done)
	for lengthToTest in $listOfLengthsToTest; do
		textSample=$(repeatStringUpToNCharacters 'X' "$lengthToTest")
		textSampleLength=${#textSample}
		padding=$((nbColumns-textSampleLength))
		expected="$(repeatStringUpToNCharacters "$blankCharacter" "$padding")$textSample"
		output=$(makeTextLine1String '/dev/stdout' 'right' "$textSample")
#		echo "$lengthToTest [$output]"
		assert_equals "$expected" "$output"
	done
	}


test_makeTextLine1String_center() {
	# I must get "<padding left><textSample><padding right>"
	listOfLengthsToTest="0 $nbColumns "$(for i in {1..10}; do echo $(($RANDOM % nbColumns+1))' '; done)
	for lengthToTest in $listOfLengthsToTest; do
		textSample=$(repeatStringUpToNCharacters 'X' "$lengthToTest")
		textSampleLength=${#textSample}
		leftPadding=$(((nbColumns+1-textSampleLength)/2))
		rightPadding=$((nbColumns-textSampleLength-leftPadding))
		expected="$(repeatStringUpToNCharacters "$blankCharacter" "$leftPadding")$textSample$(repeatStringUpToNCharacters "$blankCharacter" "$rightPadding")"
		output=$(makeTextLine1String '/dev/stdout' 'center' "$textSample")
#		echo "$lengthToTest [$output]"
		assert_equals "$expected" "$output"
	done
	}

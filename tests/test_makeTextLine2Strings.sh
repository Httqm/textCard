#!/usr/bin/env bash

# These are tests to be run with 'bash_unit'
#       https://github.com/pgrange/bash_unit
# To run tests :
#       path/to/bash_unit <thisFile>.sh

directoryOfThisScript="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
for functionFile in config.sh textCard_functions.sh functions.sh; do
	source "$directoryOfThisScript/../$functionFile"
done


test_makeTextLine2Strings_nonEmptyString() {
	# 'makeTextLine2Strings' is designed to output "<left><padding><right>".
	# Calling it with either '<left>' or '<right>' string being empty is useless since
	# 'makeTextLine1String' can already handle this with 'left|right' parameter.
	# Since supporting exceptions implies more code + more tests = more bugs, it's disabled.
	while read stringLeft stringRight; do
		textLeft=$(repeatStringUpToNCharacters 'L' "$length1")
		textRight=$(repeatStringUpToNCharacters 'R' "$length2")
		output=$(makeTextLine2Strings '/dev/stdout' 'whatever' "$textLeft" "$textRight")
#		echo "$position $length1 $length2 [$output]"
		# This is tested before checking the 'leftright/other', hence "whatever"
		assert_status_code 1 "makeTextLine2Strings '/dev/stdout' 'whatever' $stringLeft $stringRight"
	done < <(cat <<-EOF
		left	''
		''		right
		EOF
		)
	}


test_makeTextLine2Strings_generatedStringLength() {
	# checking the generated string has always "$nbColumn" characters
	for position in leftright; do
		while read lengthLeft lengthRight; do
			[ "$lengthLeft"  -eq 0 ] && lengthLeft=1
			[ "$lengthRight" -eq 0 ] && lengthRight=1
			textLeft=$(repeatStringUpToNCharacters 'L' "$lengthLeft")
			textRight=$(repeatStringUpToNCharacters 'R' "$lengthRight")
			output=$(makeTextLine2Strings '/dev/stdout' "$position" "$textLeft" "$textRight")
#			echo "$position $lengthLeft $lengthRight [$output]"
			assert_equals "$nbColumns" "${#output}"
		done < <(cat <<-EOF
			$((nbColumns/2))				$(((nbColumns/2)+(nbColumns % 2)))
			$((RANDOM % (nbColumns/2)))		$((RANDOM % (nbColumns/2)))
			$((RANDOM % (nbColumns/2)))		$((RANDOM % (nbColumns/2)))
			$((RANDOM % (nbColumns/2)))		$((RANDOM % (nbColumns/2)))
			EOF
			)
	done
	}


test_makeTextLine2Strings_inputStringsTooLong() {
	# I must get an error if the total length of the 2 strings is longer that "$nbColumns"

	# 'makeTextLine2Strings' checks the string length by calling 'checkStringIsShortherThan'.
	# When the padding width is null or unspecified, 'checkStringIsShortherThan' searches the
	# corresponding line in '$inputFile', to output "Error in '$inputFile' at line X"
	# This is performed with "grep <options> $inputFile | ...". But since unit tests use
	# no input file, there is nothing to 'grep' into, hence the error :
	#	grep: : No such file or directory
	# This hack is to avoid it.
	inputFile='/dev/null'

	while read lengthLeft lengthRight; do
		textLeft=$(repeatStringUpToNCharacters 'L' "$lengthLeft")
		textRight=$(repeatStringUpToNCharacters 'R' "$lengthRight")
		output=$(makeTextLine2Strings '/dev/stdout' 'whatever' "$textLeft" "$textRight")
#		echo "$position $lengthLeft $lengthRight [$output]"
		# This is tested before checking the left/center/right, hence "whatever"
		assert_status_code 1 "makeTextLine2Strings '/dev/stdout' 'whatever' $textLeft $textRight"
	done < <(cat <<-EOF
		0							$((nbColumns+1))
		$((nbColumns+1)) 			0
		$(((nbColumns/2)+1))		$(((nbColumns/2)+1))
		$(((nbColumns/2)-1))		$(((nbColumns/2)+2))
		$(((nbColumns/2)+2))		$(((nbColumns/2)-1))
		EOF
		)
	}


test_makeTextLine2Strings_leftright() {
	# I must get "<left><padding><right>"
	while read lengthLeft lengthRight; do
		[ "$lengthLeft" -eq 0 ] && lengthLeft=1
		[ "$lengthRight" -eq 0 ] && lengthRight=1
		textLeft=$(repeatStringUpToNCharacters 'L' "$lengthLeft")
		textRight=$(repeatStringUpToNCharacters 'R' "$lengthRight")
		padding=$(repeatStringUpToNCharacters "$blankCharacter" $((nbColumns-lengthLeft-lengthRight)))
		expected="$textLeft$padding$textRight"
		output=$(makeTextLine2Strings '/dev/stdout' 'leftright' "$textLeft" "$textRight")
#		echo "expected: '$expected', output: '$output'"
		assert_equals "$expected" "$output"
	done < <(cat <<-EOF
		$((RANDOM % (nbColumns/2)))		$((RANDOM % (nbColumns/2)))
		$((RANDOM % (nbColumns/2)))		$((RANDOM % (nbColumns/2)))
		$((RANDOM % (nbColumns/2)))		$((RANDOM % (nbColumns/2)))
		EOF
		)
	}

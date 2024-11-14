#!/usr/bin/env bash

# These are tests to be run with 'bash_unit'
#       https://github.com/pgrange/bash_unit
# To run tests :
#       path/to/bash_unit <thisFile>.sh

directoryOfThisScript="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
for functionFile in config.sh textCard_functions.sh functions.sh; do
	source "$directoryOfThisScript/../$functionFile"
done


# 'makeTextLinePadded' checks the string length by calling 'checkStringIsShortherThan'.
# When the padding width is null or unspecified, 'checkStringIsShortherThan' searches the
# corresponding line in '$inputFile', to output "Error in '$inputFile' at line X"
# This is performed with "grep <options> $inputFile | ...". But since unit tests use
# no input file, there is nothing to 'grep' into, hence the error :
#	grep: : No such file or directory
# This hack is to avoid it.
inputFile='/dev/null'


test_makeTextLinePadded_inputStringTooLong() {
	# I must get an error if the total length of (padding + string) is longer that "$nbColumns"
	while read lengthPadding lengthString; do
		string=$(repeatStringUpToNCharacters 'S' "$lengthString")
		output=$(makeTextLinePadded '/dev/stdout' 'whatever' "$string" "$lengthPadding" '_')
#		echo "$lengthPadding $lengthString [$output]"
		# This is tested before checking the left/right, hence "whatever"
		assert_status_code 1 "makeTextLinePadded '/dev/stdout' 'whateverPosition' \"$string\" \"$lengthPadding\" '_'"
	done < <(cat <<-EOF
		0							$((nbColumns+1))
		$((nbColumns+1)) 			0
		$(((nbColumns/2)+1))		$(((nbColumns/2)+1))
		$(((nbColumns/2)-1))		$(((nbColumns/2)+2))
		$(((nbColumns/2)+2))		$(((nbColumns/2)-1))
		EOF
		)
	}


test_makeTextLinePadded_nullPaddingWidthForbidden() {
	# Using 'padded|left' or 'padded|right' with a null padding width is the same than using
	# '1string|left' or '1string|right' directly, and is forbidden.
	# Just checking this is enforced.
	assert_status_code 1 "makeTextLinePadded '/dev/stdout' 'whateverPosition' 'whateverString' 0 _"
	}


test_makeTextLinePadded_stringPlusPaddingLengthEqualNbColumns() {
	# 'makeTextLinePadded' generates :
	#	"<padding><myString><restOfLinePadding>" with position 'left'
	#	"<restOfLinePadding><myString><padding>" with position 'right'
	# If "<restOfLinePadding>" becomes empty because length of ('string' and 'padding') == nbColumns,
	# this is equal to using '1string|left' or '1string|right', which is forbidden.
	# Just checking this is enforced.
	for position in left right; do
		for i in {0..5}; do
			lengthString=$((RANDOM % nbColumns))
			lengthPadding=$((nbColumns-lengthString))
#			[ "$lengthPadding" -eq 0 ] && lengthPadding=1	# avoid the 'null padding' error, tested above
			string=$(repeatStringUpToNCharacters 'S' "$lengthString")
#			echo "$position $lengthString $lengthPadding $((nbColumns-lengthString-lengthPadding))"
			assert_status_code 1 "makeTextLinePadded '/dev/stdout' \"$position\" \"$string\" \"$lengthPadding\" '_'"
		done
	done
	}

test_makeTextLinePadded_generatedStringLength() {
	# checking the generated string has always "$nbColumn" characters
	for position in left right; do
		for i in {0..5}; do
			lengthString=$((RANDOM % (nbColumns/2)))
			lengthPadding=$((RANDOM % (nbColumns/2)))
			[ "$lengthPadding" -eq 0 ] && lengthPadding=1	# avoid the 'null padding' error, tested above
			string=$(repeatStringUpToNCharacters 'S' "$lengthString")
			output=$(makeTextLinePadded '/dev/stdout' "$position" "$string" "$lengthPadding" '_')
#			echo "$position $lengthString $lengthPadding [$output]"
			assert_equals "$nbColumns" "${#output}"
		done
	done
	}


#test_makeTextLinePadded_nonEmptyString() {
#	# 'makeTextLinePadded' is designed to output "<left><padding><right>".
#	# Calling it with either '<left>' or '<right>' string being empty is useless since
#	# 'makeTextLine1String' can already handle this with 'left|right' parameter.
#	# Since supporting exceptions implies more code + more tests = more bugs, it's disabled.
#	while read stringLeft stringRight; do
#		textLeft=$(repeatStringUpToNCharacters 'X' "$length1")
#		textRight=$(repeatStringUpToNCharacters 'X' "$length2")
#		output=$(makeTextLinePadded '/dev/stdout' "$position" "$textLeft" "$textRight")
##		echo "$position $length1 $length2 [$output]"
#		# This is tested before checking the 'leftright/other', hence "whatever"
#		assert_status_code 1 "makeTextLinePadded whatever $stringLeft $stringRight"
#	done < <(cat <<-EOF
#		left	''
#		''		right
#		EOF
#		)
#	}
#
#
#test_makeTextLinePadded_leftright() {
#	# I must get "<left><padding><right>"
#	while read lengthLeft lengthRight; do
#		[ "$lengthLeft" -eq 0 ] && lengthLeft=1
#		[ "$lengthRight" -eq 0 ] && lengthRight=1
#		textLeft=$(repeatStringUpToNCharacters 'L' "$lengthLeft")
#		textRight=$(repeatStringUpToNCharacters 'R' "$lengthRight")
#		padding=$(repeatStringUpToNCharacters "$blankCharacter" $((nbColumns-lengthLeft-lengthRight)))
#		expected="$textLeft$padding$textRight"
#		output=$(makeTextLinePadded '/dev/stdout' 'leftright' "$textLeft" "$textRight")
##		echo "expected: '$expected', output: '$output'"
#		assert_equals "$expected" "$output"
#	done < <(cat <<-EOF
#		$((RANDOM % (nbColumns/2)))		$((RANDOM % (nbColumns/2)))
#		$((RANDOM % (nbColumns/2)))		$((RANDOM % (nbColumns/2)))
#		$((RANDOM % (nbColumns/2)))		$((RANDOM % (nbColumns/2)))
#		EOF
#		)
#	}

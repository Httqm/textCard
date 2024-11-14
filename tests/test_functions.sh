#!/usr/bin/env bash

# These are tests to be run with 'bash_unit'
#       https://github.com/pgrange/bash_unit
# To run tests :
#       path/to/bash_unit <thisFile>.sh

directoryOfThisScript="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$directoryOfThisScript/../functions.sh"


test_abs() {
	while read input expectedOutput; do
#		echo "testing '$input'"
		assert_equals "$(abs $input)" "$expectedOutput"
	done < <(cat <<-EOF
		123456	123456
		12345	12345
		1234	1234
		123		123
		12		12
		1		1
		0		0
		-0		0
		-1		1
		-12		12
		-123	123
		-1234	1234
		-12345	12345
		-123456	123456
		EOF
		)
	}


test_message_ok() {
	expected='[1;32m✅ Everything is going extremely well.[0m'
	# get this by running "./functions_test.sh > test.txt" and copy the result from test.txt

	output=$(message ok 'Everything is going extremely well.')
	assert_equals "$expected" "$output"
	}


test_message_error() {
	expected='[1;31m🚩 You Shall Not Pass![0m'
	output=$(message error 'You Shall Not Pass!')
	assert_equals "$expected" "$output"
	}


test_message_info() {
	expected='[1;36mℹ️ The answer to the Great Question is 42.[0m'
	output=$(message info 'The answer to the Great Question is 42.')
	assert_equals "$expected" "$output"
	}


test_message_warning() {
	expected='[1;33m⚠️ Houston, we have a problem.[0m'
	output=$(message warning 'Houston, we have a problem.')
	assert_equals "$expected" "$output"
	}


test_message_default() {
	expected='[1;37m😲️ Messages with an unknown type will be displayed like this.[0m'
	output=$(message default 'Messages with an unknown type will be displayed like this.')
	assert_equals "$expected" "$output"
	}

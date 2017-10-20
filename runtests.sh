#!/bin/bash

# =========== CONSTANTS ===========
# Return values
readonly RET_success=0
readonly RET_error=1
readonly RET_usage=2
readonly RET_help=2

# Colors
readonly RCol='\033[0m'         # Text Reset
readonly Whi='\033[0;37m'       # White, for small details
readonly Red='\033[0;31m'       # Red, for small details
readonly Gre='\033[0;32m'       # Green, for small details
readonly Yel='\033[0;33m'       # Yellow, for mid-building
readonly BRed='\033[1;31m'      # Bold Red, when an error occurred
readonly BGre='\033[1;32m'      # Bold Green, for successes
readonly BYel='\033[1;33m'      # Bold Yellow, when building stuff
readonly BWhi='\033[1;37m'      # Bold White, when beginning something
readonly URed='\033[4;31m'      # Underline Red, for warnings
readonly UGre='\033[4;32m'      # Underline Green, for smaller successes
readonly UBlu='\033[4;34m'      # Underline Blue, for links
readonly UWhi='\033[4;37m'      # Underline White, for commands

# Strings
readonly Note="${UWhi}Notice${Whi}:${RCol}"
readonly Warn="${BYel}Warning${Yel}:${RCol}"
readonly Err="${BRed}Error${Red}:${RCol}"

readonly ScriptName="$0"

# String Arrays
readonly usage_content=( "Usage: $(basename $ScriptName)"
"HELP:
	-h : Shows this message"
"DIRECTORIES:
	-t : Set tests directory"
"OPTIONS:
	-r : If -t was set, then -r sets recursivity of the given directory
	--show-all : Prints successes as well"
)

# Files & Directories
readonly DIR_current="$(pwd)"

# Options
BOOL_recursive=false
BOOL_showAll=false

# =========== FUNCTIONS ===========
function usage {
	for i in `seq 0 ${#usage_content[@]}`; do
		echo -e "${usage_content[i]}"
	done
    exit $RET_usage
}

function get_absolute_dir {
	# $1 : directory to parse
	cd "$1" > /dev/null
	temp_dir="$(pwd)"
	cd - > /dev/null
	echo "$temp_dir"
}

function parse_args {
	if [ $# -eq 0 ]; then return 0; fi

	while [ $# -gt 0 ]; do
		case $1 in
			# DIRECTORIES
			-t )
				shift
				DIR_tests="$(get_absolute_dir "$1")"
				;;
			# OPTIONS
			--show-all )
				BOOL_showAll=true
				;;
			-r )
				BOOL_recursive=true
				;;
			# HELP
			-h|--help )
				usage
				exit $RET_usage
				;;
			* ) printf "Unknown argument. \"$1\"\n"
				;;
		esac
		shift
	done

	return $RET_success
}

function print_progress {
	# $1 : text to print
	# $2+: formatting args
	printf "\n${BYel}$1\n${RCol}" ${@:2}
}
function print_success {
	# $1 : text to print
	# $2+: formatting args
	printf "\n${UGre}SUCCESS${Gre}:${RCol} $1\n${RCol}" ${@:2}
}
function print_failure {
	# $1 : text to print
	# $2+: formatting args
	printf "\n${URed}FAILURE${Red}:${RCol} $1\n" ${@:2}
}
function print_error {
	# $1 : text to print
	# $2+: formatting args
	printf "\n${BRed}ERROR${Red}:${RCol} $1\n" ${@:2}
}

function check_env {
	if [ $BOOL_recursive == false -a ! -d "$DIR_tests" ]; then
		print_error "Tests directory \"$DIR_tests\" is not valid"
		return $RET_error
	fi
}

function set_env {
	# Defining script directories
	cd "$(dirname "$0")"
	DIR_script="$(pwd)"

	if [ -z "$DIR_exec" ]; then
		DIR_exec="$DIR_script/src"
	fi
	cd "$DIR_exec"

	if [ ! -d "$DIR_tests" ]; then
		DIR_tests="$DIR_script/tests_mooshak"
		BOOL_recursive=true
	fi
}

# Target functionality
function test_dir {
	# $1 : test directory
	if [ $# -lt 1 ]; then
		print_error "test_dir\(): No arguments given."
		return $RET_error
	elif [ ! -d "$1" ]; then
		print_error "Given argument is not a directory."
		return $RET_error
	elif [ -z "$(ls $1/input 2> /dev/null)" -o -z "$(ls $1/output 2> /dev/null)" ]; then
		print_error "Given directory does not contain any test files."
		return $RET_error
	fi

	# Run tests
	local test_name="$1/input"
	local test_output="$1/output"
	local test_outhyp="$1/outhyp"
	local test_errors="$1/errors.log"
	local test_diff="$1/result.diff"

	python3 -c "from same_game import *; $(cat $test_name)" > "$test_outhyp" 2> "$test_errors"
	local error=$?
    diff $test_output $test_outhyp > $test_diff
	if [ $error -ne 0 ]; then
		print_failure "Runtime error. Check errors.log"
		return 1
	elif [ -s $test_diff ]; then
        print_failure "Wrong answer. Check result.diff"
		return 2
    else
		if [ $BOOL_showAll == true ]; then
			print_success "$test_name"
		fi
        rm -f *.diff $test_outhyp
    fi

	return 0
}

function cleanup {
	:
}

function main {
	parse_args "$@"
	set_env
	check_env
	if [ $? -eq $RET_error ]; then
		usage
		exit $RET_error
	fi

	local retval=$RET_success
	local fail_count=0

	if [ $BOOL_recursive == true ]; then
		local error=0
		local runtime_error=0
		local wrong_answer=0

		for x in $DIR_tests/*/; do
			print_progress "Running through \"$x\""
			test_dir "$x"
			error=$?
			if [ $error -eq 1 ]; then
				runtime_error=$(($runtime_error + 1))
			elif [ $error -eq 2 ]; then
				wrong_answer=$(($wrong_answer + 1))
			fi
			total_count=$(($total_count + 1))
		done

		fail_count=$(($runtime_error + $wrong_answer))

		if [ $fail_count -gt 0 ]; then
			print_failure "\n$runtime_error Runtime Errors\n$wrong_answer Wrong Answers"
			printf "Total: $fail_count / $total_count tests.\n"
		fi
	else
		test_dir "$DIR_tests"
		fail_count=$?
	fi
	cleanup

	exit $fail_count
}

# Script starts HERE
main "$@"
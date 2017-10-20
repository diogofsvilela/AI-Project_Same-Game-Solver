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

# Python printing line to use with our tests
readonly print_msg="print(\"n actions: \" + str(problem.succs) + \"  n result: \" + str(problem.states) + \"  n goal_test: \" + str(problem.goal_tests))"

# String Arrays
readonly usage_content=( "Usage: $(basename $ScriptName)"
"HELP:
	-h : Shows this message"
"FILES & DIRECTORIES:
	-d : Set tests directory
	-t : Set the single test to run"
"OPTIONS:
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
			# FILES & DIRECTORIES
			-d )
				shift
				DIR_tests="$(get_absolute_dir "$1")"
				;;
			-t )
				shift
				DIR_tests="$(get_absolute_dir "$(dirname $1)")"
				FILE_testName="$DIR_tests/$(basename $1)"
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

	# Defining tests
	DIR_tests="$DIR_script/tests_benchmark"
}

# Target functionality
search_algorithms=(
"depth_first_tree_search"
"greedy_best_first_graph_search"
"astar_search"
)

function test_single {
	# $1 : test to run
	local test_input="$1"
	local test_errors="${test_input%.in}.log"
	local error=0

	local board="$(cat $test_input)"

	for algo in ${search_algorithms[@]}; do
		print_progress "Running $algo over $test_input..."
		local test_output="${test_input%.in}.$algo.outhyp"

		local cmd=""
		if [ $(echo $algo | grep "greedy_best_first_graph_search") ]; then
			cmd="problem = InstrumentedProblem(same_game($board)); $algo(problem, problem.h); $print_msg"
		else
			cmd="problem = InstrumentedProblem(same_game($board)); $algo(problem); $print_msg"
		fi

		time python3 -c "from same_game import *; $cmd" > "$test_output" 2> "$test_errors"
		error=$?
		if [ $error -ne 0 ]; then
			print_failure "Runtime error. Check $test_errors"
			exit
		fi
	done
}

function test_dir {
	# $1 : test directory
	if [ $# -lt 1 ]; then
		print_error "test_dir\(): No arguments given."
		return $RET_error
	elif [ ! -d "$1" ]; then
		print_error "Given argument is not a directory."
		return $RET_error
	elif [ -z "$(ls $1/*.in 2> /dev/null)" ]; then
		print_error "Given directory does not contain any test files."
		return $RET_error
	fi

	# Run tests
	for i $(seq 5)
		for test_input in $1/*.in; do
			test_single $test_input
			echo "__________________________________"
		done
	done
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

	if [ -z "$FILE_testName" ]; then
		test_dir "$DIR_tests"
		retval=$?
	else
		test_single "$FILE_testName"
		retval=$?
	fi

	cleanup
	exit $retval
}

# Script starts HERE
main "$@"

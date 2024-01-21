==#!/bin/bash

#########################################
#
#	C Testing Framwork
#
#########################################

###############################################################################
# Terminal colors
###############################################################################
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RESET='\033[0m' # Reset color to default

###############################################################################
# Script global variables
###############################################################################
COMPILER="gcc"
FLAGS="-Wall -g"
OUTDIR="Output"
EXECUTE="./"

###############################################################################
# Default values for flags
###############################################################################
verbose=false
clean=false

###############################################################################
# C source code compilation
###############################################################################

compile_file() {

	# Getting file and path values
	base_name=$(basename "$1" .c)
	src_name=$1
	exec_name=$OUTDIR/$base_name
	ref_name="$base_name.ref"
	log_name="$base_name.log"

	#
	# Compile
	#
	$verbose && echo -e "\nCompiling file ${src_name}"
	$verbose && echo "$COMPILER $FLAGS -o $exec_name $src_name"

	$COMPILER $FLAGS -o $exec_name $src_name > $log_name 2>&1
	compile_code=$?

	# Validate compile code and i
	#nspect run exit code and print message (run ok/ run not ok)

	if [ $compile_code -eq 0 ];
	then
		$verbose && echo -e "${GREEN}File compiled successfully.\nExecutable file run successfully with output:${RESET}"
		exec_result=$($EXECUTE$exec_name)
		echo ${exec_result} > $log_name
		$verbose && cat $log_name
	else
		$verbose && echo -e "${RED}Compilation error...${RESET}"
		echo -e "${RED}"
		cat $log_name
		rm $log_name
		echo -e "${RESET}"
	fi

	# Check if ref name file exist
	# - (if not): print message that cannot validate executable output
	# - (if found): diff between ref_name and log_name
	if [ -e "$ref_name" ];
	then
		$verbose && echo -e "${YELLOW}Successfully found .ref file${RESET}"
		diff $ref_name $log_name
		# Check if diff works
		if [ $? -eq 0 ];
		then
			$verbose && echo "No difference between output and ref files"
		else
			$verbose && echo "output and ref files are different."
		fi
	else
		$verbose && echo -e "${YELLOW}Ref file doesnt exists.\nCannot compare output with the ref file${RESET}"
	fi

	# Remove log name
	if [ -e "$log_name" ];
	then
		rm $log_name
		if [ $? -eq 0 ];
		then
			$verbose && echo -e "Output file successfully deleted\n"
		fi
	fi
}

###############################################################################
# Function for searching recursively .c files inside directory
###############################################################################

build_files() {

	# Find recursively subdirectories for the base folder
	subdirectories=$(find "$1" -type d)

	# Iterate through the each subdirectory
	for dir in $subdirectories;
	do
		$verbose && echo -e "\n\n${GREEN}Checking directory: $dir${RESET}"

		# Move to subdirectory
		cd $dir

		# Iterate through c source file
		for file in *;
		do
			if [[ -f "$file" && "$(basename "$file")" == *.c ]];
			then
				mkdir -p $OUTDIR >/dev/null 2>&1
				compile_file "$file"
			fi
		done

		# Move back to root directory
		cd - > /dev/null
	done
}


###############################################################################
# Functio call on '-c' option and remove all 'Output' directories
###############################################################################

clean_files() {
	$verbose && echo -e "${YELLOW}Cleaning Output directories...${RESET}"

	# Find recursively all Output directories
	subdirectories=$(find "$1" -type d -name "$OUTDIR")

	# Iterate through each Output directory and remove it
	for outdir in $subdirectories;
	do
		$verbose && echo -e "\n\n${GREEN}Checking Output directory: $outdir${RESET}"

		if [ -d "$outdir" ];
		then
			rm -rf "$outdir" >/dev/null 2>&1
			rm_code=$?

			if [ $rm_code -eq 0 ];
			then
				$verbose && echo -e "${GREEN}Output directory $outdir cleaned successfully.${RESET}"
			else
				$verbose && echo -e "${RED}Failed to clean Output directory $outdir.${RESET}"
			fi
		fi
	done
}


###############################################################################
# Script entrypoint
###############################################################################

while getopts ":d:c:hv" opt;
do
	case ${opt} in
		d)
			# Do something when -d option is specified
			directory="${OPTARG}"
			if [ -n "$directory" ];
			then
				if [ -d "$directory" ];
				then
					build_files "$directory"
				else
					echo "Error: '$directory' is not a valid directory." >&2
					exit 1
				fi
			else
				echo "Error: -d option requires a directory argument." >&2
				exit 1
			fi
      			;;
		h)
			# Display help message
			echo -e "Usage: $0 [-v] [-d <lookup_dir>] [-c] [-h]\n"
			echo -e "	-v: Enable verbose mode."
			echo -e "	-d <lookup_dir>: Directory for recursively lookup of c source code."
			echo -e "	-h: Display help message."
			echo -e "	-c: Clean Output directories."
			exit 0
			;;
		v)
			# Verbose mode
			verbose=true
			echo "Verbose: $verbose"
			;;
		c)
			# Clean Output/ folder
			clean_directory="${OPTARG}"

			if [ -n "$clean_directory" ];
			then
				if [ -d "$clean_directory" ] ;
				then
					clean_files "$clean_directory"
				else
					$verbose && echo -e "${RED}${clean_directory} not a directory${RESET}"
				fi
			fi
			exit 0
			;;
		\?)
			echo "Invalid option: -$OPTARG" >&2
			exit 1
			;;
		:)
			echo "Option -$OPTARG requires an argument." >&2
			exit 1
			;;
	esac
done


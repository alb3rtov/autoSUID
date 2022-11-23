#!/bin/bash
#
# Author: alb3rtov
#
# Descrition:
# This script allows you to find and enumerate SUID binaries and check if one of them
# can be used to escalate or mantain elevated privileges in a iteractive way.
#

# Run BLA::stop_loading_animation if the script is interrupted
trap BLA::stop_loading_animation SIGINT

# Loading animation
BLA_classic=(0.25 '-' "\\" '|' '/')

# Colors ANSI escape codes
DARKGRAY='\033[1;30m'
LIGHTRED='\033[1;31m'
LIGHTGREEN='\033[1;32m'
YELLOW='\033[1;33m'
LIGHTBLUE='\033[1;34m'
LIGHTPURPLE='\033[1;35m'
LIGHTCYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Global variables
declare -a exploitable_binaries
declare -a url_exploitable_binaries
declare -a limited_exploitable_binaries
declare -a limited_url_exploitable_binaries
declare -a suid_urls
declare -a limited_suid_urls
declare -i bin_index
declare -i selected_menu
declare -a BLA_active_loading_animation

# Catch Ctrl+C signal
function ctrl_c() {
	echo -e "\n${YELLOW}[*] Ctrl+C signal caught...\n${NC}"
	rm output.html tmp.html 2>/dev/null
	tput cnorm
	exit 1
}

trap ctrl_c INT

# Play loading animation
BLA::play_loading_animation_loop() {
	while true; do
		for frame in "${BLA_active_loading_animation[@]}"; do
			printf "\r[%s" "${frame}"
			sleep "${BLA_loading_animation_frame_interval}"
		done
	done
}

# Start loading animation
BLA::start_loading_animation() {
	BLA_active_loading_animation=("${@}")
	# Extract the delay between each frame from array BLA_active_loading_animation
	BLA_loading_animation_frame_interval="${BLA_active_loading_animation[0]}"
	unset "BLA_active_loading_animation[0]"
	tput civis # Hide the terminal cursor
	BLA::play_loading_animation_loop &
	BLA_loading_animation_pid="${!}"
}

# Stop loading animation
BLA::stop_loading_animation() {
	kill "${BLA_loading_animation_pid}" &>/dev/null
	printf "\r[*"
	printf "\n"
	tput cnorm # Restore the terminal cursor
}

# Press enter to continue
function enter_press() {
	echo -ne "${YELLOW}\nPress enter to continue...${NC}"
	read press_enter
}

# Check tools installed
function check_dependencies() {
	clear

	echo -ne "${YELLOW}\n[*] Checking for dependencies..."

	BLA::start_loading_animation "${BLA_classic[@]}"
	sleep 2
	BLA::stop_loading_animation

	content_retriever=""
	mode=""

	if test -f $(which curl); then
		echo -e "${YELLOW}\n[*] Curl is installed on the system (${NC}${LIGHTGREEN}V${NC}${YELLOW})${NC}"
		content_retriever="curl"
		sleep 2
	elif test -f $(which wget); then
		echo -e "${YELLOW}\n[*] Wget is installed on the system (${NC}${LIGHTGREEN}V${NC}${YELLOW})${NC}"
		content_retriever="wget"
		sleep 2
	else
		echo -e "${YELLOW}\n[*] Curl or wget are NOT installed on the system, exiting... (${NC}${LIGHTRED}X${NC}${YELLOW})${NC}"
		sleep 2
		tput cnorm
		exit 1
	fi

	if ! test -f $(which html2text); then
		echo -e "${YELLOW}\n[Optional] Html2text is installed on the system (${NC}${LIGHTGREEN}V${NC}${YELLOW})${NC}"
		sleep 2
		mode=0
	elif ! test -f $(which w3m); then
		echo -e "${YELLOW}\n[Optional] W3m is installed on the system (${NC}${LIGHTGREEN}V${NC}${YELLOW})${NC}"
		sleep 2
		mode=1
	else
		echo -e "${YELLOW}\n[Optional] W3m is NOT installed on the system (${NC}${LIGHTRED}X${NC}${YELLOW})${NC}"
		sleep 2
		mode=2
	fi
}

# Search and compare GTFO binaries with current SUID binaries
function search_binaries() {
	echo -ne "${YELLOW}\n[*] Searching for SUID vulnerable binaries in the system..."

	BLA::start_loading_animation "${BLA_classic[@]}"
	BLA::stop_loading_animation

	echo -e ""

	declare -a suid_binaries=$(find / -xdev -user root \( -perm -4000 -o -perm -2000 \) 2>/dev/null | grep -o '[^/]\+$')

	for binary_url in ${suid_urls[@]}; do
		current_binary=$(echo $binary_url | sed 's/\/#suid//' | sed 's/\/gtfobins\///')

		for binary in ${suid_binaries[@]}; do
			if [[ $current_binary == $binary ]]; then
				echo -e "${YELLOW}[*] SUID permissions match for ${NC}${LIGHTPURPLE}$binary${NC}"
				exploitable_binaries+=($(which $binary))
				url_exploitable_binaries+=($binary_url)
			fi
		done
	done

	echo -e ""

	for binary_url in ${limited_suid_urls[@]}; do
		current_binary=$(echo $binary_url | sed 's/\/#limited-suid//' | sed 's/\/gtfobins\///')

		for binary in ${suid_binaries[@]}; do
			if [[ $current_binary == $binary ]]; then
				echo -e "${YELLOW}[*] Limited SUID permissions match for ${NC}${LIGHTPURPLE}$binary${NC}"
				limited_exploitable_binaries+=($(which $binary))
				limited_url_exploitable_binaries+=($binary_url)
			fi
		done
	done

	if [ ${#exploitable_binaries[@]} -eq 0 ] && [ ${#limited_exploitable_binaries[@]} -eq 0 ]; then
		echo -e "${YELLOW}\n[*] SUID vulnerable binaries not found, exiting...\n${NC}"
		tput cnorm
		exit 0
	fi

	enter_press
	tput cnorm
}

# Display all vulnerable binaries
function display_menu() {
	clear
	echo -e "${YELLOW}\n[*] Vulnerable options\n${NC}"

	declare -i index=1

	if [ ${#exploitable_binaries[@]} -ne 0 ]; then
		echo -e "${YELLOW} $index) SUID binaries${NC}"
		let index+=1
	fi

	if [ ${#limited_exploitable_binaries[@]} -ne 0 ]; then
		echo -e "${YELLOW} $index) Limited SUID binaries${NC}"
		let index+=1
	fi

	let index-=1

	while
		echo -ne "${LIGHTBLUE}\nSelect an option (1-$index): ${NC}"
		read user_input
		(($user_input < 1 || $user_input > $index))
	do true; done

	selected_menu=$user_input

	if [ $user_input -eq 1 ]; then
		suid_binaries_menu
	else
		limited_suid_binaries_menu
	fi
}

# Show menu with limited SUID binaries to select
function limited_suid_binaries_menu() {
	clear
	echo -e "${YELLOW}\n[*] Limited SUID Binaries\n${NC}"

	declare -i index=1
	for binary in ${limited_exploitable_binaries[@]}; do
		echo -e "${YELLOW}  $index) $binary${NC}"
		let index+=1
	done

	while
		echo -ne "${LIGHTBLUE}\nSelect an option (1-${#limited_exploitable_binaries[@]}): ${NC}"
		read user_input
		(($user_input < 1 || $user_input > ${#limited_exploitable_binaries[@]}))
	do true; done

	let user_input-=1

	bin_index=$user_input
}

# Show menu with SUID binaries to select
function suid_binaries_menu() {
	clear
	echo -e "${YELLOW}\n[*] SUID Binaries\n${NC}"

	declare -i index=1
	for binary in ${exploitable_binaries[@]}; do
		echo -e "${YELLOW}  $index) $binary${NC}"
		let index+=1
	done

	while
		echo -ne "${LIGHTBLUE}\nSelect an option (1-${#exploitable_binaries[@]}): ${NC}"
		read user_input
		(($user_input < 1 || $user_input > ${#exploitable_binaries[@]}))
	do true; done

	let user_input-=1

	bin_index=$user_input
}

# Request to GTFObins info about selected SUID binary
function request_bin_info() {
	clear

	local arg1=$1
	local arg2=$2

	if [ $selected_menu -eq 1 ]; then
		selected_bin=${exploitable_binaries[${bin_index}]}
		url_selected_bin=${url_exploitable_binaries[${bin_index}]}
	else
		selected_bin=${limited_exploitable_binaries[${bin_index}]}
		url_selected_bin=${limited_url_exploitable_binaries[${bin_index}]}
	fi

	url="$arg1$url_selected_bin"

	echo -e "${YELLOW}\n[*] Searching info about $selected_bin... ${LIGHTPURPLE} ($url) ${NC}"

	if [ $arg2 == "curl" ]; then
		curl -s $url -X GET >output.html
	else
		wget -q $url -O output.html
	fi

	if test ! -f output.html; then
		echo -e "${LIGHTRED}\n[!] HTML file not found (output.html), exiting...\n${NC}"
		exit 1
	fi
}

# Fix command suggestion interpreting HTML code with w3m
function fixed_command() {
	local arg1=$1

	cmd=""
	num_lines=$(echo "$arg1" | wc -l)

	for i in $(seq 1 $num_lines); do
		cmd+=$(echo "$arg1" | sed -n $(echo $i)p | w3m -dump -T text/html)
		cmd+=$(echo "\n")
	done
}

# Get description and command for SUID binary exploitation
function extract_html_info() {

	local mode=$1

	if [ $mode -eq 0 ]; then # Html2text
		if [ $selected_menu -eq 1 ]; then
			description=$(html2text output.html | grep -F "***** SUID *****" -A 50 | sed -n '/^\*\*\*\*\* SUID \*\*\*\*\*$/,/^\*\*\*\*\* Sudo \*\*\*\*\*$/p' | sed '1d;$d' | grep "*" -B 50 | sed '/*/d' | sed -e 's/[ \t]*//')
			commands=$(html2text output.html | grep -F "***** SUID *****" -A 50 | sed -n '/^\*\*\*\*\* SUID \*\*\*\*\*$/,/^\*\*\*\*\* Sudo \*\*\*\*\*$/p' | sed '1d;$d' | grep "*" -A 50 | sed 's/*//' | sed -e 's/[ \t]*//')
		else
			description=$(html2text output.html | grep -F "***** Limited SUID *****" -A 50 | sed '1d;$d' | grep "*" -B 50 | sed '/*/d')
			commands=$(html2text output.html | grep -F "***** Limited SUID *****" -A 50 | sed '1d' | grep "*" -A 50 | sed 's/*//')
		fi
	else
		if [ $selected_menu -eq 1 ]; then
			description=$(cat output.html | grep -A 25 'id="suid"' | awk '/<p>/,/<\/p>/' | sed -e 's/<[^>]*>//g' | sed -e 's/[ \t]*//')
			commands=$(cat output.html | grep -A 25 'id="suid"' | awk '/<pre>/,/<\/pre>/' | sed -e 's/<[^>]*>//g' | sed -e 's/[ \t]*//')
		else
			description=$(cat output.html | grep -A 25 'id="limited-suid"' | awk '/<p>/,/<\/p>/' | sed -e 's/<[^>]*>//g' | sed -e 's/[ \t]*//')
			commands=$(cat output.html | grep -A 25 'id="limited-suid"' | awk '/<pre>/,/<\/pre>/' | sed -e 's/<[^>]*>//g' | sed -e 's/[ \t]*//')
		fi

		if [ $mode -eq 1 ]; then
			fixed_command "$commands"
			commands=$(echo $cmd)
		fi
	fi

	echo -e "${YELLOW}\n[*] Description${NC}"
	echo -e "${LIGHTBLUE}\n$description${NC}"
	echo -e "${YELLOW}\n[*] Commands${NC}"
	echo -e "${LIGHTPURPLE}\n$commands${NC}"
	enter_press
}

# Main function
function main() {
	tput civis
	wget -q --spider http://google.com # Check if there is internet connection

	if [ $? -eq 0 ]; then

		check_dependencies

		gtfo_url="https://gtfobins.github.io"

		if [ $content_retriever == "curl" ]; then
			suid_urls=$(curl -s $gtfo_url -X GET | grep "#suid" | sed 's/<li><a href="//' | sed 's/">SUID<\/a><\/li>//')
			limited_suid_urls=$(curl -s $gtfo_url -X GET | grep "#limited-suid" | sed 's/<li><a href="//' | sed 's/">Limited SUID<\/a><\/li>//')
		else
			wget -q $gtfo_url -O tmp.html
			suid_urls=$(cat tmp.html | grep "#suid" | sed 's/<li><a href="//' | sed 's/">SUID<\/a><\/li>//')
			limited_suid_urls=$(cat tmp.html | grep "#limited-suid" | sed 's/<li><a href="//' | sed 's/">Limited SUID<\/a><\/li>//')
			rm tmp.html 2>/dev/null
		fi

		if [ $mode -ne 255 ]; then
			search_binaries
			display_menu
			request_bin_info $gtfo_url $content_retriever
			extract_html_info $mode
			rm output.html 2>/dev/null
		fi
	else
		echo -e "${YELLOW}\n[*] No internet connection, exiting...\n${NC}"
		tput cnorm
	fi
}

main

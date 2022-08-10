#!/bin/bash
#
# Author: alb3rtov
#
# Descrition:
# This script allows you to find SUID binaries and check if one of them 
# can be used to escalate or mantain elevated privileges in a iteractive way.
#

# Run BLA::stop_loading_animation if the script is interrupted
trap BLA::stop_loading_animation SIGINT

# Loading animation
BLA_classic=( 0.25 '-' "\\" '|' '/' )

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
declare -a suid_urls
declare -i bin_index
declare -a BLA_active_loading_animation

# Catch Ctrl+C signal
function ctrl_c() {
	echo -e "\n${YELLOW}[*] Ctrl+C signal caught...\n${NC}"
	rm output.html 2> /dev/null
	tput cnorm
	exit 1
}

trap ctrl_c INT

# 
BLA::play_loading_animation_loop() {
  while true ; do
    for frame in "${BLA_active_loading_animation[@]}" ; do
      printf "\r[%s" "${frame}"
      sleep "${BLA_loading_animation_frame_interval}"
    done
  done
}

# 
BLA::start_loading_animation() {
  BLA_active_loading_animation=( "${@}" )
  # Extract the delay between each frame from array BLA_active_loading_animation
  BLA_loading_animation_frame_interval="${BLA_active_loading_animation[0]}"
  unset "BLA_active_loading_animation[0]"
  tput civis # Hide the terminal cursor
  BLA::play_loading_animation_loop &
  BLA_loading_animation_pid="${!}"
}

# 
BLA::stop_loading_animation() {
  kill "${BLA_loading_animation_pid}" &> /dev/null
  printf "\r[*"
  printf "\n"
  tput cnorm # Restore the terminal cursor
}


# Check if html2text is installed
function check_dependencies() {
	clear

	echo -ne "${YELLOW}\n[*] Checking for dependencies..."
	
        BLA::start_loading_animation "${BLA_classic[@]}"
        sleep 2	
	BLA::stop_loading_animation

        if test -f /usr/bin/html2text; then
		echo -e "${YELLOW}\n[*] Html2text is installed on the system (${NC}${LIGHTGREEN}V${NC}${YELLOW})${NC}"	
		sleep 2
	else
		echo -e "${YELLOW}\n[*] Html2text is NOT installed on the system.\n\n  [-] Type this command to install it: ${NC}${LIGHTBLUE}apt-get install html2text.\n${NC}" 
		sleep 2
		tput cnorm
		exit 0;
	fi
}

# Search and compare GTFO binaries with current SUID binaries
function search_binaries() {
	echo -ne "${YELLOW}\n[*] Searching for SUID vulnerable binaries in the system..."
        
        BLA::start_loading_animation "${BLA_classic[@]}"
	declare -a suid_binaries=$(find / -perm -4000 2> /dev/null | grep -o '[^/]\+$')
        BLA::stop_loading_animation
        
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
	
	if [[ ${#exploitable_binaries[@]} -eq 0 ]]; then
		echo -e "${YELLOW}\n[*] SUID vulnerable binaries not found, exiting...\n${NC}"
		tput cnorm
		exit 0
	fi

	sleep 2
	tput cnorm
}

# Show menu with SUID binaries to select
function display_menu() {
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
		(( $user_input < 1 || $user_input > ${#exploitable_binaries[@]} ))
	do true; done

	let user_input-=1

	bin_index=$user_input
}

# Request to GTFObins info about selected SUID binary
function request_bin_info() {
	clear
	
	selected_bin=${exploitable_binaries[${bin_index}]}
	url_selected_bin=${url_exploitable_binaries[${bin_index}]}
	url="$1$url_selected_bin"

	echo -e "${YELLOW}\n[*] Searching info about $selected_bin... ${NC}"
	
	curl -s $url -X GET > output.html

	if test ! -f output.html; then
		echo -e "${LIGHTRED}\n[!] HTML file not found (output.html), exiting...\n${NC}"
		exit 1
	fi
}

# Get description and command for SUID binary exploitation
function extract_html_info() {
	
	description=$(html2text output.html | grep -F "***** SUID *****" -A 50 | awk '/***** SUID *****/{flag=1}/***** Sudo *****/{flag=0}flag' | tail -n +2 | grep "*" -B 50 | sed '/*/d')
	commands=$(html2text output.html | grep -F "***** SUID *****" -A 50 | awk '/***** SUID *****/{flag=1}/***** Sudo *****/{flag=0}flag' | tail -n +2 | grep "*" -A 50 | sed 's/*//')

	echo -e "${YELLOW}\n[*] Description${NC}"
	echo -e "${LIGHTBLUE}\n$description${NC}"
	echo -e "${YELLOW}\n[*] Commands${NC}"
	echo -e "${LIGHTPURPLE}\n$commands${NC}"
	echo -ne "${YELLOW}\nPress any key to continue...${NC}"
	read press_enter
}

# Main function
function main() {
	tput civis
	wget -q --spider http://google.com
        
        if [ $? -eq 0 ]; then
	  gtfo_url="https://gtfobins.github.io"
          suid_urls=$(curl -s $gtfo_url -X GET | grep "#suid" | sed 's/<li><a href="//' | sed 's/">SUID<\/a><\/li>//')
	
	  check_dependencies
	  search_binaries
	  display_menu
	  request_bin_info $gtfo_url
	  extract_html_info	
	  rm output.html 2> /dev/null
        else
          echo -e "${YELLOW}\n[*] No internet connection, exiting...\n${NC}"
          tput cnorm
        fi
}

main

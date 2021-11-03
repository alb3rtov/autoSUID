#!/bin/bash
#
# Author: alb3rtov
#

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

function ctrl_c() {
	echo -e "\n${YELLOW}[*] Ctrl+C signal caught...\n${NC}"
	tput cnorm
	exit 1
}

trap ctrl_c INT

function search_binaries() {
	
	declare -a suid_binaries=$(find / -perm -4000 2> /dev/null | grep -o '[^/]\+$')

	for binary_url in ${suid_urls[@]}; do
		current_binary=$(echo $binary_url | sed 's/\/#suid//' | sed 's/\/gtfobins\///')
		
		for binary in ${suid_binaries[@]}; do
			if [[ $current_binary == $binary ]]; then
				echo -e "\n${YELLOW}[*] SUID permissions match for ${NC}${LIGHTPURPLE}$binary${NC}"
				exploitable_binaries+=($(which $binary))
				url_exploitable_binaries+=($binary_url)
			fi
		done
	done
	echo -e ""
	
	if [[ ${#exploitable_binaries[@]} -eq 0 ]]; then
		echo -e "${YELLOW}[*] SUID binaries not found, exiting...\n${NC}"
		tput cnorm
		exit 0
	fi
}

# Main function

tput civis

gtfo_url="https://gtfobins.github.io"

declare -a suid_urls=$(curl -s $gtfo_url -X GET | grep "#suid" | sed 's/<li><a href="//' | sed 's/">SUID<\/a><\/li>//')

search_binaries

tput cnorm

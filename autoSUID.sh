#!/bin/bash
# Author: alb3rtov

# Global variables
declare -a exploitable_binaries

function ctrl_c() {
	echo -e "\nCtrl+C signal caught...\n"
	exit 1
}

trap ctrl_c INT

function search_binaries() {
	
	declare -a suid_binaries=$(find / -perm -4000 2> /dev/null | grep -o '[^/]\+$')

	for binary_url in ${suid_urls[@]}; do
		current_binary=$(echo $binary_url | sed 's/\/#suid//' | sed 's/\/gtfobins\///')
		
		for binary in ${suid_binaries[@]}; do
			if [[ $current_binary == $binary ]]; then
				echo -e "[*] Match for $binary"
				exploitable_binaries+=($(which $binary))
			fi
		done
	done
	echo -e ""
	
	if [[ ${#exploitable_binaries[@]} -eq 0 ]]; then
		echo -e "[*] SUID binaries not found, exiting...\n"
		exit 0
	fi
	
	#for element in ${exploitable_binaries[@]}; do
	#	echo "$element"
	#done
}

# Main function

gtfo_url="https://gtfobins.github.io"

declare -a suid_urls=$(curl -s $gtfo_url -X GET | grep "#suid" | sed 's/<li><a href="//' | sed 's/">SUID<\/a><\/li>//')

search_binaries

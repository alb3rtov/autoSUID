#!/bin/bash

# Global variables
declare -a paths

function ctrl_c() {
	echo -e "\nCtrl+C signal caught...\n"
	exit 1
}

trap ctrl_c INT

# Main function

gtfo_url="https://gtfobins.github.io"

declare -r suid_urls=$(curl -s $gtfo_url -X GET | grep "#suid" | sed 's/<li><a href="//' | sed 's/">SUID<\/a><\/li>//')

for path in $(echo $suid_urls); do
	paths+=($path)
done

#for element in ${paths[@]}; do
#	echo $element
#done

#!/bin/bash

function ctrl_c() {
	echo -e "\nCtrl+C signal caught...\n"
	exit 1
}

trap ctrl_c INT

# Main function

gtfo_url="https://gtfobins.github.io"

suid_urls=$(curl -s $gtfo_url -X GET | grep "#suid")



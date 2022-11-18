# autoSUID
This script allows you to find SUID binaries and check if one of them can be used to escalate or mantain elevated privileges in a iteractive way. It compares the current SUID binaries on the system with the list of [GTFOBins](https://gtfobins.github.io/) and reports information about how to escalate privileges with those binaries.

## Optional Html2Text
In order to parse HTML code from GTFOBins, the program `html2text` is used. Otherwise, html information will be parsed using `sed` and `grep` and `awk` but maybe some characters will not be displayed correctly.

Type this command to install it:

    sudo apt update
    sudo apt-get install html2text

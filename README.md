# autoSUID
This script allows you to find and enumerate SUID binaries and check if one of them can be used to escalate or mantain elevated privileges in a iteractive way. It compares the current SUID binaries on the system with the list of [GTFOBins](https://gtfobins.github.io/) and reports information about how to escalate privileges with those binaries.

## Requirements
The only tool that is mandatory is `curl`, in order to make the GET requests to [GTFOBins](https://gtfobins.github.io/) page and get all the vulnerables SUID and limited SUID binaries.

## Optional tools
In order to parse HTML code from [GTFOBins](https://gtfobins.github.io/), the program `html2text` is used. If html2text is not installed on the system, the script will try parse HTML code with `w3m`, and if it is not installed either, the HTML information will be parsed using `sed` and `grep` and `awk` but maybe some characters will not be displayed correctly.

You can install those tools with following commands:
```ini
$ sudo apt-get install curl

# Optional tools
$ sudo apt-get install w3m
$ sudo apt-get install html2text
```
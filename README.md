# autoSUID
This script allows you to find SUID binaries and check if one of them can be used to escalate or mantain elevated privileges in a iteractive way. Compare the current SUID binaries in the system with the list of [GTFOBins](https://gtfobins.github.io/) and reports information about how to escalate privileges with such binaries.

In order to parse HTML code from GFTOBins, the program `html2text` is used. Type this command to install it:

    sudo apt update
    sudo apt-get install html2text

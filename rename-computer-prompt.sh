#!/bin/bash

# ################################################################################################################################################
#
# Script Name:  Rename Computer
#
# Author:       Adam Williams
# Date:         07/06/2020
# Version:      1.3
#
# Purpose:      Prompts the user for a new computer name.
#
# Changes:      - 07/06/2020
#                   - Script creation
# ##################################################################################################################################

function askForCompName ()
{

## Capture the user input into a variable
COMPNAME=$(/usr/bin/osascript << EOF
tell application "System Events"
    activate
    display dialog "Enter in new computer name (Ex. MAC-UserName):" default answer ""
    set compName to text returned of result
end tell
EOF)

## Check the variable to make sure it's not empty...
if [ "$COMPNAME" == "" ]; then
    echo "Computer name was not changed."
    exit 0
else
    echo "New computer name is $COMPNAME"
fi

}

## Run the function above
askForCompName

## Rename the Mac using scutil (can also use the Jamf binary here)
/usr/sbin/scutil --set ComputerName "${COMPNAME}"
/usr/sbin/scutil --set LocalHostName "${COMPNAME}"
/usr/sbin/scutil --set HostName "${COMPNAME}"

jamf setComputerName -name "${COMPNAME}"

jamf recon

exit 0

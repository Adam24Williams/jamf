#!/bin/bash

# Written By: Adam Williams
# Info: A simple template to check to see if a specific app is not installed. If it is, update inventory. If it is not, run custom policy event.
# This assists with a bug within Jamf Pro where it believes the Mac does not have any apps installed.

# Paramater 4: Application Name
# Paramater 5: Custom Event Name

if [[ $4 == "" || $5 == "" ]]; then
	echo "One or both paramaters are missing"
    exit 1
fi

if [[ -d "/Applications/$4.app" ]]; then
	echo "$4 is installed. Updating inventory."
    jamf recon
else
	echo "$4 is not installed. Attempting to install."
    jamf policy -event $5
fi

exit 0
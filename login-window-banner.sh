#!/bin/bash

# ################################################################################################################################################
#
# Script Name:  Login Window Banner
#
# Author:       Adam Williams
# Date:         06/14/2020
# Version:      1.0
#
# Purpose:      Sets the login window to show Computer Name, Asset Tag, and Serial Number
#
# Changes:      - 06/14/2020
#                   - Script creation
# ##################################################################################################################################
### Check for log file
if [ -f "/Library/HCSD/logging.sh" ]
then
    echo "Log file exists! Continuing with script."
else
    jamf policy -event logFile
fi
####################################################################################################
source /Library/HCSD/logging.sh
####################################################################################################

### Variables
apiURL="https://hilliard.jamfcloud.com"  # JSS URL without trailing forward slash
apiUsername="$4"                    # API Username
apiPassword="$5"                    # API Password
computerUDID=$(/usr/sbin/system_profiler SPHardwareDataType | /usr/bin/awk '/Hardware UUID:/ { print $3 }')
computerSerial=$(ioreg -rd1 -c IOPlatformExpertDevice | awk -F'"' '/IOPlatformSerialNumber/{print $4}')

if [[ -z "$apiUsername" ]] || [[ -z "$apiPassword" ]] || [[ -z "$apiURL" ]]; then
    echo "The API username, password or JSS URL were not specified in the script. Please add these details and try again."
    exit 1
fi

### Getting current asset tag
assetTag=`curl -H "Accept: text/xml" -sfku ${apiUsername}:${apiPassword} ${apiURL}/JSSResource/computers/udid/${computerUDID} | xmllint --format - | awk -F'>|<' '/asset_tag/{print $3}'`

if [ "$assetTag" == "" ]; then
  assetTag="No Tag"
fi

### Setting login window to show Computer Name - Asset Tag - Serial Number
defaults write /Library/Preferences/com.apple.loginwindow LoginwindowText "$2 | $assetTag | $computerSerial"

#!/bin/bash

# ################################################################################################################################################
#
# Script Name:  iPad Quick Search
#
# Author:       Adam Williams
# Date:         08/18/2020
# Version:      1.0
#
# Purpose:      This will search Jamf for an iPad and take you directly to the inventory page.
#
# Changes:      - 08/18/2020
#                   - Script creation
# ##################################################################################################################################

### Variables
apiURL="https://hilliard.jamfcloud.com"  # JSS URL without trailing forward slash
apiUsername="${4}"                    	 # API Username
apiPassword="${5}"                    	 # API Password

### Check that API is ready to go
if [[ -z "$apiUsername" ]] || [[ -z "$apiPassword" ]] || [[ -z "$apiURL" ]]; then
  echo "The API username, password or JSS URL were not specified in the script. Please add these details and try again."
  exit 1
fi

# Defining jamfHelper
JAMFHELPER="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"

function askForDeviceInfo ()
{

## Capture the user input into a variable
deviceInfo=$(/usr/bin/osascript << EOF
tell application "System Events"
    activate
    display dialog "Enter in the iPad Asset Tag, Enrolled Username, or Student ID" default answer ""
    set deviceInfo to text returned of result
end tell
EOF)

## Check the variable to make sure it's not empty...
if [ "$deviceInfo" == "" ]; then
    RESULT=`"$JAMFHELPER" -windowType utility -title "Hilliard City School District" -icon /Library/HCSD/loginlogo.png -iconSize 145 -description "Please try again or verify provided information is correct in Jamf Pro" -timeout 60 -button1 "Close"`
else
    realName=`curl -H "Accept: text/xml" -sfku ${apiUsername}:${apiPassword} ${apiURL}/JSSResource/mobiledevices/match/$deviceInfo | xmllint --format - | awk -F'>|<' '/realname/{print $3}'`
      if [ "$realName" == "" ]; then
        RESULT=`"$JAMFHELPER" -windowType utility -title "Hilliard City School District" -icon /Library/HCSD/loginlogo.png -iconSize 145 -description "Unable to locate iPad. Please try again with different information." -timeout 60 -button1 "Close"`
      else
        ipadUDID=`curl -H "Accept: text/xml" -sfku ${apiUsername}:${apiPassword} ${apiURL}/JSSResource/mobiledevices/match/$deviceInfo | xmllint --format - | awk -F'>|<' '/udid/{print $3}'`
        assetTag=`curl -H "Accept: text/xml" -sfku ${apiUsername}:${apiPassword} ${apiURL}/JSSResource/mobiledevices/udid/$ipadUDID | xmllint --format - | awk -F'>|<' '/asset_tag/{print $3}'`
        serialNumber=`curl -H "Accept: text/xml" -sfku ${apiUsername}:${apiPassword} ${apiURL}/JSSResource/mobiledevices/match/$deviceInfo | xmllint --format - | awk -F'>|<' '/serial_number/{print $3}'`
        buildingInfo=`curl -H "Accept: text/xml" -sfku ${apiUsername}:${apiPassword} ${apiURL}/JSSResource/mobiledevices/udid/$ipadUDID | xmllint --format - | awk -F'>|<' '/building/{print $3}'`
        RESULT=`"$JAMFHELPER" -windowType utility -title "Hilliard City School District" -icon /Library/HCSD/loginlogo.png -iconSize 145 -description "Name: $realName
        Building: $buildingInfo
        Asset Tag: $assetTag
        Serial Number: $serialNumber" -timeout 60 -button1 "Cancel" -button2 "Correct"`
        if [ $RESULT == 0 ]; then
            RESULT=`"$JAMFHELPER" -windowType utility -title "Hilliard City School District" -icon /Library/HCSD/loginlogo.png -iconSize 145 -description "Please try again or verify provided information is correct in Jamf Pro" -timeout 60 -button1 "Close"`
        elif [ $RESULT == 2 ]; then
            ipadUDID=`curl -H "Accept: text/xml" -sfku ${apiUsername}:${apiPassword} ${apiURL}/JSSResource/mobiledevices/match/$deviceInfo | xmllint --format - | awk -F'>|<' '/udid/{print $3}'`
            ipadID=`curl -H "Accept: text/xml" -sfku ${apiUsername}:${apiPassword} ${apiURL}/JSSResource/mobiledevices/serialnumber/$serialNumber/subset/general | xpath /mobile_device/general/id[1] | awk -F'>|<' '{print $3}'` > /dev/null 2>&1
            open "https://hilliard.jamfcloud.com/mobileDevices.html?id=$ipadID&o=r" > /dev/null 2>&1
        fi
      fi
fi

}

## Run the function above
askForDeviceInfo > /dev/null 2>&1

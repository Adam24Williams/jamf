#!/bin/bash

# ################################################################################################################################################
#
# Script Name:  JSSiWC
#
# Author:       Adam Williams
# Date:         08/17/2020
# Version:      2.0
#
# Purpose:      This will search Jamf and provide the UDID. It will then open that user's Self Service web clip.
#
# Changes:      - 08/17/2020
#                   - Script creation
#               - 05/22/2021
#                   - Secured the password
#                   - Now available as a local script/application
#                   - Gives an error message when there are multiple results
#                   - Verifies that the user should be allowed to run the tool
# ################################################################################################################################################

# Variables
apiURL="ENTER-URL-HERE"
JAMFHELPER="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
currentUser=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')
currentUserFullName=$(id -F)

# Welcome Message
welcomeMessage=`"$JAMFHELPER" -windowType utility -title "Hilliard City School District" -icon /Library/HCSD/loginlogo.png -iconSize 145 -description "Hello, $currentUserFullName! This tool is intended to help access a user's Self Service web clip. Are you ready to continue?" -timeout 60 -button1 "Continue" -button2 "Cancel"`

if [[ $welcomeMessage == 2 ]]; then
    echo "Cancel was pressed"
    exit 0
fi

# Verifying that the user has permission to run this tool
function checkCreds () {

secretVar=$(osascript -e 'Tell application "System Events" to display dialog "Enter your network password:" with hidden answer default answer "" with title "Hilliard City School District" with icon file ":Library:HCSD:loginlogo.png"' -e 'text returned of result' 2>/dev/null)

apiCheck=$(curl -H "accept: text/xml" -sfku ${currentUser}:${secretVar} ${apiURL}/JSSResource/accounts/username/hjadmin | xmllint --xpath '/account/id/text()' -)

if [[ $apiCheck = 1 ]]; then
    echo "Successful connection established."
else
    loginError=`"$JAMFHELPER" -windowType utility -title "Hilliard City School District" -icon /Library/HCSD/loginlogo.png -iconSize 145 -description "Error: You either don't have permission to use this tool or your password was incorrect. Please try again." -timeout 60 -button1 "Try Again" -button2 "Cancel"`
        if [[ $loginError == 0 ]]; then
            echo "Try again was pressed"
            checkCreds
        else
            echo "Cancel was pressed"
            exit 0
        fi
fi

}

checkCreds


#Locating iPad Self Service Web Clip
function iPadInfo () {

iPadData=$(osascript -e 'Tell application "System Events" to display dialog "Enter iPad Information:" default answer "" with title "Hilliard City School District" with icon file ":Library:HCSD:loginlogo.png"' -e 'text returned of result')

if [[ "$iPadData" == "" ]]; then

    iPadMessage=`"$JAMFHELPER" -windowType utility -title "Hilliard City School District" -icon /Library/HCSD/loginlogo.png -iconSize 145 -description "iPad Information was left blank. Would you like to try again?" -timeout 60 -button1 "Try Again" -button2 "Cancel"`
    if [[ $iPadMessage == 0 ]]; then
        echo "Try again was pressed"
        iPadInfo
    else
        echo "Cancel was pressed"
        exit 0
    fi

fi

searchResults=$(curl -H "accept: text/xml" -skfu ${currentUser}:${secretVar} ${apiURL}/JSSResource/mobiledevices/match/$iPadData -X GET)
UDIDs=()
UDIDs=$(echo "$searchResults" | xmllint --format - | awk -F '[<>]' '/<udid>/{print $3}')
numberOfResults=$(echo -n "$UDIDs" | grep -c '^')

if [[ $numberOfResults > 1 ]]; then

    iPadMessage=`"$JAMFHELPER" -windowType utility -title "Hilliard City School District" -icon /Library/HCSD/loginlogo.png -iconSize 145 -description "There were more than 1 results. Please narrow your search." -timeout 60 -button1 "Try Again" -button2 "Cancel"`
    if [[ $iPadMessage == 0 ]]; then
        echo "Try again was pressed"
        iPadInfo
    else
        echo "Cancel was pressed"
        exit 0
    fi
fi

massResults=$(curl -H "accept: text/xml" -sfku ${currentUser}:${secretVar} ${apiURL}/JSSResource/mobiledevices/udid/$UDIDs -X GET)
realname=$(echo "$massResults" | xmllint --format - | awk -F '[<>]' '/<realname>/{print $3}')
assetTag=$(echo "$massResults" | xmllint --format - | awk -F '[<>]' '/<asset_tag>/{print $3}')
building=$(echo "$massResults" | xmllint --format - | awk -F '[<>]' '/<building>/{print $3}')

    iPadMessage=`"$JAMFHELPER" -windowType utility -title "Hilliard City School District" -icon /Library/HCSD/loginlogo.png -iconSize 145 -description "Name: $realname
    Building: $building
    Asset Tag: $assetTag" -timeout 60 -button1 "Correct" -button2 "Try Again"`
    if [[ $iPadMessage == 0 ]]; then
        echo "Correct was pressed"
        open "https://hilliard.jamfcloud.com/mdss/?udid=$UDIDs"
    else
        echo "Try again was pressed"
        iPadInfo
    fi

    keepGoing=`"$JAMFHELPER" -windowType utility -title "Hilliard City School District" -icon /Library/HCSD/loginlogo.png -iconSize 145 -description "Would you like to search for another iPad?" -timeout 60 -button1 "Yes" -button2 "No"`
    if [[ $keepGoing == 0 ]]; then
        echo "Yes was pressed"
        iPadInfo
    else
        echo "No was pressed"
        exit 0
    fi
}

iPadInfo

exit 0
#!/bin/bash
#Adam Williams
#Automate macOS Update

#Variables
JAMFHELPER="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"

RESULT=$("$JAMFHELPER" -windowType utility -title "Hilliard City School District" -icon /Library/HCSD/loginlogo.png -iconSize 145 -description "This tool will help assist with the update process for your Mac. It is recommended that you have a backup of your files, are plugged into a charger if you're using a MacBook, and a reliable internet connection for roughly 45-60 minutes. Please close all files and applications. Are you ready to proceed?" -button1 "Cancel" -button2 "Continue")
if [ $RESULT == 0 ]; then
    echo "Cancel was selected!"
    exit 0
else
    echo "Continue was selected!"
fi

#Health Check
function healthCheck () {
    # set Internal Field Separator (IFS) to newline
    # this accomodates app titles/directories with spaces
    IFS=$'\n'

    # perform `mdfind` search; save it to "SEARCH_OUTPUT"
    SEARCH_OUTPUT="$(/usr/bin/mdfind -onlyin /Applications "kMDItemExecutableArchitectures == 'i386' && \
    kMDItemExecutableArchitectures != 'x86_64' && \
    kMDItemKind == 'Application'")"

    # create an empty array to save the app names to
    APPS=()

    # remove tmp file
    rm -f /tmp/apps.txt

    # loop through the search output; add the applications to the array
    for i in $SEARCH_OUTPUT; do
    # use `basename` to strip out the directory path
    b=$( /usr/bin/basename -a "$i" )
    APPS+=("$b")
    # Append full path to file
    echo "$i" >> /tmp/apps.txt
    done

    if [ ${#APPS[@]} == 0 ]; then
        echo "No 32-bit applications detected"
    else
        RESULT=$("$JAMFHELPER" -windowType utility -title "Hilliard City School District" -icon /Library/HCSD/loginlogo.png -iconSize 145 -description "There are currently ${#APPS[@]} applications that may stop working after the update. If you would like to view this list, please restart the update process in Self Service when you are ready. Would you like to view these applications or continue?" -button1 "View" -button2 "Continue")
        if [ $RESULT == 0 ]; then
            echo "View was selected!"
            open '/tmp/apps.txt'
            exit 0
        else
            echo "Continue was selected!"
        fi
    fi
}

healthCheck

# function checkForAC () {
#     # check for ac power
#     acPower=$(pmset -g batt | head -n 1 | cut -d \' -f2)
#     if [[ "$acPower" != "AC Power" ]]; then
#         RESULT=$("$JAMFHELPER" -windowType utility -title "Hilliard City School District" -icon /Library/HCSD/loginlogo.png -iconSize 145 -description "Please plug your MacBook into a charger before proceeding." -button1 "Cancel" -button2 "Continue")
#             if [ $RESULT == 0 ]; then
#                 echo "Cancel was selected!"
#                 exit 0
#             else
#                 echo "Continue was selected!"
#                 checkForAC
#             fi
#     fi
# }

# checkForAC

function askForBackup () {
    RESULT=$("$JAMFHELPER" -windowType utility -title "Hilliard City School District" -icon /Library/HCSD/loginlogo.png -iconSize 145 -description "This update process is not intended to erase any files from the computer but it is still recommended that you have a backup. If you continue, you acknowledge that you have a recent backup or are aware of these risks. Are you ready to continue?" -button1 "Cancel" -button2 "Continue")
    if [ $RESULT == 0 ]; then
        echo "Cancel was selected!"
        exit 0
    else
        echo "Continue was selected!"
    fi
}

askForBackup

#Updating Stuff
jamf manage
jamf recon

function checkNotify () {
#Check for DEPNotify
if [[ -d /Applications/Utilities/DEPNotify.app ]]; then
    echo "DEPNotify is installed"
else
    jamf policy -event depNotifyNS
    checkNotify
fi
}

checkNotify

#Starting the update
cpuType=$(/usr/sbin/sysctl -n machdep.cpu.brand_string)
if [[ "$cpuType" == *"Intel"* ]]; then
    curl -s https://raw.githubusercontent.com/grahampugh/erase-install/master/erase-install.sh | sudo bash /dev/stdin --reinstall --update --check-power --depnotify
else
    curl -s https://raw.githubusercontent.com/grahampugh/erase-install/master/erase-install.sh | sudo bash /dev/stdin --reinstall --update --check-power --current-user --depnotify
fi
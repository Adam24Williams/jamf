#!/bin/bash
# Microsoft Office Manager
# Version: 1.0
# Compatibility: macOS 10.14, macOS 10.15
# Written By: Adam Williams
# Adam_Williams@hilliardschools.org

###############################################################################
# General Information
###############################################################################
# This script will walk the user through reinstalling or uninstalling Microsoft Office

###############################################################################
# Variables
###############################################################################

JAMFHELPER="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
studentCheck='^[0-9]+$'
currentUser=`who |grep console| awk '{print $1}'`

###############################################################################
# Health Check
###############################################################################

# Verifying that this request is not being made by a student.
if [[ $currentUser =~ $studentCheck ]]; then
   echo "This request cannot be made by a student."
   RESULT=`"$JAMFHELPER" -windowType hud -title "Hilliard City Schools" -description "This request cannot be made by a student. Please login to a staff account." -button1 "OK" -timeout 60`
    if [ $RESULT == 0 ]; then
        echo "OK was pressed!"
    elif [ $RESULT == 2 ]; then
        echo "Nothing was pressed!"
    fi
    exit 1
else
	echo "This is not a student account. Proceeding."
fi

if [ -d "/Applications/Microsoft Word.app" ] || [ -d "/Applications/Microsoft Excel.app" ] || [ -d "/Applications/Microsoft PowerPoint.app" ] || [ -d "/Applications/Microsoft Outlook.app" ]; then
  echo "Office appears to be installed."
  RESULT=`"$JAMFHELPER" -windowType hud -title "Hilliard City School District" -icon /Library/HCSD/loginlogo.png -iconSize 145 -description "Microsoft Office appears to be installed already. How would you like to proceed?" -timeout 60 -button1 "Reinstall" -button2 "Uninstall"`
    if [ $RESULT == 0 ]; then
      echo "Reinstall was pressed!"
      jamf policy -event officeUninstall
      jamf policy -event officeInstall
    elif [ $RESULT == 2 ]; then
  	  echo "Uninstall was pressed"
      jamf policy -event officeUninstall
    fi
else
  echo "Office does not appear to be installed."
  RESULT=`"$JAMFHELPER" -windowType hud -title "Hilliard City School District" -icon /Library/HCSD/loginlogo.png -iconSize 145 -description "Would you like to install Microsoft Office? This may take up to 20-30 minutes." -timeout 60 -button1 "Install" -button2 "Cancel"`
    if [ $RESULT == 0 ]; then
      echo "Install was pressed!"
      jamf policy -event officeInstall
    elif [ $RESULT == 2 ]; then
      echo "Cancel was pressed"
    fi
fi

exit 0

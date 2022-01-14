#!/bin/bash

    # This script must be run as root or with "sudo"

    echo "Stopping the jamfAgent and removing it from launchd..."
    /bin/launchctl bootout gui/$(/usr/bin/stat -f %u /dev/console)/'com.jamfsoftware.jamf.agent'
    sleep 1
    /bin/rm /Library/LaunchAgents/com.jamfsoftware.jamf.agent.plist

    echo "Running jamf manage to download and restart the jamfAgent..."
    /usr/local/jamf/bin/jamf manage

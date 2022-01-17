#!/bin/bash
#Find Serial Numbers Based on Student ID Match
#Enable Lost Most For Devices in Results

# server connection information
URL="https://hilliard.jamfcloud.com"
userName="username"
password="pass"
workingFile="/tmp/neededCSV.csv"
apiDataTrue="<mobile_device><extension_attributes><extension_attribute><name>Lost Mode Enforced</name><value>Enabled</value></extension_attribute></extension_attributes></mobile_device>"

#kill_process
kill_process() {
    process="$1"
    if /usr/bin/pgrep -a "$process" >/dev/null ; then 
        /usr/bin/pkill -a "$process" && echo "   lost-reporter '$process' ended" || \
        echo "   lost-reporter '$process' could not be killed"
    fi
}

# ensure computer does not go to sleep while running this script
pid=$$
echo "Caffeinating this script (pid=$pid)"
/usr/bin/caffeinate -dimsu -w $pid &
caffeinate_pid=$!

printf "Enter or drag CSV: "
read FILELOC

if [[ -f "$workingFile" ]]; then
    rm "$workingFile"
fi

tr '\r' '\n' < $FILELOC > $workingFile

# printf "\n" >> $FILELOC
index=0
serialNumbers=()

while IFS="," read -r usernames; do
    if [[ $usernames != "" ]]; then
        printf "\nGathering info for $usernames\n"
        firstCall=$(curl -X GET -u ${userName}:${password} "https://hilliard.jamfcloud.com/JSSResource/mobiledevices/match/$usernames" -H  "accept: application/xml")
        deviceID=$(echo "$firstCall" | /usr/bin/xpath -e '/mobile_devices/mobile_device/id/text()') 2>/dev/null
        if [[ "$deviceID" != "" ]]; then
        serial=$(echo "$firstCall" | /usr/bin/xpath -e '/mobile_devices/mobile_device/serial_number/text()') 2>/dev/null
        lostModeEnabled=$(curl -X GET -s -k -u "$userName:$password" "https://hilliard.jamfcloud.com/JSSResource/mobiledevices/id/$deviceID/subset/security" -H  "accept: application/xml" | xmllint --format - | awk -F'>|<' '/lost_mode_enabled/{print $3}') 2>/dev/null
        lostModePending=$(curl -X GET -s -k -u "$userName:$password" "https://hilliard.jamfcloud.com/JSSResource/mobiledevicehistory/id/$deviceID" -H  "accept: application/xml" | xmllint --format - | awk -F'<pending><command>|</command></pending>' '/name/{print $1}' | grep "EnableLostMode" | awk -F'>|<' '{print $3}') 2>/dev/null
        lostModeEnforced=$(curl -H "Accept: text/xml" -sfku ${userName}:${password} "https://hilliard.jamfcloud.com/JSSResource/mobiledevices/id/${deviceID}/subset/extension_attributes" | xmllint --format - | grep -A3 "<name>Lost Mode Enforced</name>" | awk -F'>|<' '/value/{print $3}') 2>/dev/null
        printf "\nStudent ID: $usernames\nDevice ID: $deviceID\nSerial Number: $serial\nLost Mode Status: $lostModeEnabled\nPending Command: $lostModePending\n"
            if [[ "$lostMode" == "true" ]] || [[ "$lostModePending" != "" ]]; then
            printf "Device is already in Lost Mode or command has been sent\n"
            if [[ "$lostModeEnforced" != *"Enabled" ]]; then
            printf "Fixing extension attribute while we are here"
            apiPost=`curl -H "Content-Type: text/xml" -sfu ${userName}:${password} ${URL}/JSSResource/mobiledevices/id/$deviceID -d "${apiDataTrue}" -X PUT`
            echo ${apiPost}
            fi
        else
            serialNumbers+=($serial)
            (( index++ ))
        fi
        else
        echo "No device found"
        fi
    fi
done < $workingFile

echo "There were ${#serialNumbers[@]} serial numbers found!"

# Lost Mode messaging
lostModeMsg="This iPad has been reported lost from Hilliard City School District. Please return this iPad to Central Office at 2140 Atlas Street, Columbus, OH 43228."
lostModePhone="(614) 921-7148"
lostModeFootnote="Property of Hilliard City School District"

# send Lost Mode command to every device in mobile device list
for aDevice in ${serialNumbers[@]}
do
    # get Jamf Pro ID for device
    deviceID=$( /usr/bin/curl -s "$URL/JSSResource/mobiledevices/serialnumber/$aDevice" \
    --user "$userName:$password" \
    --header "Accept: text/xml" \
    --request GET | \
    /usr/bin/xpath -e '/mobile_device/general/id/text()' )
    
    # API submission command
    xmlData="<mobile_device_command>
	<general>
		<command>EnableLostMode</command>
		<lost_mode_message>$lostModeMsg</lost_mode_message>
		<lost_mode_phone>$lostModePhone</lost_mode_phone>
		<lost_mode_footnote>$lostModeFootnote</lost_mode_footnote>
	</general>
	<mobile_devices>
		<mobile_device>
			<id>$deviceID</id>
		</mobile_device>
	</mobile_devices>
</mobile_device_command>"
    
    # flattened XML
    flatXML=$( /usr/bin/xmllint --noblanks - <<< "$xmlData" )
                    
    /usr/bin/curl -s "$URL/JSSResource/mobiledevicecommands/command/EnableLostMode"\
    --user "$userName":"$password" \
    --header "Content-Type: text/xml" \
    --request POST \
    --data "$flatXML"
   
    echo "Sending Enable Lost Mode Command to Device ID: $deviceID..."

    apiPost=`curl -H "Content-Type: text/xml" -sfu ${userName}:${password} ${URL}/JSSResource/mobiledevices/id/$deviceID -d "${apiDataTrue}" -X PUT`
    echo ${apiPost}
    echo "Set extension attribute..."
done

# kill caffeinate
kill_process "caffeinate"

exit 0

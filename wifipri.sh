#!/bin/bash
#Set WiFi Priority For SSIDs
#Priority will be set in order 1-3
#NOTE: This will check the box for auto join

#Configurable SSID Information
SSIDNAME1="ENTER_SSID_1" #Change to $4 if you want to pull this from Jamf policy instead
SSIDNAME2="ENTER_SSID_2" #Change this to $5 if you want ^
SSIDNAME3="ENTER_SSID_3" #Change this to $6 if you want ^^
SECTYPE1="WPA2E" #Examples: WPA, WPA2, WPA2E, OPEN, NONE
SECTYPE2="WPA2" #This is optional if you aren't going to move $SSIDNAME2
SECTYPE3="WPA2" #This is option if you aren't going to move $SSIDNAME3

#DO NOT CHANGE BELOW THIS LINE

#Getting the current hardware port for WiFi
HWPORT=$(networksetup -listallhardwareports | awk '/Wi-Fi|AirPort/{getline; print $NF}')

#Checking if SSIDs exists
if [[ -z $(networksetup -listpreferredwirelessnetworks "$HWPORT" | grep "$SSIDNAME1") ]]; then
    echo "$SSIDNAME1 is not currently installed"
    exit 1
else
    echo "$SSIDNAME1 is installed"
fi

if [[ -z $(networksetup -listpreferredwirelessnetworks "$HWPORT" | grep "$SSIDNAME2") ]]; then
    echo "$SSIDNAME2 is not currently installed"
    exit 1
else
    echo "$SSIDNAME2 is installed"
fi

if [[ -z $(networksetup -listpreferredwirelessnetworks "$HWPORT" | grep "$SSIDNAME3") ]]; then
    echo "$SSIDNAME3 is not currently installed"
    exit 1
else
    echo "$SSIDNAME3 is installed"
fi

wiFunction ()
{
#Gathering current list of preferred networks
SSIDLIST=$(networksetup -listpreferredwirelessnetworks "$HWPORT" | tail -n +2)

#Creating array of the results
SAVEIFS=$IFS
IFS=$'\n'
nArray=($SSIDLIST)
IFS=$SAVEIFS

for (( i=0; i<${#nArray[@]}; i++ ))
do
    if [[ ${nArray[$i]} == *"$SSIDNAME1"* ]]; then
        echo "$i: ${nArray[$i]}"
    fi
    if [[ ${nArray[$i]} == *"$SSIDNAME1" ]]; then
        index1=$i
    elif [[ ${nArray[$i]} == *"$SSIDNAME2" ]]; then
        index2=$i
    elif [[ ${nArray[$i]} == *"$SSIDNAME3" ]]; then
        index3=$i
    fi
done

#Use this if you only care about moving $SSIDNAME1 above the other 2
if [[ $index1 -lt $index2 ]] && [[ $index1 -lt $index3 ]]; then
    echo "$SSIDNAME1 is correctly set as the top priority!"
    exit 0
elif [[ $index2 -lt $index3 ]]; then
    echo "Setting $SSIDNAME1 above $SSIDNAME2"
    networksetup -removepreferredwirelessnetwork "$HWPORT" "$SSIDNAME1"
    networksetup -addpreferredwirelessnetworkatindex "$HWPORT" "$SSIDNAME1" $index2 "$SECTYPE1"
elif [[ $index2 -gt $index3 ]]; then
    echo "Setting $SSIDNAME1 above $SSIDENAME3"
    networksetup -removepreferredwirelessnetwork "$HWPORT" "$SSIDNAME1"
    networksetup -addpreferredwirelessnetworkatindex "$HWPORT" "$SSIDNAME1" $index3 "$SECTYPE1"
else
    echo "I am not sure how we have made it this far. Please double check your configuration"
    exit 1
fi

#Use this (and comment out above) if you would like to move $SSIDNAME3 below $SSIDNAME2
# if [[ $index1 -gt $index2 ]]; then
#     echo "Setting $SSIDNAME1 above $SSIDENAME2"
#     networksetup -removepreferredwirelessnetwork "$HWPORT" "$SSIDNAME1"
#     networksetup -addpreferredwirelessnetworkatindex "$HWPORT" "$SSIDNAME1" $index2 "$SECTYPE1"
# else
#     echo "$SSIDNAME1 is correctly above $SSIDNAME2"
#     firstPass="True" # Use this if you decide to care about $SSIDNAME3
#     exit 0 # Comment this out if you use $firstPass above
# fi

# # Use this if you want $SSIDNAME3 to be below $SSIDNAME2
# # if [[ $index2 -gt $index3 ]]; then
# #     echo "Setting $SSIDNAME3 below $SSIDNAME2"
# #     networksetup -removepreferredwirelessnetwork "$HWPORT" "$SSIDNAME3"
# #     networksetup -addpreferredwirelessnetworkatindex "$HWPORT" "$SSIDNAME3" $(($index2 + 1)) "$SECTYPE3"
# # else
# #     echo "$SSIDNAME3 is correctly below $SSIDNAME2"
# #     if [[ "$firstPass" == "True" ]]; then
# #         exit 0
# #     fi
# # fi
}

wiFunction

#Checking the results, if needed
echo "Running function again to verify the changes"
wiFunction

exit 0
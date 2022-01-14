#!bin/sh
#This script sets the computer name for staff MacBooks. It's simple. I like it.
#Script created by Adam Williams

#Gets the currently logged in username
U=`who |grep console| awk '{print $1}'`

#Uses that username to set the computer name.
sudo scutil --set ComputerName "MAC-$U"
sudo scutil --set LocalHost Name "MAC-$U"
sudo scutil --set HostName "MAC-$U"

sleep 5

#Let's send this to Jamf now.
sudo jamf setComputerName -name "MAC-$U"

sleep 10

#Final push to Jamf server.
sudo jamf recon

exit 0

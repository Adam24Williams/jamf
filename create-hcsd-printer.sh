#!/bin/bash
#Prompt user for printer information and then install
#This was intended for HCSD

#Ask user for printer name
echo ""
echo "What is the name of the printer?"
read -p "Printer name: " printerName

#Ask for print server
echo ""
echo "What print server is $printerName on?"
read -p "Print server: " printServer

#Ask for driver information
echo ""
echo "What model is this printer?"
echo "Type in one of the following:"
echo "HP 3015 = 3015"
echo "HP 553 = 553"
read -p "Printer model: " printerModel

if [[ "$printerModel" == *"3015"* ]]; then
  printerDriver=/Library/Printers/PPDs/Contents/Resources/HP\ LaserJet\ P3010\ Series.gz
elif [[ "$printerModel" == *"553"* ]]; then
  printerDriver=/Library/Printers/PPDs/Contents/Resources/HP\ Color\ LaserJet\ M553.gz
else
  echo "Unable to recognize printer model"
  exit 1
fi

/usr/sbin/lpadmin -p $printerName \
-E \
-D $printerName \
-P "$printerDriver" \
-v lpd://print-$printServer.hboe.org/$printerName \
-o printer-is-shared=False \
-o printer-error-policy=abort-job \
-o auth-info-required=none

echo "Successfully installed $printerName"

exit 0

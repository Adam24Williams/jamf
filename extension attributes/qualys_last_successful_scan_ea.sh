#!/bin/bash
# Output last successful Qualys scan

# Define the path to the log file
LOG_FILE="/var/log/qualys/qualys-cloud-agent-scan.log"

# Check if the log file exists
if [ -f "$LOG_FILE" ]; then
    # Extract the date for the last entry containing "Scan completed for manifest:"
    DATE_ENTRY=$(grep "Scan completed for manifest:" "$LOG_FILE" | tail -n 1 | awk '{print $1, $2}' | sed 's/....$//')
else
    DATE_ENTRY="Log Not Found"
fi

echo "<result>$DATE_ENTRY</result>"

exit 0
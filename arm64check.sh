#!/usr/bin/env bash
# ARM64 Check
# Version: 1.0
# Compatibility: macOS 11.0+

###############################################################################
# General Information
###############################################################################
# This script will check if the newly enrolled device has an ARM-based chip
# It will then install Rosetta 2, if needed

cpuCheck=$(uname -m)

if [[ "$cpuCheck" == "arm64" ]]; then
    echo "M1 CPU has been detected."
    softwareupdate --install-rosetta --agree-to-license
    jamf recon
else
    echo "Does not need Rosetta 2 installed"
fi

exit 0

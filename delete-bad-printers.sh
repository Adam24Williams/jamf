#!/bin/bash
#Loop to delete printers that were incorrectly installed

listOfPrinters=$(lpstat -p | awk '{print $2}')

for a in ${listOfPrinters}; do
  if [[ "$a" == *"PRINT_ES"* ]] || [[ "$a" == *"PRINT_MS"* ]] || [[ "$a" == *"PRINT_HS"* ]] || [[ "$a" == *"PRINT_COA"* ]]; then
    echo "Deleting $a"
    lpadmin -x "$a"
    continue
  else
    echo "$a should not be deleted"
  fi
done

echo "Cleanup complete"

exit 0

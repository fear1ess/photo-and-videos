#!/bin/bash
DRY_RUN=true
SD_CARD_NAME=DJI
cd /Volumes/$SD_CARD_NAME/DCIM/DJI_001

echo -e "\n Clean WAV and LRF files \n"
rm  *_D.WAV
rm  *_D.LRF

echo -e "\n Directory content: \n"
ls -ltr

echo -e "\n Renaming: \n"

TARGET_NAME="PPA_Lakeland. Men's 5.0+"    # <-- set target name here
DATE="20251122"                 # <-- set your target date here (YYYYMMDD)

for f in DJI_*.MP4; do
  # extract date from filename
  file_date="${f:4:8}"

  # skip if this file is not from DATE
  [[ "$file_date" != "$DATE" ]] && continue

  new=$(printf '%s' "$f" | sed -E "s/^DJI_([0-9]{4})[0-9]{10}_0*([0-9]+)_D\.MP4$/\1 ${TARGET_NAME} \2.MP4/")

  echo "$f --> $new"
  # mv -v -- "$f" "$new"
done



# i=1
# printf '%s\n' *.MP4 | sort -V | while IFS= read -r f; do
#   new=$(printf '%s' "$f" | sed -E "s/[0-9]+\.MP4$/Round ${i}.MP4/")
#   mv -v -- "$f" "$new"
#   ((i++))
# done

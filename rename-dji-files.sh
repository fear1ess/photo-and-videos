#!/bin/bash

TARGET_NAME="Singles. LT. Against Chris"  # <-- set target name here
DATE="20251202"                         # <-- set your target date here (YYYYMMDD)

DRY_RUN=false
# DRY_RUN=true
DELETE_LRF=true
DELETE_WAV=true

SD_CARD_NAME=DJI
WORKING_DIR=/Volumes/$SD_CARD_NAME/DCIM/DJI_001
LOG_FILE="rename_log.txt"

cd $WORKING_DIR || exit

echo -e "\n Clean WAV=$DELETE_WAV and LRF=$DELETE_LRF files \n"
if [[ "$DELETE_WAV" == true ]] && [[ "$DRY_RUN" != true ]] ; then rm ./*_D.WAV 2>/dev/null ; fi
if [[ "$DELETE_LRF" == true ]] && [[ "$DRY_RUN" != true ]] ; then rm ./*_D.LRF 2>/dev/null ; fi

echo -e "\n Directory content: \n"
ls -ltr

echo -e "\n Renaming: \n"


# Start log section
echo "---------------------------------------------" >> "$LOG_FILE"
echo "Rename session: $(date)" >> "$LOG_FILE"
echo "Target date: $DATE" >> "$LOG_FILE"
echo "Dry run: $DRY_RUN" >> "$LOG_FILE"
echo "---------------------------------------------" >> "$LOG_FILE"

for f in DJI_*.MP4; do
  # extract date from filename
  file_date="${f:4:8}"

  # skip non-matching dates
  [[ "$file_date" != "$DATE" ]] && continue

  # Build new filename
  new=$(printf '%s' "$f" | sed -E "s/^DJI_([0-9]{4})[0-9]{10}_0*([0-9]+)_D\.MP4$/\1 ${TARGET_NAME} \2.MP4/")

  if [[ "$DRY_RUN" == true ]]; then
      echo "[DRY RUN] $f --> $new"
      echo "$(date '+%Y-%m-%d %H:%M:%S') [DRY RUN] $f --> $new" >> "$LOG_FILE"
  else
      echo "Renaming: $f --> $new"
      mv -v -- "$f" "$new"
      echo "$(date '+%Y-%m-%d %H:%M:%S') Renamed: $f --> $new" >> "$LOG_FILE"
  fi
done

echo -e "\nLog saved to: $LOG_FILE\n"


# i=1
# printf '%s\n' *.MP4 | sort -V | while IFS= read -r f; do
#   new=$(printf '%s' "$f" | sed -E "s/[0-9]+\.MP4$/Round ${i}.MP4/")
#   mv -v -- "$f" "$new"
#   ((i++))
# done

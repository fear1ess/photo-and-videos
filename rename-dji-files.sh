#!/bin/bash

# Variabels:
TARGET_NAME="PracticeGames_Chris_Josh_Eric"  # <-- set target name here
DATE="20251216"                         # <-- set your target date here (YYYYMMDD)

DRY_RUN=false
# DRY_RUN=true

DELETE_LRF=true
DELETE_WAV=true

SD_CARD_NAME=DJI
WORKING_DIR=/Volumes/$SD_CARD_NAME/DCIM/DJI_001
VIDEO_DESTINATION_DIR_NAME="$DATE $TARGET_NAME"  # <-- set destination dir name
VIDEO_DESTINATION=/Volumes/T7/PB_Videos/$VIDEO_DESTINATION_DIR_NAME # <-- Full path for destination

LOG_FILE="rename_log.txt"


### Script actions:
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
echo "Destination: $VIDEO_DESTINATION" >> "$LOG_FILE"
echo "---------------------------------------------" >> "$LOG_FILE"

renamed_files=()

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
      renamed_files+=("$new")
  fi
done

echo -e "\nLog saved to: $LOG_FILE\n"

if [[ "$DRY_RUN" == true ]]; then
  echo "[DRY RUN] Would create and move to: $VIDEO_DESTINATION"
  printf '%s\n' "${renamed_files[@]/#/  - }"
elif [[ "${#renamed_files[@]}" -eq 0 ]]; then
  echo "No files renamed; nothing to move."
else
  mkdir -p "$VIDEO_DESTINATION"
  echo -e "\nMoving renamed files to: $VIDEO_DESTINATION\n"
  printf '%s\n' "${renamed_files[@]/#/  - }"
  mv -v -- "${renamed_files[@]}" "$VIDEO_DESTINATION"
  echo "$(date '+%Y-%m-%d %H:%M:%S') Moved ${#renamed_files[@]} files to $VIDEO_DESTINATION" >> "$LOG_FILE"
fi


# i=1
# printf '%s\n' *.MP4 | sort -V | while IFS= read -r f; do
#   new=$(printf '%s' "$f" | sed -E "s/[0-9]+\.MP4$/Round ${i}.MP4/")
#   mv -v -- "$f" "$new"
#   ((i++))
# done

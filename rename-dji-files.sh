#!/bin/bash
export PATH="$PATH:$HOME/.local/bin"

# Variabels:
DATE="20260131"                         # <-- set your target date here (YYYYMMDD)
TARGET_NAME="The_Blizzard_Bash_by_Lucky_Shots_Open"  # <-- set target name here

DRY_RUN=false
# DRY_RUN=true

RENAME_AND_COPY=true
# TRANSCRIPT=true
# CUT_POINTS=true

DELETE_LRF=true
DELETE_WAV=true

# Source
SD_CARD_NAME=DJI
WORKING_DIR=/Volumes/$SD_CARD_NAME/DCIM/DJI_001

# Destination
VIDEO_DESTINATION_DIR_NAME="${DATE}_${TARGET_NAME}"  # <-- set destination dir name
VIDEO_DESTINATION=/Volumes/T7/PB_Videos/$VIDEO_DESTINATION_DIR_NAME # <-- Full path for destination
# VIDEO_DESTINATION=/Volumes/T7/PB_Videos/20260109_Pure_PB_Minnesota_Open_Mixed_Moneyball # <-- Full path for destination

LOG_FILE="rename_log.txt"

#######################################################
### Script actions:
#######################################################
if [[ "$RENAME_AND_COPY" == true ]]; then
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
    new=$(printf '%s' "$f" | sed -E "s/^DJI_([0-9]{4})[0-9]{10}_0*([0-9]+)_D\.MP4$/\1_${TARGET_NAME}_\2.MP4/")

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
    exit 0
  elif [[ "${#renamed_files[@]}" -eq 0 ]]; then
    echo "No files renamed; nothing to move."
  else
    mkdir -p "$VIDEO_DESTINATION"
    echo -e "\nMoving renamed files to: $VIDEO_DESTINATION\n"
    printf '%s\n' "${renamed_files[@]/#/  - }"
    # TODO: use rsync for progress bar, and fallback to 'mv' if rsync not available.
    mv -v -- "${renamed_files[@]}" "$VIDEO_DESTINATION"
    echo "$(date '+%Y-%m-%d %H:%M:%S') Moved ${#renamed_files[@]} files to $VIDEO_DESTINATION" >> "$LOG_FILE"
  fi
fi

### For next step tools are required
# command -v whisper >/dev/null 2>&1 || { echo >&2 "Whisper is required but it's not installed. Aborting."; exit 1; }
command -v whisperx >/dev/null 2>&1 || { echo >&2 "WhisperX is required but it's not installed. Aborting."; exit 1; }
command -v ffmpeg >/dev/null 2>&1 || { echo >&2 "ffmpeg is required but it's not installed. Aborting."; exit 1; }

# =======================================================
function revind_seconds(){
  echo "$1" | awk -F: '{
    sec=$1*3600+$2*60+$3
    sec-=25
    if (sec<0) sec=0
    h=int(sec/3600); sec%=3600
    m=int(sec/60); s=sec%60
    printf "%02d:%02d:%02d\n", h,m,s
  }'
}
function add_second(){
  echo "$1" | awk -F: '{
    sec=$1*3600+$2*60+$3
    sec+=1
    if (sec<30) sec=30
    h=int(sec/3600); sec%=3600
    m=int(sec/60); s=sec%60
    printf "%02d:%02d:%02d\n", h,m,s
  }'
}
# =======================================================
# Make transcription with whisper and cut points based on it
list_of_words="cut|beauty|Wow|Whoo|Sweet|point|Mistake|Review"
common_phrases="Common phrases: Cut the point, rally. Cut the point. Mistake, twoie. Mistake, drive. Review point. Cut the point, Brock. Analyze the point. Body bag"

cd $VIDEO_DESTINATION
# i=1
for f in *.MP4 ; do
  # Transcription
  if [[ "$TRANSCRIPT" == true ]] && [[ "$DRY_RUN" != true ]] && [ ! -f "${f%???}srt" ] ; then
    echo "Making transcription with whisper for $f"
    # whisper "$f" --model medium --language English --fp16 False --verbose True --logprob_threshold -2.0 --no_speech_threshold 0.2 --output_format srt
    PYTHONWARNINGS="ignore"
    whisperx "$f" --model medium --language en --output_format srt --vad_method silero  --compute_type float32 --beam_size 5 --best_of 5  --temperature 0 --initial_prompt $common_phrases
  fi

  # Cut points
  if [[ "$CUT_POINTS" == true ]] && [[ "$DRY_RUN" != true ]] ; then
    ind=$(echo "$f" | awk -F'[_.]' '{print $(NF-1)}')
    d="cuts_$ind" ; [ ! -d $d ] && mkdir $d

    # generate timestamp list
    if [[ "$TRANSCRIPT" == true ]] ; then
      echo "Generating cut points from transcription for $f"
      [ -f ${f%???}cut_timestamps.txt ] && rm ${f%???}cut_timestamps.txt
      sed '/ --> /{N; s/\n/ /; }' "${f%???}srt" | grep -iE "$list_of_words" |grep ' --> ' | awk -F ' --> ' '{print substr($1,0, length($1)-4) ";" substr($2,14, length($2)-0); }' > "${f%???}cut_timestamps.txt"
    else
      echo "Check ${f%???}cut_timestamps.txt"
      if [ ! -f "${f%???}cut_timestamps.txt" ] ; then
        echo "No transcription available and no cut timestamps file found. Skipping $f"
        continue
      fi
    fi

    # generate cuts from video
    while IFS= read -r line; do
      echo "$line"
      t=$(echo $line | awk -F';' '{print $1}')
      suffix=$(echo $line| awk -F';' '{print $2}' | tr -c 'A-Za-z' "_")
      start=$(revind_seconds $t)
      end=$(add_second $t)
      echo "$start --> $end"
      ffmpeg -y -nostdin -v fatal -i "$f" -ss $start -to $end -c copy $d/cut_${t}_${suffix}.mp4
      # ffmpeg -y -v fatal -ss $start -i "$f" -c copy -t $t -avoid_negative_ts make_zero -fflags +genpts $d/cut_$t.mp4
      echo "file cut_${t}_${suffix}.mp4" >> $d/list.txt
    done < "${f%???}cut_timestamps.txt"
  fi

  # ((i++))

done
  # --model tiny, base, small, medium, large (or large-v2, large-v3 depending on install).

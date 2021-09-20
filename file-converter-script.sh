#!/bin/bash

export TITLE="file-converter"
export APP_VERSION="beta 0.2"

HERE="$(dirname "$(readlink -f "${0}")")"

file-converter-pdf2jpg() {
pdftoppm -jpeg "$1" "$(echo "$2" | sed 's/\.jpg$//g')"
}

file-converter-pdf2png() {
pdftoppm -png "$1" "$(echo "$2" | sed 's/\.png$//g')"
}

file-converter-pdf2tiff() {
pdftoppm -tiff "$1" "$(echo "$2" | sed 's/\.tiff$//g')"
}

file-converter-pdf2jpg-OnlyFirstPage() {
pdftoppm -singlefile -jpeg "$1" "$(echo "$2" | sed 's/\.jpg-OnlyFirstPage$//g')"
}

yad_show_info() {
    yad --image "info" --title "$TITLE" --center --width=360 --height=240 --text="$@" 2> /dev/null
}

yad_show_error_incompatible_format() {
yad_show_info 'Please use supported and compatible formats.

These formats and their equivalents are supported:
 1) PDF
 2) Images: jpg png tiff bmp heic
 3) Audio : aiff aiffc au amr-nb amr-wb cdda flac gsm mp3 ogg opus sln voc vox wav wv 8svx
 4) Video : 3g2 3gp asf avi m4v mkv mov mp4 nsv rm roq vob webm
 
 A PDF can be converted to jpg , png or tiff -- page-by-page or just the first page.
 Images can be converted to Images, Audios to Audios and Videos to Videos.
'

exit 1
}

# This function is forked from main.
# So, it can't read progress from a variable.
# So, we're using a file to relay progress from main to the progress meter.
progress-bar-monitor_progress() {
    # Continue monitoring while /tmp/file-converter-progress-bar exists.
    # Prints progress to stdout (piped to yad --progress)
    while [ -f /tmp/file-converter-progress-bar ] ; do
        # Update the reading if it changes since last update.
        current_progress="$(cat /tmp/file-converter-progress-bar)"
        if [ "$current_progress" != "$progress_bar_reading" ] ; then
            progress_bar_reading="$current_progress"
            echo "$progress_bar_reading"
        fi
        # Take a break to avoid excess load.
        sleep 0.5 
    done
    # Ensure that the progress bar closes if /tmp/file-converter-progress-bar is removed.
    echo "100"
    echo ""
}

echo ""
echo "File converter is starting......."
echo "Please dont close this terminal window until file-converter exits"
echo 'You need not do anything in this terminal. file-converter will do that for you :)'
echo ""

if ! which yad > /dev/null ; then
    echo "yad is not installed"
    echo "Please install it from software manager or with the command"
    echo "sudo apt update && sudo apt install yad"
    exit 1
fi

# Disallow running as root
if [ "$(whoami)" = "root" ] ; then
    yad_show_info "This app SHOULD NOT be run as root / using sudo"
    exit 1
fi

if ! which bash > /dev/null ; then
    yad_show_info "Please install bash"
    exit 1
fi

if ! which grep > /dev/null ; then
    yad_show_info "Please install grep"
    exit 1
fi

if ! which x-terminal-emulator > /dev/null ; then
    yad_show_info "Please install x-terminal-emulator"
    exit 1
fi

# Remove the "file://" in front
# TODO: Support mtp:// , smb:// etc.,
filelist=$(yad --title="$TITLE" --image="info" --center \
    --width=360 --height=240 \
    --text "Welcome to file-converter version ${APP_VERSION}\n\nPlease DRAG AND DROP files here , then CLICK OK\n\nYou need not do anything in the terminal that just came up." \
    --button=gtk-ok:0 \
    --dnd \
    --cmd echo "$1" | sed 's/^file\:\/\///' )

# I think Drag-N-Drop is better than file selection (for multiple files) because we can:
#  1) Select files from different folders.
#  2) Use preferred file manager.
#  3) Use a "Find" utility (both in the file manager / others like Catfish).

# Remove duplicate from the dragged and dropped files.
filelist="$(echo "$filelist" | sort -u)"

if [ -z "$filelist" ] ; then
    yad_show_info "You have not selected any files.\n Please run again."
    exit 1
fi

# Accept only valid filenames
while read file ; do
    if [ -f "$file" ] && [ -r "$file" ] ; then
        true
    else
        yad_show_info "Please select valid and readable files"
        exit 1
    fi
done < <(echo "$filelist")

# Detect the input file formats (extension) -- converted to lowercase for case-insensitivity
IN_FORMATS="$(echo "$filelist" | grep '\.' | sed 's/^.*\.//g' | tr A-Z a-z | sed 's/^$//g' | sort -u)"

# If all the files have no extension
[ -z "$IN_FORMATS" ] && yad_show_error_incompatible_format

IN_FORMAT=""
IN_FORMAT_TYPE_PREVIOUS=""

# "\!" is for the yad combobox.
# The trailing "\!" is intentional (so that a regex can match all formats equally).

# Ref: https://en.wikipedia.org/wiki/Image_file_formats
IMAGE_FILE_FORMATS="jpg\!png\!tiff\!bmp\!gif\!heic\!webp\!"

# Ref: https://en.wikipedia.org/wiki/Video_file_format
# Ref: ffmpeg -formats
# BTW I'm not familiar with video formats. So, this list may contain errors.
VIDEO_FILE_FORMATS="3g2\!3gp\!asf\!avi\!m4v\!mkv\!mov\!mp4\!nsv\!rm\!roq\!vob\!webm\!"

# Ref: man soxformat
# Ref: https://en.wikipedia.org/wiki/Audio_file_format
# BTW I'm not familiar with audio formats too. So, this list may contain errors.
AUDIO_FILE_FORMATS="aiff\!aiffc\!au\!amr-nb\!amr-wb\!cdda\!flac\!gsm\!mp3\!ogg\!opus\!sln\!voc\!vox\!wav\!wv\!8svx\!"

while read IN_FORMAT ; do

    # If a format is known by many extensions , fix one of them
    if [ "$IN_FORMAT" = "jpg" ] || [ "$IN_FORMAT" = "jpeg" ] ; then
        IN_FORMAT="jpg"
    elif [ "$IN_FORMAT" = "tif" ] ; then
        IN_FORMAT="tiff"
    elif [ "$IN_FORMAT" = "aif" ] ; then
        IN_FORMAT="aiff"
    elif [ "$IN_FORMAT" = "aifc" ] ; then
        IN_FORMAT="aiffc"
    elif [ "$IN_FORMAT" = "amr" ] ; then
        IN_FORMAT="amr-nb"
    elif [ "$IN_FORMAT" = "snd" ] ; then
        IN_FORMAT="au"
    elif [ "$IN_FORMAT" = "awb" ] ; then
        IN_FORMAT="amr-wb"
    elif [ "$IN_FORMAT" = "cdr" ] ; then
        IN_FORMAT="cdda"
    elif [ "$IN_FORMAT" = "mp2" ] ; then
        IN_FORMAT="mp3"
    elif [ "$IN_FORMAT" = "ogga" ] || [ "$IN_FORMAT" = "mogg" ] || [ "$IN_FORMAT" = "vorbis" ] ; then
        IN_FORMAT="ogg"
    elif [ "$IN_FORMAT" = "f4p" ] || [ "$IN_FORMAT" = "f4v" ] || [ "$IN_FORMAT" = "f4a" ] || [ "$IN_FORMAT" = "f4b" ] ; then
        IN_FORMAT="flv"
    elif [ "$IN_FORMAT" = "mpg" ] || [ "$IN_FORMAT" = "mpv" ] || [ "$IN_FORMAT" = "mpe" ] ; then
        IN_FORMAT="mpeg"
    elif [ "$IN_FORMAT" = "m4p" ] ; then
        IN_FORMAT="mp4"
    fi

    if [ "$IN_FORMAT" = "pdf" ] ; then
        AVAILABLE_OUT_FORMATS="jpg\!png\!tiff\!jpg-OnlyFirstPage"
        IN_FORMAT_TYPE="PDF"
        # Exit with error message if the converter is not available
        if ! which pdftoppm > /dev/null ; then
            yad_show_info "To convert pdf files, please install 'poppler-utils' from the software store OR with the command\nsudo apt update && sudo apt install poppler-utils"
            exit 1
        fi
    elif echo "$IMAGE_FILE_FORMATS" | grep "${IN_FORMAT}\\\!" ; then
        IN_FORMAT_TYPE="IMAGE"
        # All image file conversions use convert-im6.q16
        CONVERTER_COMMAND="convert-im6.q16"
        AVAILABLE_OUT_FORMATS="$IMAGE_FILE_FORMATS"
        # Exit with error message if the converter is not available
        if ! which convert-im6.q16 > /dev/null ; then
            yad_show_info "To convert images, please install 'imagemagick' from the software store\nOR with the command\nsudo apt update && sudo apt install imagemagick"
            exit 1
        fi

    elif echo "$AUDIO_FILE_FORMATS" | grep "${IN_FORMAT}\\\!" ; then
        IN_FORMAT_TYPE="AUDIO"
        # All audio file conversions use sox
        CONVERTER_COMMAND="sox"
        AVAILABLE_OUT_FORMATS="$AUDIO_FILE_FORMATS"
        # Exit with error message if the converter is not available
        if ! which sox > /dev/null ; then
            yad_show_info "To convert audio, please install 'sox' from the software store\nOR with the command\nsudo apt update && sudo apt install sox"
            exit 1
        fi
    elif echo "$VIDEO_FILE_FORMATS" | grep "${IN_FORMAT}\\\!" ; then
        IN_FORMAT_TYPE="VIDEO"
        # All video file conversions use ffmpeg
        CONVERTER_COMMAND="ffmpeg -hide_banner -loglevel quiet -status -i "
        AVAILABLE_OUT_FORMATS="$VIDEO_FILE_FORMATS"
        # Exit with error message if the converter is not available
        if ! which ffmpeg > /dev/null ; then
            yad_show_info "To convert videos, please install 'ffmpeg' from the software store\nOR with the command\nsudo apt update && sudo apt install ffmpeg"
            exit 1
        fi
    else
        yad_show_error_incompatible_format
    fi
    
    # If this is not the first iteration of this while loop, check for incompatibilities between input formats.
    # Example: pdf and mp4 , jpg and mp3 etc., are incompatible.
    [ -n "$IN_FORMAT_TYPE_PREVIOUS" ] && [ "$IN_FORMAT_TYPE_PREVIOUS" != "$IN_FORMAT_TYPE" ] && yad_show_error_incompatible_format
    
    # Store this format as the previous format , getting ready for the next iteration.
    # This is to check for incompatible formats.
    IN_FORMAT_TYPE_PREVIOUS="$IN_FORMAT_TYPE"

done < <(echo "$IN_FORMATS")

FILE_COUNT="$(echo "$filelist" | wc -l)"

RESP=$(yad --title="$TITLE" --image="info" --center --width=360 --height=240 \
                --form --field="Output format:CB" "$AVAILABLE_OUT_FORMATS" \
                --text="$FILE_COUNT files will be converted. \n Press OK to proceed" || echo "EXIT NOW")

# Exit on pressing Cancel/Close button.
[ "$RESP" = "EXIT NOW" ] && exit 1

# Remove trailing "|" added by yad
OUT_FORMAT=$(echo $RESP | tr -d '|')

if [ -z "$OUT_FORMAT" ] ; then
    yad_show_info "Please run again and select a vaild output format."
    exit 1
fi

# cd to $HOME before showing folder selection dialog.
# Otherwise, it opens this app's directory to choose folders.
cd "$HOME"
dest_dir=$(yad --title="$TITLE" --image="info" --center \
    --text="\nPlease choose the DESTINATION FOLDER\n" \
    --width=600 --height=400 \
    --file --directory || echo "EXIT NOW")
cd - > /dev/null

# Exit on pressing Cancel/Close button.
[ "$RESP" = "EXIT NOW" ] && exit 1

dest_dir="$dest_dir"/files-converted-on-$(date +%F)-at-$(date +%I-%M-%S-%p)

if ! mkdir "$dest_dir" ; then
    yad_show_info "Please select a valid, writable folder."
    exit 1
fi

rm -rf /tmp/file-converter-progress-bar
echo "0" > /tmp/file-converter-progress-bar

progress-bar-monitor_progress | \
    yad --title "$TITLE" --center --progress --width 540 \
        --text="Converting..... Please wait. \n You need not do anything in the terminal that just came up.\nfile-converter does that for you :)\nTo abort, close that terminal window." \
        --percentage=0 --auto-close --no-button &

echo ""
echo "$FILE_COUNT files going to be converted"
echo ""

# Remove trailing slashes in directory name
dest_dir="$(echo "$dest_dir" | sed 's/\/$//g')"

if [ "$IN_FORMAT_TYPE" = "PDF" ] ; then
    CONVERTER_COMMAND="file-converter-pdf2${OUT_FORMAT}"
fi

SUCCESS_COUNT=0

while read file ; do
    # Just the file name without full path
    file_name_out="$(basename "$file")" # Remove full path
    file_name_out="${file_name_out%.*}" # Remove extension
    
    # If 2 files have same name (ignoring extension)
    # Then, a file with the same name will exist in dest_dir for the second and subsequent iterations of this while loop.
    # If so, a number is appended to the output file to make it unique.
    FILE_NUM=0
    while [ -e "$dest_dir"/"$file_name_out".$OUT_FORMAT ] ; do
        [ "$FILE_NUM" != "0" ] && file_name_out="${file_name_out%.*}" # Remove extension if we're running the second or subsequent time.
        file_name_out="${file_name_out}.(${FILE_NUM})" # Add extension with a number
        # BTW how I miss C++'s FILE_NUM++;
        FILE_NUM=$((${FILE_NUM}+1))
    done
    
    echo ""
    echo "Converting $file ....."
    
    if [ -z "$(echo "$file" | tr A-Z a-z | sed "/\.${OUT_FORMAT}$/d")" ] ; then
        # Just copy the file if the source and destination extensions are same (case-insensitive match)
        cp "$file" "$dest_dir"/"$file_name_out".$OUT_FORMAT
        SUCCESS_COUNT=$((${SUCCESS_COUNT}+1))
        echo "$file is already in output format. Just copying it."
    else
        # Otherwise, do the real conversion
        if ${CONVERTER_COMMAND} "$file" "$dest_dir"/"$file_name_out".$OUT_FORMAT ; then
            echo "$file successfully converted"
            SUCCESS_COUNT=$((${SUCCESS_COUNT}+1))
        else
            echo "Failed to convert $file" | tee -a "$dest_dir"/file-converter-errors.log
        fi
    fi
    # BTW how I miss python's and C/C++'s math.
    percent=$(((100*${SUCCESS_COUNT})/${FILE_COUNT}))
    # TODO: make the percentage show as a progress bar (like apt and wget do)
    echo ""
    echo "$percent % done ; $SUCCESS_COUNT / $FILE_COUNT files processed."
    echo ""
    # This is for the progress bar to read.
    echo "$percent" > /tmp/file-converter-progress-bar
done < <(echo "$filelist")

# Close the progress bar
rm -f /tmp/file-converter-progress-bar

# Show message for success / failure
if [ "$SUCCESS_COUNT" != "$FILE_COUNT" ] ; then
    yad_show_info "Error. Could not convert all files.\n Error log is at $dest_dir/file-converter-errors.log"
    xdg-open "$dest_dir" &
    sleep 1 # Wait for the file manager to open
else
    yad_show_info "Success - all the files have been converted.\n Press OK to see them." || exit 0
    xdg-open "$dest_dir" &
    sleep 1
    exit 0
fi

exit 1

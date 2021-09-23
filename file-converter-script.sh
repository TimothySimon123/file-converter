#!/bin/bash

export TITLE="file-converter"
export APP_VERSION="beta 0.3"

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
pdftoppm -singlefile -jpeg "$1" "$(echo "$2" | sed 's/\.jpg$//g')"
}

# pdf2odg and pdf2html are done by LibreOffice.

file-converter-pdf2ppm() {
pdftoppm "$1" "$(echo "$2" | sed 's/\.ppm$//g')"
}

yad_show_info() {
    yad --image=tap-create --title "$TITLE" --center --width=360 --height=240 --text="$@"
}

yad_show_error_incompatible_format() {
yad --image=tap-create --title "$TITLE" --center --width=540 --height=360 --text='Please use supported and compatible formats.

These formats and their equivalents are supported:
 1) PDF -> html odg jpg jpg-OnlyFirstPage png tiff ppm
 2) Document files: all format conversions supported by LibreOffice.
 3) Images: jpg png gif tiff bmp heic ico webp
 4) Audio : mp3 ogg wav aiff aiffc au amrnb amrwb cdda flac gsm
            opus sln voc vox wv 8svx
 5) Video : 3g2 3gp asf avi m4v mkv mov mp4 nsv rm roq vob webm
 
 Images can be converted to Images, Audios to Audios, Videos to Videos
 and Document files to Document files or PDFs.
 Video files can also be converted to Audio files, but not vice-versa.
 
 Hidden files (whose filenames start with a dot ".") are not supported.
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
        # Update the reading if it has changed since last update.
        current_progress="$(cat /tmp/file-converter-progress-bar)"
        if [ "$current_progress" != "$progress_bar_reading" ] ; then
            progress_bar_reading="$current_progress"
            echo "$progress_bar_reading"
        fi
        # Take a break to avoid excess load.
        sleep 1
    done
    # Ensure that the progress bar closes if /tmp/file-converter-progress-bar is removed.
    echo "100"
    echo ""
}

filelist=""
file-converter-get_filelist() {
    # Remove the "file://" in front
    # TODO: Support mtp:// , smb:// etc.,
    filelist=$(yad --title="$TITLE" --image=tap-create --center \
        --width=360 --height=240 \
        --text="Welcome to file-converter version ${APP_VERSION}\n\n<b>Please DRAG AND DROP files here , then CLICK OK</b>\n\nYou need not do anything in the terminal that just came up." --text-align=center \
        --button=gtk-ok \
        --dnd \
        --cmd echo "$1" | sed 's/^file\:\/\///' )

    # I think Drag-N-Drop is better than file selection (for multiple files) because we can:
    #  1) Select files from different folders.
    #  2) Use preferred file manager.
    #  3) Use a "Find" utility (both inside the file manager / others like Catfish).
    
    # Remove duplicates from the dragged and dropped files.
    filelist="$(echo "$filelist" | sort -u)"

    # If we didn't select any file, show a message.
    # On clicking OK , show the file selection dialog again.
    # On clicking Cancel, exit now.
    if [ -z "$filelist" ] ; then
        yad_show_info "You have not selected any files." || exit 1
        file-converter-get_filelist
    fi

    # Accept only valid filenames
    local ERR_INVALID_FILES=""
    file_path=""
    while read -r file_path ; do
        if [ ! -f "$file_path" ] || [ ! -r "$file_path" ] ; then
            ERR_INVALID_FILES="true"
        fi
        true
    done <<< "$filelist"

    if [ -n "$ERR_INVALID_FILES" ] ; then
        yad_show_info "Please select valid and readable files"
        file-converter-get_filelist
    fi

}

OUT_FORMAT=""
file-converter-get_OUT_FORMAT() {

# This yad command produces this error for each occurence of \! in $AVAILABLE_OUT_FORMATS :
# (yad:6014): GLib-WARNING **: HH:MM:SS.SSS: g_strcompress: trailing \
# Where 6014 == $(pidof yad) and HH:MM:SS.SSS is the current time.
# Now, it is hidden by 2> /dev/null
# TODO: Find a permanent fix.
RESP=$(yad --title="$TITLE" --image=tap-create --center --width=360 --height=240 \
                --form --field="Output format:CB" "$AVAILABLE_OUT_FORMATS" \
                --text="$FILE_COUNT files will be converted. \n $LO_CONV_MESSAGE \n Press OK to proceed" \
                 2> /dev/null || echo "EXIT NOW")

# Exit on pressing Cancel/Close button.
[ "$RESP" = "EXIT NOW" ] && exit 1

# Remove trailing "|" added by yad
OUT_FORMAT="$(echo "$RESP" | sed 's/|$//g')"

# If we didn't select any format, show a message.
# On clicking OK , show the format selection dialog again.
# On clicking Cancel, exit now.
if [ -z "$OUT_FORMAT" ] ; then
    yad_show_info "Please run again and select a vaild output format." || exit 1
    file-converter-get_OUT_FORMAT
fi

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

if ! which ps > /dev/null ; then
    yad_show_info "Please install ps"
    exit 1
fi

if ! which grep > /dev/null ; then
    yad_show_info "Please install grep"
    exit 1
fi

if ! which sed > /dev/null ; then
    yad_show_info "Please install sed"
    exit 1
fi

if ! which sort > /dev/null ; then
    yad_show_info "Please install GNU coreutils"
    exit 1
fi

if ! which x-terminal-emulator > /dev/null ; then
    yad_show_info "Please install x-terminal-emulator for a better experience"
fi

file-converter-get_filelist

FILE_COUNT="$(echo "$filelist" | wc -l)"

# Detect the input file formats (extension) -- converted to lowercase for case-insensitivity
# Exclude hidden files (filenames starting with a dot ".") and those without any dot "." in their filename.
IN_FORMATS="$(echo "$filelist" | grep -v '^\.' | grep '\.' | sed 's/^.*\.//g' | tr A-Z a-z | sed 's/^$//g' | sort -u)"

# If all the files have no extension or if all of them are hidden files (filenames starting with a dot ".")
[ -z "$IN_FORMATS" ] && yad_show_error_incompatible_format

IN_FORMAT=""
IN_FORMAT_TYPE_PREVIOUS=""

# "\!" separator is for the yad combobox.
# The trailing "\!" is intentional (so that a regex can match all formats equally).

# Ref: https://en.wikipedia.org/wiki/Image_file_formats
# Ref: experimentation with convert-im6.q16
IMAGE_FILE_FORMATS="jpg\!png\!gif\!tiff\!bmp\!heic\!ico\!webp\!"

# Ref: ffmpeg -formats
# BTW I'm not familiar with video formats. So, this list may contain errors.
# TODO: Improve this list
VIDEO_FILE_FORMATS="mp4\!mkv\!webm\!3gp\!avi\!dat\!flv\!m4v\!mov\!rm\!"

# Ref: ffmpeg -formats
# BTW I'm not familiar with audio formats too. So, this list may contain errors.
# TODO: Improve this list
AUDIO_FILE_FORMATS="mp3\!ogg\!wav\!aiff\!aac\!flac\!voc\!"

# Files formats that LibreOffice supports writing
# Ref: https://en.wikipedia.org/wiki/LibreOffice#Supported_file_formats
# Only the most common ones are listed here
LO_WRITE_FILE_FORMATS="pdf\!docx\!xlsx\!pptx\!odt\!ods\!odp\!odg\!odf\!odb\!doc\!ppt\!rtf\!xls\!epub\!html\!slk\!csv\!txt\!xml\!dif\!eps\!mml"

# Files formats that LibreOffice supports reading
# Ref: https://en.wikipedia.org/wiki/LibreOffice#Supported_file_formats
# PDF is intentionally excluded, because it is dealt with separately.
LO_READ_FILE_FORMATS="abw\!zabw\!swf\!pmd\!pm3\!pm4\!\!pm5\!pm6\!p65\!cwk\!ase\!agd\!fhd\!kth\!key\!numbers\!pages\!pdb\!dxf\!csv\!txt\!cdr\!cmx\!cgm\!dif\!dbf\!xml\!eps\!emf\!fb2\!gpl\!gnm\!gnumeric\!hwp\!plt\!html\!htm\!jtd\!jtt\!wk1\!wk3\!wk4\!wks\!123\!pct\!mml\!met\!xls\!xlw\!xlt\!xlsx\!iqy\!xlsx\!pptx\!pxl\!psw\!ppt\!pot\!pub\!rtf\!docx\!doc\!dot\!wps\!wks\!wdb\!wri\!vsd\!pgm\!pbm\!ppm\!odt\!fodt\!ods\!fods\!odp\!fodp\!odg\!fodg\!odf\!odb\!sxw\!stw\!sxc\!stc\!sxi\!sti\!sxd\!std\!sxm\!pcx\!pcd\!psd\!qxp\!wb1\!wq1\!wq2\!sgv\!602\!sgf\!rls\!ras\!svm\!slk\!tga\!\!uof\!uot\!uos\!uop\!wmf\!wpd\!wps\!xbm\!xpm\!zmf\!"

while read IN_FORMAT ; do

    # If a format is known by many extensions , fix one of them
    if [ "$IN_FORMAT" = "jpeg" ] ; then
        IN_FORMAT="jpg"
    elif [ "$IN_FORMAT" = "tif" ] ; then
        IN_FORMAT="tiff"
    elif [ "$IN_FORMAT" = "aif" ] ; then
        IN_FORMAT="aiff"
    elif [ "$IN_FORMAT" = "aifc" ] ; then
        IN_FORMAT="aiffc"
    elif [ "$IN_FORMAT" = "amr" ] ; then
        IN_FORMAT="amrnb"
    elif [ "$IN_FORMAT" = "snd" ] ; then
        IN_FORMAT="au"
    elif [ "$IN_FORMAT" = "awb" ] ; then
        IN_FORMAT="amrwb"
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
    elif [ "$IN_FORMAT" = "htm" ] ; then
        IN_FORMAT="html"
    fi

    if [ "$IN_FORMAT" = "pdf" ] ; then
        IN_FORMAT_TYPE="PDF"
        AVAILABLE_OUT_FORMATS="html\!odg\!jpg\!jpg-OnlyFirstPage\!png\!tiff\!ppm"
    
    elif echo "$LO_READ_FILE_FORMATS" | grep "${IN_FORMAT}\\\!" > /dev/null ; then
        IN_FORMAT_TYPE="DOCUMENT"
        AVAILABLE_OUT_FORMATS="$LO_WRITE_FILE_FORMATS"
        
        LO_CONV_MESSAGE="\nNote: Document file conversion is supported only if LibreOffice supports that conversion.\n"
        USE_LIBREOFFICE="true"
        # Exit with error message if libreoffice is not available
        if ! which libreoffice > /dev/null ; then
            yad_show_info "To convert document files, please install 'libreoffice' from the software store OR with the command\nsudo apt update && sudo apt install libreoffice"
            exit 1
        fi
        
    elif echo "$IMAGE_FILE_FORMATS" | grep "${IN_FORMAT}\\\!" > /dev/null ; then
        IN_FORMAT_TYPE="IMAGE"
        # All image file conversions use convert-im6.q16
        CONVERTER_COMMAND="convert-im6.q16"
        AVAILABLE_OUT_FORMATS="$IMAGE_FILE_FORMATS"
        # Exit with error message if the converter is not available
        if ! which convert-im6.q16 > /dev/null ; then
            yad_show_info "To convert images, please install 'imagemagick' from the software store\nOR with the command\nsudo apt update && sudo apt install imagemagick"
            exit 1
        fi

    elif echo "$AUDIO_FILE_FORMATS" | grep "${IN_FORMAT}\\\!" > /dev/null ; then
        IN_FORMAT_TYPE="AUDIO"
        # All audio file conversions use ffmpeg
        # The -nostdin makes it script-friendly.
        CONVERTER_COMMAND="ffmpeg -nostdin -i "
        AVAILABLE_OUT_FORMATS="$AUDIO_FILE_FORMATS"
        # Exit with error message if the converter is not available
        if ! which ffmpeg > /dev/null ; then
            yad_show_info "To convert audios, please install 'ffmpeg' from the software store\nOR with the command\nsudo apt update && sudo apt install ffmpeg"
            exit 1
        fi
    elif echo "$VIDEO_FILE_FORMATS" | grep "${IN_FORMAT}\\\!" > /dev/null ; then
        IN_FORMAT_TYPE="VIDEO"
        # All video file conversions use ffmpeg
        # The -nostdin makes it script-friendly.
        CONVERTER_COMMAND="ffmpeg -nostdin -i "
        # Add option to extract audio from a video
        AVAILABLE_OUT_FORMATS="Extract-Audio\!${VIDEO_FILE_FORMATS}"
        # Exit with error message if the converter is not available
        if ! which ffmpeg > /dev/null ; then
            yad_show_info "To convert videos, please install 'ffmpeg' from the software store\nOR with the command\nsudo apt update && sudo apt install ffmpeg"
            exit 1
        fi
    else
        yad_show_error_incompatible_format
    fi
    
    # If this is not the first iteration of this while loop, check for incompatibilities between input formats.
    # Example: PDF and VIDEO , DOCUMENT and AUDIO etc., are incompatible.
    [ -n "$IN_FORMAT_TYPE_PREVIOUS" ] && [ "$IN_FORMAT_TYPE_PREVIOUS" != "$IN_FORMAT_TYPE" ] && yad_show_error_incompatible_format
    
    # Store this format as the previous format , getting ready for the next iteration.
    # This is to check for incompatible formats.
    IN_FORMAT_TYPE_PREVIOUS="$IN_FORMAT_TYPE"

done <<< "$IN_FORMATS"

file-converter-get_OUT_FORMAT

# Some special conversions require special modifications.
if [ "$IN_FORMAT_TYPE" = "PDF" ] ; then
    # These are functions defined in the start of this script.
    CONVERTER_COMMAND="file-converter-pdf2${OUT_FORMAT}"
    if [ "$OUT_FORMAT" = "jpg-OnlyFirstPage" ] ; then
        # Do this only AFTER defining $CONVERTER_COMMAND using the previous value of ${OUT_FORMAT}
        OUT_FORMAT="jpg"
    fi
elif [ "$OUT_FORMAT" = "Extract-Audio" ] ; then
    # Get the output format for the extracted audio.
    AVAILABLE_OUT_FORMATS="$AUDIO_FILE_FORMATS"
    file-converter-get_OUT_FORMAT
fi

if [ "$IN_FORMAT_TYPE" = "PDF" ] ; then
    # PDF converters depend on OUT_FORMAT
    if [ "$OUT_FORMAT" = "html" ] || [ "$OUT_FORMAT" = "odg" ] ; then
        LO_CONV_MESSAGE="\nNote: Document file conversion is supported only if LibreOffice supports that conversion.\n"
        USE_LIBREOFFICE="true"
        if ! which libreoffice > /dev/null ; then
            yad_show_info "To convert pdf files to html or odg, please install 'libreoffice' from the software store \nOR with the command\nsudo apt update && sudo apt install libreoffice"
            exit 1
        fi
    else
        if ! which pdftoppm > /dev/null ; then
            yad_show_info "To convert pdf files to images, please install 'poppler-utils' from the software store \nOR with the command\nsudo apt update && sudo apt install poppler-utils"
            exit 1
        fi
    fi
fi

# cd to $HOME before showing folder selection dialog.
# Otherwise, it opens this app's directory to choose folders.
cd "$HOME"
dest_dir=$(yad --title="$TITLE" --image=tap-create --center \
    --text="\nPlease choose the DESTINATION FOLDER\n" \
    --width=600 --height=400 \
    --file --directory || echo "EXIT NOW")
cd - > /dev/null

# Exit on pressing Cancel/Close button.
[ "$dest_dir" = "EXIT NOW" ] && exit 1

# Use a subdirectory of $dest_dir (this makes it easier to avoid conflicts with existing files).
# Name it according to the exact time (including seconds).
dest_dir="$dest_dir"/files-converted-on-$(date +%F)-at-$(date +%I-%M-%S-%p)

if ! mkdir "$dest_dir" ; then
    yad_show_info "Please select a valid, writable folder."
    exit 1
fi

# Initialize and enable the progress bar.
rm -rf /tmp/file-converter-progress-bar
echo "0" > /tmp/file-converter-progress-bar

# Start the progress bar.
progress-bar-monitor_progress | \
    yad --title "$TITLE" --center --progress --width 540 \
        --text="Converting..... Please wait. \n You need not do anything in the terminal that just came up.\nfile-converter does that for you :)\nTo abort, close that terminal window." \
        --percentage=0 --auto-close --no-button &

echo ""
echo "$FILE_COUNT files are going to be converted"
echo ""

# Remove trailing slash in directory name
dest_dir="$(echo "$dest_dir" | sed 's/\/$//g')"

# Some initialization before entering the conversion step.
SUCCESS_COUNT=0
file_path=""
if [ "$USE_LIBREOFFICE" = "true" ] ; then
    LO_NOT_SUPPORTED="\nLibreOffice does not support converting these to $OUT_FORMAT : \n"
fi

while read -r file_path ; do

    FILE_CONV_ERR=""
    # If file_path doesn't exist now (may be deleted after selecting it, or permissions changed recently etc.,) , throw an error for this file.
    if [ ! -f "$file_path" ] || [ ! -r "$file_path" ] ; then
        FILE_CONV_ERR="true"
        echo "$file_path is not a valid, readable file." | tee -a "$dest_dir"/file-converter-errors.log
    fi
    
    # Just the file name without full path or extension.
    # This NEEDS bash (not any other shell).
    file_name_out="$(basename "$file_path")" # Remove full path.
    file_name_out="${file_name_out%.*}" # Remove extension.
    
    if [ -e "$dest_dir"/"$file_name_out".$OUT_FORMAT ] ; then
        # If 2 input files have same name (ignoring extension)
        # Then, a number is appended to the output file name to make it unique.
        
        # Faster O(n*log(n)) way to get last FILE_NUM if it was assigned before to a previous file with a naming conflict..
        # Running a while loop checking for each file's existence is so slow, at O(n^2) ie. > 25 million operations (with bash) for a 5000-page conversion !
        # But, this O(n*log(n)) one is faster ie. basically ls piped to sort and ~ 70,000 operations (inside sort) for a 5000-page conversion.
        cd "$dest_dir"
        FILE_NUM=$(ls *.$OUT_FORMAT | \
        grep "^${file_name_out}\.(" | sed "s/^${file_name_out}\.(//g" | \
        grep ")\.${OUT_FORMAT}\$" | sed "s/)\.${OUT_FORMAT}\$//g" | \
        grep -v '[[:alpha:]]' | grep -v '[[:punct:]]'| \
        grep -v '[[:space:]]' | grep -v '[[:blank:]]' | \
        tr -dc '[:digit:]\n' | sed 's/^$//g' | \
        sort --general-numeric-sort | tail -n 1 )
        cd - > /dev/null
        
        [ -z "$FILE_NUM" ] && FILE_NUM=0
        
        # Get the FILE_NUM for which the output file name won't confict with a previous one
        while [ -e "${dest_dir}"/"${file_name_out}.(${FILE_NUM}).${OUT_FORMAT}" ] ; do
            # BTW how I miss C++'s FILE_NUM++;
            FILE_NUM=$((${FILE_NUM}+1))
        done
        
        # Append FILE_NUM to file_name_out
        file_name_out+=".(${FILE_NUM})"
    fi
    
    # If the yad progress bar was closed, exit now.
    ps -aux | grep -i "yad" | grep -i "progress" | grep -v "grep" > /dev/null || exit 0
    
    echo ""
    echo "Converting $file_path ....."

    if echo "$file_path" | tr A-Z a-z | grep "\.${OUT_FORMAT}\$" ; then
        # Just copy the file if the source and destination extensions are same (case-insensitive match)
        cp "$file_path" "$dest_dir"/"$file_name_out".$OUT_FORMAT
        echo "$file_path is already in output format. Just copying it."
    else
        # Otherwise, do the real conversion
        if [ "$USE_LIBREOFFICE" = "true" ] ; then
            dest_dir_temp="$dest_dir"/"$file_name_out"."$(tr -dc '[:alnum:]' < /dev/urandom | head -c 15 ; echo '')" # A random name
            mkdir "$dest_dir_temp"
            # LibreOffice's document conversion command has a special syntax
            if libreoffice --headless --convert-to "$OUT_FORMAT" --outdir "$dest_dir_temp" "$file_path" 2>&1 | tee /tmp/file-converter-command-stdout-stderr.txt ; then
                if [ "$(ls -a "$dest_dir_temp" | grep -v '^\.$' | grep -v '^\.\.$' | wc -l)" = "1" ] ; then
                    # If there's only one output file, move it
                    mv "$dest_dir_temp"/* "$dest_dir"/"$file_name_out".$OUT_FORMAT
                elif [ "$(ls -a "$dest_dir_temp" | grep -v '^\.$' | grep -v '^\.\.$' | wc -l)" -gt "1" ] ; then
                    # If there are many output files (like in HTML conversion), move it to a directory
                    mkdir "$dest_dir"/"$file_name_out".$OUT_FORMAT
                    mv "$dest_dir_temp" "$dest_dir"/"$file_name_out".$OUT_FORMAT
                fi
            else
                # If we encounter errors, append it to the log.
                FILE_CONV_ERR="true"
                cat /tmp/file-converter-command-stdout-stderr.txt >> "$dest_dir"/file-converter-errors.log
            fi
            # libreoffice --headless --convert-to exits with exit code 0 even if it has an error and can't convert the file.
            # So, we're piping its output to a file and checking for conversions unsupported by LibreOffice.
            # Conversions LO doesn't support have the error message beginning with "Error: no export filter for " in the first line.
            if head -n 2 /tmp/file-converter-command-stdout-stderr.txt | grep '^Error: no export filter for ' > /dev/null ; then
                FILE_CONV_ERR="true"
                # If we encounter errors, append it to the log.
                cat /tmp/file-converter-command-stdout-stderr.txt >> "$dest_dir"/file-converter-errors.log
                # Append IN_FORMAT to LO_NOT_SUPPORTED message (show that it LO doesn't support converting it).
                LO_NOT_SUPPORTED+="$IN_FORMAT "
            fi
            # Clean up
            rm -rf "$dest_dir_temp"
            rm -f /tmp/file-converter-command-stdout-stderr.txt
        else
            # The conversion syntax for all converters except LibreOffice.
            ${CONVERTER_COMMAND} "${file_path}" "${dest_dir}/${file_name_out}.${OUT_FORMAT}" || FILE_CONV_ERR="true"
        fi
    fi
    
    if [ -z "$FILE_CONV_ERR" ] ; then
        echo "$file_path successfully converted"
        SUCCESS_COUNT=$((${SUCCESS_COUNT}+1))
    else
        echo "Failed to convert $file_path" | tee -a "$dest_dir"/file-converter-errors.log
    fi
    # BTW how I miss python and C/C++ math.
    percent=$(((100*${SUCCESS_COUNT})/${FILE_COUNT}))
    # TODO: make the percentage show as a progress bar (like apt and wget do)
    echo ""
    echo "$percent % done ; ${SUCCESS_COUNT}/${FILE_COUNT} files processed."
    echo ""
    # This is for the progress bar to read.
    echo "$percent" > /tmp/file-converter-progress-bar
    
done <<< "$filelist"

# Close the progress bar
rm -f /tmp/file-converter-progress-bar

# Show message for success / failure
# "Success" if all files were converted with exit code 0
# AND $dest_dir contains atleast $FILE_COUNT files/folders other than "." , ".." and logfiles.
if [ "$SUCCESS_COUNT" = "$FILE_COUNT" ] && [ "$(ls -a "$dest_dir" | grep -v '^\.$' | grep -v '^\.\.$' | grep -v '\.log$' | wc -l)" -ge "$FILE_COUNT" ] ; then
    yad --image=tap-create --title "$TITLE" --center --width=360 --height=240 \
        --text="<b>Success - all the files have been converted.</b> \nPress 'View' to view them." \
        --button=View \
        --button=gtk-close || exit 0
    xdg-open "$dest_dir" &
    sleep 1 # Wait for the file manager to open
    exit 0
else
    yad_show_info "<b>Error. Could not convert some files.</b> \n $LO_NOT_SUPPORTED \n Error log is at $dest_dir/file-converter-errors.log" || exit 1
    xdg-open "$dest_dir" &
    sleep 1 # Wait for the file manager to open
fi

exit 1

#!/bin/bash
# Written on 05/05/2024 without teammembers. Submitted on 20/05/2024.

# Looks at subdirectories, finds images in these subdirectories and combines them in a directory called "combined_images". The number before the underscore in the original filename will be kept (as this functions as the label of the image).
# All jpg and tif files will be converted to png images.

#Here I implement a check. I check if ImageMagick is installed, and halt te script if it is not.
#I use command -v, which generates a short description for the program. The description (or error) is redirected to the null device, and it's exit code is used to check for the existance of gnuplot. I could've also used which or type as ways to check for the program, but only 'command' is POSIX compliant, and thus should always work irrespective of shell implementation.
command -v magick >/dev/null 2>&1 || { echo -e >&2 "ImageMagick is required, but not installed. Script will halt"; exit 1; }


# Check if the directory 'combinedImages' exists. If it esists, ask to delete and make empty directory.
# if it doesn't exist, make empty directory.
DIRECTORY_NAME='combined_images'
if [ -d  $DIRECTORY_NAME ]; then
    # Prompt for confirmation to delete
    read -r -p "The directory $DIRECTORY_NAME exists. Do you want to delete it? (y|n): " CHOICE
    case "$CHOICE" in
      y|Y )
        rm -r $DIRECTORY_NAME && echo 'Deletion succesfull.' || echo 'Deletion unsuccesfull' 1>&2
        mkdir $DIRECTORY_NAME;;
      n|N )
        echo 'Deletion aborted.';;
      * )
        echo 'WARNING: Invalid choice. Deletion aborted.' 1>&2;;
    esac
else
    mkdir $DIRECTORY_NAME
fi

# Declare an associative array (bash equivalent of python dictionary) containing information about number count
declare -A NUMBER_COUNT=([0]=1 [1]=1 [2]=1 [3]=1 [4]=1 [5]=1 [6]=1 [7]=1 [8]=1 [9]=1)

for DIR in ./*/; do
    # Make sure the directory where we copy from, is not the one where we combine all images
    if [ "$DIR" != "./${DIRECTORY_NAME}/" ]; then
        for FILE in "$DIR"*
        do
            if [ ! -f "$FILE" ]; then
                echo "WARNING: $FILE is not a file. Will be ignored" 1>&2
            else
                BASE_FILE=${FILE##*/}
                if ! [[ "$BASE_FILE" =~ ^[[:digit:]] ]]; then
                    echo "ERROR: $FILE does not start with number. Terminating" 1>&2
                    exit 1
                elif ! [[ "$BASE_FILE" == *.png || "$BASE_FILE" == *.jpg || "$BASE_FILE" == *.jpeg || "$BASE_FILE" == *.tif ]]; then
                    echo "WARNING: $FILE has suspect file extension. Will be ignored" 1>&2
                else
                    NUMBER=${BASE_FILE:0:1}
                    cp "$FILE" "./${DIRECTORY_NAME}/${NUMBER}_${NUMBER_COUNT[$NUMBER]}.${FILE##*.}"
                    (( NUMBER_COUNT[$NUMBER]++ ))
                fi
            fi
        done
    fi
done


# The following code converts jpg's and tifs to png
for file in "$DIRECTORY_NAME"/*.{jpg,tif}; do
    if [ -f "$file" ]; then
        case "$file" in
            *.jpg) output="${file%.jpg}.png" ;;
            *.tif) output="${file%.tif}.png" ;;
        esac
        # See explanation for the redirect to null bellow
        convert "$file" "$output" 2> /dev/null
        if [ $? -eq 0 ]; then
            rm "$file"
        else
            echo "WARNING: Failed to convert $file" >&2
        fi
    fi
done
# The stderr output of the convert command is redirected to null, because it generated the following warning when converting the tif-files:
# "Convert: Unknown field with tag 50838 (0xc696) encountered. `TIFFReadDirectory' @ warning/tiff.c/TIFFWarnings/945"
# This is probably being caused by the fact that some people used tools like Fiji to cut the images. I think Fiji adds metadata to the .tif-files
# that cannot be interpreted by ImageMagick, resulting in a warning.
# Probably a better solution than redirecting all errors to null, would be the deletion of the metadata using a tool like 'exiftool'. This would
# still allow for other errors to be printed. I didn't implement it, even though I think it is the superior solution, because it was out of scope.

echo 'Program Execution Finished'

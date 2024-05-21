#!/bin/bash

# Written on 16/05/2024. Submitted on 20/05/2024.
# This script cuts out numbers from a large image (imagename supplied via terminal) and put it in a directory in the pwd named 'output'.
# The numbers will be stored as png-images with file NUMBERONIMAGE_RANDOMCOUNTER.

#Order of the numbered rows in the image (from top to bottom)
NUMBERORDER=(0 9 8 7 6 5 4 3 2 1)
#Amount of numbers in a row of the image
NUMPERROW=10


#Here I implement a check. I check if ImageMagick is installed, and halt te script if it is not.
#I use command -v, which generates a short description for the program. The description (or error) is redirected to the null device, and it's exit code is used to check for the existance of gnuplot. I could've also used which or type as ways to check for the program, but only 'command' is POSIX compliant, and thus should always work irrespective of shell implementation.
command -v magick >/dev/null 2>&1 || { echo >&2 "ImageMagick is required, but not installed. Script will halt"; exit 1; }

#Test if user didn't supply the filename
if [ $# -eq 0 ]; then
    echo >&2 "No arguments supplied. Please provide the filename of the large image as an argument for this script."
    exit 1
fi

#filename should be supplied via terminal
FILENAME=$1
[ -f "$FILENAME" ] || { echo >&2 "$FILENAME not present in working directory. Script will halt"; exit 1; }

#Check if output directory already exists. If it does exist, ask before removing. Script will halt if it cannot be overwritten.
if [[ -d "./output" ]]; then
    echo "Error: output directory 'output' is already present. It will be overwritten by this script."
    #read -p to prompt the user and reading his answer.
    read -p "Do you want to continue'? y|Y|yes to delete: " answer
    case $answer in
        y | Y | yes)
        rm -r './output';
        ;;
        *)
        echo "Nothing has been deleted. Script will halt";
        exit 1;
        ;;
    esac
fi

mkdir output
cd output || { echo >&2 "Could not cd to output directory. Script will halt"; exit 1; }
magick "../$FILENAME" -crop 10x10@ raw-%09d.png


#There is a limit of the amount of images that can be cut out in one go (1 billion). This limit is caused by the amount of numbers used in the filename (9).
if (( ${#NUMBERORDER[@]}*NUMPERROW>1000000000 )); then
    echo >&2 "Error: The number of elements in NUMBERORDER times NUMPERROW exceeds the maximum of 1,000,000,000. Script will halt.";
    exit 1;
fi


for i in "${!NUMBERORDER[@]}"; do
    for ((j=0; j<NUMPERROW; j++)); do
        let IMAGENUMBER=j+i*NUMPERROW;
        IMAGENAME=$(printf "raw-%09d.png" $IMAGENUMBER);
        mv "$IMAGENAME" "${NUMBERORDER[$i]}_${j}.png"
        done
done

echo "Script execution finished."

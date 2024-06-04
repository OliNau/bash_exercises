#!/bin/bash
#Submitted on 03/03/2024

#Error check: script will halt and give an error if required .zip file is not present in the working directory. 
if [[ ! -f "./BoekHoofdstukken.zip" ]]; then
    echo "Error: 'BoekHoofdstukken.zip' not present in the working directory. Script will halt." 
    exit
fi 

#Error check: check if output directories are already present. Ask the user if these files can be deleted.
if [[ -d "./Books" || -d "./CompleteBooks" || -d "./BoekHoofdstukken" ]]; then
    echo "Error: output directories 'Books' and/or 'CompleteBooks' and/or 'BoekHoofdstukken' are already present. It is advised to delete them before running the script."
    read -p "Do you want to delete the above-mentioned directories'? y|Y|yes to delete: " answer #read -p to prompt the user and reading his answer.
    case $answer in
        y | Y | yes)
        rm -rf "./Books" "./CompleteBooks" "./BoekHoofdstukken"
        ;;
        *)
        echo "Nothing has been deleted"
        ;;
    esac
fi
    
#Implementation of a verbose mode: give extra output to console if -v or --verbose flags are supplied. Implentation based on example 03_looping_with_flags from Blackboard.
VERBOSE=0
if [[ $1 = -v || $1 = --verbose ]]; then
    VERBOSE=1    
    echo "===Verbose mode is active.==="
fi



#All initialization and error checking done. Main program starts
#Unzip the supplied file. If statement on one line: if verbose equals one 

#If statement using ternary operators. If verbose is set to one (when verbose flag is supplied), it will give an additional echo to signal start of unzip.
#Use VERBOSE (without the dollar sign), because it is an arithmetic variable in an arithmetic context ((...)) and this seems to be preferred by bash.
#Give option -e to allow interpretation of backslash characters (this is required for the newline character to work.)
(( VERBOSE )) && echo -e "\n=======Start unzip=======" 
#Unzip BoekHoofdstukken.zip. If verbose is set to one, unzip it with usual output to the prompt. If verbose is unset, it will unzip with option -q (which supresses output to prompt).
(( VERBOSE )) && unzip BoekHoofdstukken.zip || unzip -q BoekHoofdstukken.zip 
#If verbose is set, this will signal the finished execution of the unzip command. The variable $? contains the exit code of the unzip command (and not from the if-statement one might presume).
(( VERBOSE )) && echo -e "=======Finished unzip with exit code: $? =======  \n\n\n"


#Define the function sort_books. This function gets executed whenever the 'find' command gets executed. 
# This function expects two inputs: the full location of the book and the bookname. Of course the bookname can be determined from the full book location, but it has already been calculated, so might as well be used. 
sort_books () {
    #We define local variables. They are not needed outside this function, so it is better to 
    local WITHOUTPREFIX=${1#./BoekHoofdstukken}
    local CHAPTERWITHSLASH=${WITHOUTPREFIX%p*.txt} #
    local CHAPTERWITHOUTSLASH=${CHAPTERWITHSLASH//\//} #Replace all forward slashes with nothing. (This removes the slashes)
    cp $1 ./Books/${2}/B${2}-C${CHAPTERWITHOUTSLASH}.txt
}
#export needed to export the function so it can be executed by the subshell which is activated whenever 'bash' gets executed by the 'find' command.
export -f sort_books

#Create a directory `Books'. It will contain all the book-directories.
mkdir Books
(( VERBOSE )) && echo "=======Start chapter sort=======" 

#All books contain a chapter 0. So We iterate over all the files in the chapter 0 directory. 
for BOOK in "./BoekHoofdstukken/0/"*.txt
do
    #Remove all unnecessary information for the $BOOK variable. To do this, I used `bash parameter substitution'.
    # Use % te remove the shortest possible pattern from the end.
    BOOKWITHOUTSUFFIX=${BOOK%.txt}
    # Use ## Te remove the longest possible pattern from the start.
    BOOKNAME=${BOOKWITHOUTSUFFIX##*/p}
    #If verbose is set, give additional info about execution
    (( $VERBOSE )) && echo "Loop currently at book: $BOOKNAME"
    #Create a new directory in the `Books' directory. This new directory simply has the book code as its name, and will contain all the chapters that are part of one book.
    mkdir ./Books/$BOOKNAME

    #Use find to find all files that have the current bookname in its filename. 
    #We use type -f to make sure we only find files (otherwise find also returns directories). 
    #We use -exec bash to execute a bash subshell. option `-c' is necessary to be able to give a string as input. `{}` contains the result of the find.
    find ./BoekHoofdstukken -type f -name "*p${BOOKNAME}.txt" -exec bash -c "sort_books {} $BOOKNAME" \;
done
(( VERBOSE )) && echo -e "=======chapter sort finished with exit code: $? =======\n\n\n" 

#Create a directory `CompleteBooks' which contains the concatenated books.
mkdir CompleteBooks
echo "=======Start book concatenation=======" 

#Loop over every BOOK in the ./Books directory.
for BOOK in "./Books"/*
do 
    #Create an empty file with the correct name.
    touch ./CompleteBooks/B${BOOK##*/}.txt
    #ls -lv to sort by name:natural order (1<2<11), instead of the default alphabetical order (1<11<2). awk $NF to only print the last field. 'tail -n +2' to skip the first line (which contains total filesize.)
    CHAPTERS=$(ls -lv "$BOOK" | awk '{print $NF}' | tail -n +2)
    #Loop over the different chapters that are present in my Book directory.
    for CHAPTER in $CHAPTERS
    do
      #Append the content of the chapter to the newly made file.
      cat "${BOOK}/${CHAPTER}" >> ./CompleteBooks/B${BOOK##*/}.txt
    done
    #The rest is only to give a nice table with overview about the different books, with title, author, size, etc.
    #du -k to get the filesize in kilobyte. awk '{print $1}' only gets the first field.
    FILESIZE=$(du -k ./CompleteBooks/B${BOOK##*/}.txt | awk '{print $1}') 
    #grep -m 1 means grep will stop the search after the first occurrence. $1="Deletes the first field (which is; `Author:' )" and $0 gets all the remaining fields.
    AUTHOR=$(grep -m 1 "Author: " "./CompleteBooks/B${BOOK##*/}.txt" | awk '{$1=""; print $0}')
    #Idem above
    TITLE=$(grep -m 1 "Title: " "./CompleteBooks/B${BOOK##*/}.txt" | awk '{$1=""; print $0}')
    
    #$COLUMNS gives info about the current width of the console window.
    AUTHOR_TITLE_WIDTH=$(($COLUMNS / 4)) #Note: / will do floor division, so we will never overshoot our maxwidth.
    CODE_SIZE_WIDTH=$(($COLUMNS / 20))
    
    #If the author or title are too long, printf will truncate them. Here I add three dots to show the name has been truncated.
    (( ${#AUTHOR} > $AUTHOR_TITLE_WIDTH )) && AUTHOR="${AUTHOR:0:$((AUTHOR_TITLE_WIDTH-3))}..."
    (( ${#TITLE} > $AUTHOR_TITLE_WIDTH )) && TITLE="${TITLE:0:$((AUTHOR_TITLE_WIDTH-3))}..."
    printf "Code:%${CODE_SIZE_WIDTH}d | Author:%-${AUTHOR_TITLE_WIDTH}.${AUTHOR_TITLE_WIDTH}s | Title:%-${AUTHOR_TITLE_WIDTH}.${AUTHOR_TITLE_WIDTH}s | Size: %${CODE_SIZE_WIDTH}s kb\n" "${BOOK##*/}" "$AUTHOR" "$TITLE" "$FILESIZE"
done 
echo -e "=======Book concatenation finished with exit code: $? =======\n\n\n"

#Move to the books directory. If cd fails (for example, due to insufficient permissions), the code needs to exit immediately, to prevent removing files in the wrong directories.
cd ./Books || { echo -e "cd to ./Books failed with exit code: $? \t Script will stop"; exit; }
#Loop over all the books
echo "=======Start removing smallest and largest chapter from the Books directory======="
for BOOK in "."/*
do
    #Find the the smallest chapter: ls -Sr does reverse size sort (smallest file at the top of the output) and head -1 only selects the first line.
    SMALLESTCHAPTER=$(ls -Sr $BOOK | head -1)
    #The way we find size is completely the sam 
    SMALLESTCHAPTERSIZE=$(du -k ${BOOK}/${SMALLESTCHAPTER} | awk '{print $1}')
    #Find the largest chapter: ls -Sr does size sort (largest file at the top of the output) and head -1 only selects the first line.
    LARGESTCHAPTER=$(ls -S $BOOK | head -1)
    LARGESTCHAPTERSIZE=$(du -k ${BOOK}/${LARGESTCHAPTER} | awk '{print $1}')
    #Remove the smallest and largest chapter.
    rm ${BOOK}/${SMALLESTCHAPTER}
    rm ${BOOK}/${LARGESTCHAPTER}
    #Remove pre and suffix for next printf statement.
    SMALLESTCHAPTERPRINT=${SMALLESTCHAPTER#B*-}; SMALLESTCHAPTERPRINT=${SMALLESTCHAPTERPRINT%.txt};
    LARGESTCHAPTERPRINT=${LARGESTCHAPTER#B*-}; LARGESTCHAPTERPRINT=${LARGESTCHAPTERPRINT%.txt};
    #Here the output doesn't get truncated based on console width because the majority of the text being printed is typed (the variables only amount to a small fraction of total print length).
    #If the contents have to be displayed on a small screen, it might be better to split the line below in halve. (this can even be done automatically based on $COLUMN size but is out of scope.)
    printf "Book %3d : Removed smallest chapter %-4.4s (size: %3dkb) and largest chapter %-4.4s (size: %5dkb) \n" ${BOOK#./} ${SMALLESTCHAPTERPRINT} $SMALLESTCHAPTERSIZE ${LARGESTCHAPTERPRINT} $LARGESTCHAPTERSIZE
done 
echo -e "=======Finished removing smallest and largest chapter with exit code: $?======="
echo -e "=======END OF SCRIPT======="



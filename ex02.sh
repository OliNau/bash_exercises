#! /bin/bash

#Submitted on 17/03/2024

###Start of excercise 1.1
#Error checking and preparation. The first two checks (no Boekhoofdstukken zip file, or zip already unzipped), are largely copied from my previous script( with small improvements like writing to stderr and exit codes). For comments, I refer to my code for the previous excercise.
#I perform the error checking exercise per exercise. In reality I would perform them all at the top of the file, but I do this to make grading more easy.
if [[ ! -f "./BoekHoofdstukken.zip" ]]; then
    echo "Error: 'BoekHoofdstukken.zip' not present in the working directory. Script will halt." >&2
    exit 1
fi

if [[ -d "./BoekHoofdstukken" ]]; then
    echo "Error: output directory 'BoekHoofdstukken' is already present. It is advised to delete it before running the script." >&2
    read -p "Do you want to delete the above-mentioned directories'? y|Y|yes to delete: " answer #read -p to prompt the user and reading his answer.
    case $answer in
        y | Y | yes)
        rm -rf "./BoekHoofdstukken"
        ;;
        *)
        echo "Nothing has been deleted"
        ;;
    esac
fi

#Here I implement an additional check. Gnuplot is not installed by default. So I check if it is installed, and halt te script if it is not.
#I use command -v, which generates a short description for the program. The description (or error) is redirected to the null device, and it's exit code is used to check for the existance of gnuplot. I could've also used `which` or `type` as ways to check for the program, but only 'command' is POSIX compliant, and thus should always work irrespective of shell implementation.
command -v gnuplot > /dev/null 2>&1 || { echo -e "gnuplot is required, but not installed. Script will halt" >&2; exit 1; }

VERBOSE=0
if [[ $1 = -v || $1 = --verbose ]]; then
    VERBOSE=1
    echo "===Verbose mode is active.==="
fi

#Initialization and error checking done. Main program starts
#1.1.1.1
(( VERBOSE )) && echo -e "\n=======Start ex. 1.1.1.1.======="
#FNR gives the current line number. awk allows immediate arithmetic. The BEGIN keyword is used to only execute one time, when awk begins its run.
awk 'BEGIN {print "xav y" > "data_mod.txt"}   FNR>5 {print ($1+$2)/2, $3 >> "data_mod.txt"}' data.txt
(( VERBOSE )) && echo -e "=======Finished ex. 1.1.1.1 With exit code: $? =======  \n\n\n"

#1.1.1.2 (bonus question)
#Persist is necessary so the plot windows stay open after the program exits.
#the <<- syntax is heredoc format: It reads until it sees EOF again, and passes it all into the gnuplot command. - just deletes leading tabs, and isn't even necessary in this case.
(( VERBOSE )) && echo -e "\n=======Start ex. 1.1.1.2.======="
gnuplot --persist <<-EOF
set title "Multiplicity distribution"
set xlabel "xav"
set ylabel "y"
set grid

#This next line can be ommited if one wants a more modern looking plot.
set term dumb

#skip 1 skips the first line, which only contains text (and no numeric data). Trying to plot this, would generate an error . pt (point type) '*' makes sure a star is used to display the points, otherwise the default would be the letter A'.
#the 'title' keyword sets the legend.
plot "data_mod.txt" skip 1 pt "*" title "data ex. 1.1"
EOF
(( VERBOSE )) && echo -e "=======Finished ex. 1.1.1.1 With exit code: $? =======  \n\n\n"

#1.1.2
(( VERBOSE )) && echo -e "Start ex. 1.1.2\n=======Start unzip======="
(( VERBOSE )) && unzip BoekHoofdstukken.zip || unzip -q BoekHoofdstukken.zip
#If verbose is set, this will signal the finished execution of the unzip command. The variable $? contains the exit code of the unzip command (and not from the if-statement one might presume).
(( VERBOSE )) && echo -e "=======Finished unzip with exit code: $? =======  \n\n\n"

cd BoekHoofdstukken || { echo "Couldn't change directory to BoekHoofdstukken. Script will halt"  >&2 ; exit 1;}

#Use single quotes to pass it to bash as a literal and prevent interpretation of the backslash character.
#To pass a literal backslash to awk, it needs to be escaped by another backslash. So when the shell encounters \\, it translates it to \ before passing it to awk.
SEARCHWORDS='\\<the\\> \\<plates\\> \\<safe'

#Cleanup the variable names for printing (adding stars when necessary and removing brackets).
for WORD in $SEARCHWORDS
do
    if [[ "$WORD" != '\\<'* ]]; then
        PRINTWORD="*${WORD}"
    else
        PRINTWORD=${WORD:3}
    fi
    if [[ "$WORD" != *'\\>' ]]; then
        PRINTWORD="${PRINTWORD}*"
    else
        PRINTWORD=${PRINTWORD:0:-3}
    fi
    PRINTWORDS+="$PRINTWORD "
done

#Replace spaces with pipes to make it easier to see the different words
(( VERBOSE )) && echo "Finding occurences for: ${PRINTWORDS//' '/'|' }"

#Construct an empty array. This array will hold 1) bookname 2) number of occurences for each of the SEARCHWORDS
for BOOK in "./0/"*.txt
do
    BOOKNAME=${BOOK#./0/p}; BOOKNAME=B${BOOKNAME%.txt}
    # () necessary for append syntax
    RESULTARRAY+=( "$BOOKNAME" )
	for WORD in $SEARCHWORDS
	do
		(( VERBOSE )) && echo "Loop at book: ${BOOK} and word: ${WORD}"

        #I initially implemented ex.1.1.2 with grep to match the occurences. I have however rewritten this to use only awk. I will show the commented grep code as a reference.
		#Grep -o: to only output the text, and not the whole line. If this is not present, it will not count words if they are on the same line.
		#wc finds the number of lines outputted by grep. So for each book, bash will output N lines where N is het amount of chapters of the book, and the number on the line, represents the amount of occurences in the chapter.
		#awk sums all these values (from the different chapters) to get the complete amount of occurences in the book.
		#grep implementation: much simpeler.
		#MATCHES=$( find . -name ${BOOK##*/} -exec bash -c "grep -iow "$WORD" {} | wc -l " \; | awk '{ SUM += $1} END { print SUM }'; )

        #Now the awk implementation:
		#-v passes a variable to awk. IGNORECASE=1 makes the search case insesnitive. Then awk will try to match the current line ($0) to variable CURRENTWORD (\<XXX\> only matches complete words.)
		#If a match is found, the counter will be increased, the current line variable is shortened, and awk keeps trying to match. At the end, the amount of matches with a certain word for a certain chapter of a certain book will be printed.
		#The output of the find command is N lines, where N is the amount of chapters in $BOOKNAME, where each line shows the amount of matches in this chapter with $WORD. This is then passed to a second awk command that sums all these lines together to get a total amount of matches per book. The result is saved in a variabele: MATCHES
		MATCHES=$(find . -name "${BOOK##*/}" -exec awk -v CURRENTWORD="$WORD" 'BEGIN {IGNORECASE=1} {while (match($0, CURRENTWORD)) {count++; $0=substr($0, RSTART+RLENGTH)}} END {print count}' {} \; | awk '{ SUM += $1} END { print SUM }';)

        #The variable $MATCHES is written to the array RESULTARRAY
        RESULTARRAY+=( "$MATCHES" )
	done
done

#AMOUNTOFWORDS contains the amound of SEARCHWORDS for which we check occurences.
AMOUNTOFWORDS=$( echo "$SEARCHWORDS" | wc -w )
#AMOUNTOFCOLLUMNS is AMOUNTOFWORDS plus one, because we also need to print the bookname.
AMOUNTOFCOLLUMNS=$(( AMOUNTOFWORDS+1 ))
#AMOUNTOFARRAYELEMENTS is the total amount of elements in the RESULTARRAY, we use this to loop untill we have printed all elements in the array.
AMOUNTOFARRAYELEMENTS=${#RESULTARRAY[@]}

#Print collumn names
printf "%-10s|" "BOOK"
for WORD in $PRINTWORDS
do
    printf "%10.10s|" "$WORD"
done

#print seperator between collumn titles and table content.
#We cannot use brace expansion {} for the for loop, because brace expansion happens before variable expansion, and the code wouldn't run. This is why we need to use the 'seq' command. However this is part of GNU coreutils, and not POSIX compliant.
echo ; for i in $(seq 1 $AMOUNTOFCOLLUMNS); do echo -n '-----------'; done; echo ;

#i SMALLER than amountofarrayelements because array starts counting at zero, we don't want to get beyond it.'
for ((i = 0; i < AMOUNTOFARRAYELEMENTS ; i+=AMOUNTOFCOLLUMNS))
do
    printf "%-10.10s|" "${RESULTARRAY[i]}"
    #j=1 to skip the first element of the line, which is the bookname. This is the only string, so will be handled differently by the line above.
    #Dollar sign is unnessary on arithmetic variables
    for (( j = 1; j < AMOUNTOFCOLLUMNS; j++ ))
    do
        printf "%10d|" "${RESULTARRAY[(( i + j ))]}"
    done
    echo
done


#1.1.2.4 (bonus)
(( VERBOSE )) && echo -e "Start ex. 1.1.4"

BOOKNAMES='p18.txt p25.txt p80.txt p82.txt'
for BOOK in $BOOKNAMES
do
    #because it is an awk excercise I tried to do it all in awk.
    find . -name "${BOOK}" -exec awk -v BOOK="$BOOK" '{
    #Remove punctuation (gsub means global substitutian)
    gsub(/[[:punct:]]/, "", $0);
    for(i=1; i<=NF; i++) {
        #Exclude digits from the count.
        if ($i !~ /[[:digit:]]/){
            #Convert word to lowercase, so every occurence is counted.
            word = tolower($i);
            #word_count is an associative array (the equivalent of a dictionary in python)
            word_count[word]++;
        }
    }
}
END {
    #Book title
    print "========================================"
    print "Most/least occuring words for: " BOOK
    print "========================================"
    #Most occuring words
    print "Top 10 most repeated words:";
    print "-------------------------------"
    printf("%-15.15s %15.15s\n", "Word", "Occurences")
    print "-------------------------------"
    #asorti(source, destination) reads associative array "source" and outputs it sorted to "destination".
    n = asorti(word_count, sorted_words, "@val_num_desc");
    #Also i<n to prevent array out of bounds when there are less than 10 variables (for very short texts)
    for (i=1; i<=10 && i<=n; i++) {
        printf("%-15.15s %15d\n", sorted_words[i], word_count[sorted_words[i]])
    }
    print "==============================="

    #Least occuring words
    print "Top 10 least repeated words:";
    print "-------------------------------"
    printf("%-15.15s %15.15s\n", "Word", "Occurences")
    print "-------------------------------"
    n = asorti(word_count, sorted_words, "@val_num_asc");
    for (i=1; i<=10 && i<=n; i++) {
        printf("%-15.15s %15d\n", sorted_words[i], word_count[sorted_words[i]])
    }
    print "===============================\n\n"
}' {} +
done
(( VERBOSE )) && echo -e "=======Finished ex. 1.1.2.4 With exit code: $? =======  \n\n\n"


###Start of excercise 1.2
#Error Checking and Initialization
#Currently in subdirectory ./BoekHoofdstukken. Move back up
cd ..|| { echo "Couldn't change to parrent directory. Script will halt" >&2; exit 1;}

if [[ ! -f "./jung.tex" ]]; then
    echo "Error: 'jung.tex' not present in the working directory. Script will halt." >&2
    exit 1
fi

if [[ -f "./jung_mod.tex" ]]; then
    echo "Error: output file 'jung_mod.tex' is already present. This script will overwrite this file."
    read -p "Do you want to continue? y|Y|yes to delete: " answer #read -p to prompt the user and reading his answer.
    case $answer in
        y | Y | yes)
        #true functions as a 'pass' (like python has)
        true
        ;;
        *)
        echo "Halting script to prevent overwriting jung_mod.tex" >&2
        exit 1
        ;;
    esac
fi


#start of the usefull code
#copying is a command that can fail if there are insufficient permissions. So an aditional error is implemented.
cp jung.tex jung_mod.tex || { echo "Couldn't copy file jung.text. Script will halt" >&2; exit 1;}

#There is only one occurence of the name 'Hannes Jung' in the whole file, so the next commented line would be sufficient. However, it is better to provide more context (with the \author{} environment) because it reduces the chance of unwanted subsitutions.
#alternative, simpeler code: sed -i 's/Hannes\ Jung/Jos\ Peeters/' jung_mod.tex
#The following code is more robust
#i tells sed to update the file. 's starts subsitution of the pattern in between the forward slashes. \(...\) are capturing groups: their content can be retrieved with \1, \2. .* is a regex expression meaning (any character (.) any number of times (*))
(( VERBOSE )) && echo -e "\n=======Start ex. 1.2.1.======="
sed -i 's/\\author{\(.*\)Hannes Jung\(.*\)}/\\author{\1Jos Peeters\2}/g' jung_mod.tex
(( VERBOSE )) && echo -e "=======Finished ex. 1.2.1 With exit code: $? =======  \n\n"

#Nice feature: giving the -E switch activates 'Extended Regular Expressions', which doesn't require a backslash for the capturing groups (it can be omitted in this example, but then the parantheses would need to be escaped). '\U' is responsible for converting the text to uppercase, and 'g' is required for a global replace, which replaces all occurences on the same line (probably not necessary with this example, but it seems like a good idea).
(( VERBOSE )) && echo -e "\n=======Start ex. 1.2.2.======="
sed -Ei 's/\\section\{(.*)\}/\\section\{\U\1\}/g' jung_mod.tex
(( VERBOSE )) && echo -e "=======Finished ex. 1.2.2 With exit code: $? =======  \n\n"

# By default sed uses POSIX Basic Regular Expressions, which don't include the | alternation operator. You can switch it into using Extended Regular Expressions. Here the -E is absolutely required.
#There are no figures wrapfigures, or differently.
(( VERBOSE )) && echo -e "\n=======Start ex. 1.2.3.======="
sed -Ei '/\\begin\{(figure|wrapfigure)\}*/,/\\end\{(figure|wrapfigure)\}/d' jung_mod.tex
(( VERBOSE )) && echo -e "=======Finished ex. 1.2.3 With exit code: $? =======  \n\n"

#^ means start of line while $ means end of line. #We need the [[:space:]] because the lines are not really empty, but contain whitespaces.
# sed -n '$=' has the same functionality as '| wc -l '. The latter is a more logical choice, but I chose the former because it is a sed-exercise.
#-n is required to suppress automatic printing, and only print what is matching: it prints all lines that don't start with a percentage sign or are only spaces (empty lines). $= prints the line number of the last line ($ means last lign and = prints its line number).
(( VERBOSE )) && echo -e "\n=======Start ex. 1.2.4.======="
NUMBEROFLINES=$(sed -n '/^%\|^[[:space:]]$/!p' jung.tex | sed -n '$=')
printf "In total there are %d lines in the file jung.tex, excluding comments and blank lines. \n" "$NUMBEROFLINES"
(( VERBOSE )) && echo -e "=======Finished ex. 1.2.4 With exit code: $? =======  \n\n"


###Start of excercise 1.3
#Error Checking and Initialization
if [[ ! -f "./space bodies sim.zip" ]]; then
    echo >&2 "Error: 'space bodies sim.zip' not present in the working directory. Script will halt."
    exit 1
fi

if [[ -d "space_bodies_sim" ]]; then
    echo "Error: output directory 'space_bodies_sim' is already present. It is advised to delete it before running the script." >&2
    read -p "Do you want to delete the above-mentioned directories'? y|Y|yes to delete: " answer #read -p to prompt the user and reading his answer.
    case $answer in
        y | Y | yes)
        rm -rf "space_bodies_sim"
        ;;
        *)
        echo "Nothing has been deleted"
        ;;
    esac
fi

#Main program starts
(( VERBOSE )) && echo -e "Start ex. 1.3\n=======Start unzip======="
#Use -d to unzip to a certain directory: otherwise the files will simply be dumped in the working directory.
(( VERBOSE )) && unzip "./space bodies sim.zip" -d 'space_bodies_sim' || unzip -q "./space bodies sim.zip" -d 'space_bodies_sim'
#If verbose is set, this will signal the finished execution of the unzip command. The variable $? contains the exit code of the unzip command (and not from the if-statement one might presume).
(( VERBOSE )) && echo -e "=======Finished unzip with exit code: $? =======  \n\n\n"

cd 'space_bodies_sim'|| { echo "Couldn't change directory to 'space_bodies_sim'. Script will halt" >&2; exit 1;}

(( VERBOSE )) && echo -e "\n=======Start ex. 1.3.1.======="
for FILE in *.txt
do
	(( VERBOSE )) && printf "Currently at file: '%s'\n" "$FILE"
	#Cut based on delimeter (-d) '$'. -f1- selects from the first to the last collumn and prints.
	cut -d '$' -f1- --output-delimiter=" " "$FILE" > whitespace_"${FILE}"
done
(( VERBOSE )) && echo -e "=======Finished ex. 1.3.1 with exit code: $? ======= \n\n"

(( VERBOSE )) && echo -e "\n=======Start ex. 1.3.2.======="
paste whitespace_*.txt > combined.txt
(( VERBOSE )) && echo -e "=======Finished ex. 1.3.2 with exit code: $? ======= \n\n"


(( VERBOSE )) && echo -e "\n=======Start ex. 1.3.3.======="
sed '/^#/d; /^[[:space:]]*$/d' "combined.txt" | tr '[:lower:]' '[:upper:]' > combined_and_cleaned.txt
(( VERBOSE )) && echo -e "=======Finished ex. 1.3.3 with exit code: $? ======= \n\n"

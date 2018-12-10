#!/bin/bash

function help() {
    cat <<EOF
    Iterate through a folder tree storing BLAST RESULTS as logFile_InR6 and json files.
    Generate a unique json file with list of Psicquic interactors along w/ their homologs in R6
    Usage:
    generateHitList.sh -i DATA_DIR -o OUTPUT_JSON_FILE
    Options:
    -l ID_TEMPLATE_WR6_LIST
    --force
    Where,
        DATA_DIR is the location of the result folder tree, by default all uniprot identifer will be processed
        OUTPUT_JSON_FILE is the location of the file to dump the results, default="default.json"
        ID_TEMPLATE_WR6_LIST is a specific list of valid uniprot identifiers extracted from a PSICQUIC record which have R6 homologs
        FORCE not set will make the script stop at any folder with missing files
EOF
}






OUTPUT_JSON_FILE="default.json"

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
   	-l|--list)
    ID_TEMPLATE_WR6_LIST="$2"
    shift # past argument
    shift # past value
    ;;
	-i|--input)
    DATA_DIR="$2"
    shift # past argument
    shift # past value
    ;;
    -o|--output)
    OUTPUT_JSON_FILE="$2"
    shift # past argument
    shift # past value
    ;;
    --force)
    FORCE="TRUE"
    echo "Skipping empty folder";
    shift # past argument
    ;;
    -h|--help)
    help; exit 1;
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done

if [ -z "DATA_DIR" ]
    then
    help 
    exit 1
fi

if [ ! -d "$DATA_DIR" ]
    then
    help 
    exit 1
fi

jsonString=""
total=0
nonEmpty=0
for iDir in $(find $DATA_DIR -mindepth 2 -name "*" -type d)
do
    ##echo "##$iDir"
    ((total++))
    if [ ! -e $iDir/logFileInR6 ]
        then
        (>&2 echo  "File not found : $iDir/logFileInR6")
        [ "$FORCE" != "TRUE" ] && exit 1;
    fi
    if [ -s $iDir/logFileInR6 ] 
        then
        ((nonEmpty++))
        name=`echo $iDir | perl -pe 's/^.*\/([^\/]+)$/$1/'`
        jsonString=$jsonString$(echo -n "\"$name\" : ")
        jsonString=$jsonString$(
            perl -ne '
            BEGIN{ @all = (); }
                chomp;
                if($_ =~ /^[\s]*$/) { next; }
                @t = split(/[:,]/, $_); 
                @t2 = map {"\"" . $_ . "\""} @t;
                push(@all, "[" . join(",", @t2) . "]");
                END{ print( "[" . join(",", @all) . "]\n"); }
            ' $iDir/logFileInR6
            )
    fi
done 

echo $jsonString | perl -ne 'chomp; @all = split(/(?<=\]\])/); print "{\n" . join(",\n", @all) . "\n}\n" ' > $OUTPUT_JSON_FILE

echo  "Processed $nonEmpty out of $total"
exit 1


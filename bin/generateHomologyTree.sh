#!/bin/bash

function help() {
    cat <<EOF
    Iterate through a folder tree storing BLAST RESULTS to accumlate homology search results.
    Generate a unique json file with list of Psicquic interactors along w/ their homologs in R6
    Usage:
    generateHomologyTree.sh -i DATA_DIR -o OUTPUT_JSON_FILE
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
    name=`echo $iDir | perl -pe 's/^.*\/([^\/]+)$/$1/'`
    if [ -s $iDir/$name.json ] 
        then
        ((nonEmpty++))
        jsonString=$jsonString$(perl -pe 's/^\{//;s/\}$/#/' $iDir/$name.json)
    fi
done 
echo $jsonString | perl -ne 'chomp;@all=split(/\#/); print "{\n" . join(",\n",@all) . "\n}\n";' > $OUTPUT_JSON_FILE

echo  "Processed $nonEmpty out of $total"
exit 1


#echo $jsonString | perl -ne 'chomp; @all = split(/(?<=\]\])/); print "{\n" . join(",\n", @all) . "\n}\n" ' > $OUTPUT_JSON_FILE


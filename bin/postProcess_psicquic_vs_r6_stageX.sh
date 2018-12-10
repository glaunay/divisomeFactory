#!/bin/bash

function help() {
    cat <<EOF
    Parse blast result file to create logFileInR6 file in each folder result 
    Usage:
    postProcess_psicquic_vs_r6_stage1.sh -i BLAST_OUTPUT_DIR -o OUTPUT_DIR -l UNIPROT_ID_LIST -q R6_INDEX
    Where,
        BLAST_OUTPUT_DIR is the location of the result folder tree
        UNIPROT_ID_LIST is a list of valid uniprot identifiers extracted from a PSICQUIC record
        OUTPUT_DIR the directory to write to
        R6_INDEX is a R6 protein list 
EOF
}

#LIST=$PWD/uniprot_sprot_safe_biomolecules.lst
#export OUTPUT_DIR=$PWD/OUTPUT
#export BLAST_OUTPUT_DIR=/mobi/group/divisome/2018_11_07_RESULTS/PSICQUIC_SPROT_SAFE_VS_R6R_head/BLAST_OUTPUT

export PYTHON_SCRIPT_LOG=$SLIB_PATH/lib/R6_blast_parser.py
export PYTHON_SCRIPT_CORE=$SLIB_PATH/lib/core.py

export R6_INDEX=$PWD/R6_index.txt

if [ -z "$SLIB_PATH" ]
    then
	echo "set \$SLIB_PATH  plz" >&2;
	exit 1;
fi
source $SLIB_PATH/lib/common.sh

SLICE="_"
TEST=""

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
   	-l|--list)
    LIST="$2"
    shift # past argument
    shift # past value
    ;;
	-q|--query)
    export R6_INDEX="$2"
    shift # past argument
    shift # past value
    ;;
	-i|--inputDir)
    export BLAST_OUTPUT_DIR="$2"
    shift # past argument
    shift # past value
    ;;
	-o|--outputDir)
    export OUTPUT_DIR="$2"
    shift # past argument
    shift # past value
    ;;
    -s|--slice)
    SLICE="$2"
    shift # past argument
    shift # past value
    ;;
    --test)
    TEST="YES";
	echo "TEST MODE, no computation run";
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

#LIST=$PWD/uniprot_sprot_safe_biomolecules.lst
#export OUTPUT_DIR=$PWD/OUTPUT
#export BLAST_OUTPUT_DIR=/mobi/group/divisome/2018_11_07_RESULTS/PSICQUIC_SPROT_SAFE_VS_R6R_head/BLAST_OUTPUT
#export PYTHON_SCRIPT=$SLIB_PATH/lib//R6_blast_parser.py
#export R6_INDEX=$PWD/R6_index.txt

if [ -z "${LIST}" ] || [ -z "${OUTPUT_DIR}" ] || [ -z "${R6_INDEX}" ] || [ -z "${BLAST_OUTPUT_DIR}" ]
then
    help; exit 1;
fi

if [ ! -d $BLAST_OUTPUT_DIR ] || [ ! -e $R6_INDEX ] || [ ! -e $LIST ]
then
	help; exit 1
fi
set -- "${POSITIONAL[@]}" # restore positional parameters
echo PROTEIN IDENTIER LIST = "${LIST}" 
echo BLAST OUTPUT DIR      = "${BLAST_OUTPUT_DIR}"
echo R6 INDEX FILE         = "${R6_INDEX}"

export LOGDIR=${OUTPUT_DIR}_logs
mkdir -p $OUTPUT_DIR $LOGDIR

totalSeq=`cat $LIST | wc -l`
echo "Working on $totalSeq Ids"

read MIN MAX < <(splitAndSplice $LIST $SLICE)

echo "Processing slice list in range [ $MIN, $MAX ]";

i=0
for file in `ls $PWD/list_slice_* `
do
	((i++))
	if [ $i -le $MAX ] && [ $i -ge $MIN ]
		then
		NB=`cat $file | wc -l ` 
		export LIST=$file
        cd $LOGDIR; 
		echo sbatch --array=1-$NB:100 $SLIB_PATH/lib/run_X.sh \
			--export $OUTPUT_DIR,$LIST,$BLAST_OUTPUT_DIR,$PYTHON_SCRIPT_LOG,$R6_INDEX,$PYTHON_SCRIPT_CORE
            #--chdir=$LOGDIR
			#--output=$LOGDIR/runLogInR6_%A_%a.out
		if [ -z "$TEST" ]
			then 
				sbatch --array=1-$NB:100 $SLIB_PATH/lib/run_X.sh \
				--export $OUTPUT_DIR,$LIST,$BLAST_OUTPUT_DIR,$PYTHON_SCRIPT_LOG,$R6_INDEX,$PYTHON_SCRIPT_CORE
                #--chdir=$LOGDIR
				#--output=$LOGDIR/runLogInR6_%A_%a.out
		fi
	fi
done

#!/bin/bash


#export OUTPUT_DIR=$PWD/BLAST_OUTPUT
#export DB=/mobi/group/databases/R6R_20181107/R6R.mfasta
#export FSDB=/mobi/group/databases/FS/vTrembl


function help() {
    cat <<EOF
    Run a serie of psiblast from PSICQUIC biomolecules into R6 extended proteome
    Usage:
    psicquic_vs_r6.sh -o BLAST_OUTPUT_DIR -l UNIPROT_ID_LIST -t BLAST_TARGET_DB -q QUERY_PROTEIN_FASTA_FSB
    Where,
        BLAST_OUTPUT_DIR is the location of the result folder tree
        UNIPROT_ID_LIST is a list of valid uniprot identifiers extracted from a PSICQUIC record
        BLAST_TARGET_DB is a blast formatted database (the R6 PROTEOME w/ its UNICLUST homologs)
        QUERY_PROTEIN_FASTA_FSB is the TrEMBL fasta FSbased database
EOF

}

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
   	-l|--input)
    LIST="$2"
    shift # past argument
    shift # past value
    ;;
	-o|--outputDir)
    export OUTPUT_DIR="$2"
    shift # past argument
    shift # past value
    ;;
    -t|--targetDataBase)
    export DB="$2"
    shift # past argument
    shift # past value
    ;;
    -q|--querySeq)
    export FSDB="$2"
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

if [ -z "${LIST}" ] || [ -z "${OUTPUT_DIR}" ] || [ -z "${DB}" ] || [ -z "${FSDB}" ]  
then
    help; exit 1;
fi


set -- "${POSITIONAL[@]}" # restore positional parameters
echo PROTEIN IDENTIER LIST = "${LIST}" 
echo OUTPUT DIR  = "${OUTPUT_DIR}"
echo TARGET DATABASE PATH     = "${DB}"
echo QUERY DATABASE PATH    = "${FSDB}"

LOGDIR=${OUTPUT_DIR}_logs
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
        	NB=`cat $file | wc -l`
            cd $LOGDIR
        	export LIST=$file
        	echo sbatch --array=1-$NB $SLIB_PATH/run_blast_array.sh \
            --export $OUTPUT_DIR,$LIST,$DB,$FSDB
            
			
            if [ -z "$TEST" ]
			then 
				echo "GO>>" sbatch --array=1-$NB $SLIB_PATH/run_blast_array.sh \
                    --export $OUTPUT_DIR,$LIST,$DB,$FSDB 
            fi
	fi
done

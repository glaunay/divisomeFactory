#!/bin/bash

function usage() {
	echo "Run blast of each target proteome sequence against uniclust30":
	echo "targetProteomeEnricher.sh -w WORKDIR -i TARGET_PROTEOME_FASTA_FOLDER -d UNICLUST_DATABASE"
}

function createWorkSpace(){
	local mainFolder=$1
	mkdir -p $mainFolder/slogs $mainFolder/swork
}

if [ -z "$SLIB_PATH" ]
    then
	echo "set \$SLIB_PATH  plz" >&2;
	exit 1;
fi

while [[ $# -ge 1 ]]
do
key="$1"
case $key in
    -w|--workDir)
    ROOTDIR=$(readlink -f $2)
    shift # past argument
    ;;
    -i|--inputDir)
    INPUT_DIR="$2"
    shift # past argument
    ;;
	-d|--dataBase)
    export UNICLUST_DB="$2"
    shift # past argument
    ;;
esac
shift # past argument or value
done

[[ -z "$ROOTDIR" ]] && {
	echo "Missing -w|--workDir";
	usage;
	exit 1;
}
[[ -z "$INPUT_DIR" ]] && {
	echo "Missing -i|--inputDir";
	usage;
	exit 1;
}
[[ -z "$UNICLUST_DB" ]] && {
	echo "Missing -d|--dataBase";
	usage;
	exit 1;
}

echo createWorkSpace in $ROOTDIR
createWorkSpace $ROOTDIR

export OUTPUT_DIR=$ROOTDIR/swork
export LIST=$ROOTDIR/list.temp
export PYTHON_SCRIPT=$SLIB_PATH/lib/MsaFromBlast.py

if [ ! -e $PYTHON_SCRIPT ]
then
echo "Fatal Error: no Python script at $PYTHON_SCRIPT"
exit 1
fi

#export UNICLUST_DB=/mobi/group/databases/blast/uniclust30_2016_09_seed.fasta 

ls $INPUT_DIR/*.seq > $ROOTDIR/list.temp
totalSeq=$(wc -l $ROOTDIR/list.temp | awk '{print $1}')

cd $ROOTDIR/slogs
cmd="sbatch --array=1-$totalSeq $SLIB_PATH/lib/run_blast_array_enricher.sh --export $OUTPUT_DIR,$LIST,$UNICLUST_DB,$PYTHON_SCRIPT"
echo $cmd
$cmd


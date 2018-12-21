#!/bin/bash

function usage() {
    cat <<EOF
Run batch of fastacmd to create enriched proteome multifasta and then build the Blast database
formatEnrichedTargetProteome.sh -i INPUTDIR -e ENRICHMENT_DIR -t OUTPUT_BLAST_DB_TAG -o OUTPUT_BLAST_DB_LOCATION -d REF_BLAST_DB
Where,
    -i|--inputDir)  Folder storing the target proteome sequences
    -e|--enrichDir) Folder storing the target proteome enrichment step results (must contain the swork folder)
    -o|--outputDir) Folder to store the enriched proteome blast database
    -t|--blastTag)  Name for the enriched proteome blast database
    -d|--dataBase)  Database containing the enrichment hits, from which homologs fasta sequencs will be extracted
EOF
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
    -i|--inputDir)
    INPUT_DIR=$(readlink -f $2)
    shift # past argument
    ;;
    -e|--enrichDir)
    ENRICHED_DIR=$(readlink -f $2)
    shift # past argument
    ;;
    -o|--outputDir)
    TARGET_DIR=$(readlink -f $2)
    shift # past argument
    ;;
    -d|--dataBase)
    BLAST_DB_IN="$2"
    shift # past argument
    ;;
    -t|--blastTag)
    BLAST_DB_TAG="$2"
    shift # past argument
    ;;
esac
shift # past argument or value
done


[[ -z "$INPUT_DIR" ]] && {
	echo "Missing -i|--inputDir";
	usage;
	exit 1;
}

[[ -z "$ENRICHED_DIR" ]] && {
	echo "Missing -e|--enrichDir";
	usage;
	exit 1;
}

[[ -z "$TARGET_DIR" ]] && {
	echo "Missing  -o|--outputDir)";
	usage;
	exit 1;
}

[[ -z "$BLAST_DB_IN" ]] && {
	echo "Missing -d|--dataBase)";
	usage;
	exit 1;
}

[[ -z "$BLAST_DB_TAG" ]] && {
	echo "Missing -t|--blastTag)";
	usage;
	exit 1;
}

#TARGET_DIR="/mobi/group/databases/R6R_20181107"
#BLAST_DB="/mobi/group/databases/blast/uniclust30_2018_08_seed.fasta"

# dump all the ids of the  target proteome sequences and homologues into a file
cat $ENRICHED_DIR/swork/*/proteins.mfasta $INPUT_DIR/*.seq | grep ">" | cut -d"|" -f2 | sort -u  > non_redundant_ids.txt
# remove from that list the ids of R6 proteome
grep ">" $INPUT_DIR/*.seq | cut -d"|" -f2 | sort -u > targetProteome_ids.txt
# -v reverts the selection (non-matching line), -f tells grep to reat PATTERN in a file, and -w tells grep to consider PATTERN as full word
# "the matching substring must either be at the beginning of the line, or preceded by a non-word constituent character.  Similarly, it
#              must be either at the end of the line or followed by a non-word constituent character."
# without this option, PATTERN
# to test that it is correct, `grep -w -f R6_ids.txt  non_redundant_ids.txt | wc -l` should return exactly the number of lines that are stored in R6_ids.txt
grep -w -v -f targetProteome_ids.txt non_redundant_ids.txt > non_redundant_ids_without_targetProteome.txt

# get all the sequences of non_redundant_ids_without_R6.txt
module load ncbi-blast/2.2.26
fastacmd -l 60 -i non_redundant_ids_without_targetProteome.txt -p T -d $BLAST_DB_IN -o non_redundant_seq_without_targetProteome.mfasta
# NB : the -l 60 is here to have same line length as in ../R6_proteome/ sequences.
# I don't know wheter is has an influence or not for formatdb, but I rather have consistent formats

# Add the sequences of R6 proteome
cat non_redundant_seq_without_targetProteome.mfasta $INPUT_DIR/*.seq  > $BLAST_DB_TAG.mfasta

# format the database
formatdb  -o T -s T -t $BLAST_DB_TAG -i $BLAST_DB_TAG.mfasta
# copy it
cp ${BLAST_DB_TAG}* $TARGET_DIR

echo "Blast database Name :$BLAST_DB_TAG, Size:$(grep "^>" $BLAST_DB_TAG.mfasta | wc -l) Location: $TARGET_DIR"
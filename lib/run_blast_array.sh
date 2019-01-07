#!/bin/bash

#SBATCH --job-name=TargetVsPsq
#SBATCH --partition=medium-mobi
#SBATCH --qos=medium-mobi
#SBATCH --ntasks=1
#SBATCH -N 1
#SBATCH --output=run_blast_%A_%a.out

echo input parameters
echo LIST $LIST
echo DB $DB
echo OUTPUT_DIR $OUTPUT_DIR
echo running task id $SLURM_ARRAY_TASK_ID 
echo FSBD $FSDB
echo TP_INDEX $TP_INDEX

module load ncbi-blast/2.2.26 
module load uniprotDB_FS

#echo "##PYTHON"
#which python
#python --version
#echo "####DEPENDENCIES####"
#ls $FSDB
#ls /software/mobi/uniprotDB_FS/2.0.0/scripts/uniprotFastaFS_2.py
#echo "#######"

cd $WORKDIR

cp $LIST ./list.temp
name=$(sed -n "$SLURM_ARRAY_TASK_ID"p list.temp)

#echo "########GO###"
#python /software/mobi/uniprotDB_FS/2.0.0/scripts/uniprotFastaFS_2.py $FSDB --get $name
#echo "########FAST###"


final_folder=$OUTPUT_DIR/${name:0:2}/$name/

echo destination folder is $final_folder 

if [ !  -s $final_folder/blast.out.gz ]
then
    mkdir -p $final_folder

    fastaFile=$name.fasta
    python /software/mobi/uniprotDB_FS/2.0.0/scripts/uniprotFastaFS.py \
        $FSDB --get $name \
        > $fastaFile

    if [ !  -s $fastaFile ]
    then
        echo "ERROR when retrieving fasta file from FSDB with id $name"
        rm $fastaFile
        exit
    fi
#rm $logFile

    blastpgp -j 3  -i $fastaFile  -d $DB -m 7 -b 2500 2> blast.err 1> blast.out

    if [ -s blast.err ]
	    then
	    echo "WARNING when running blast, take a look at $final_folder/blast.err"
    fi

    if [ -s blast.out ]
    then
        python /software/mobi/divisomeFactory/1.0.0/lib/R6_blast_parser.py \
        $TP_INDEX blast.out $name > $final_folder/$name.json
        gzip blast.out
        cp blast.out.gz $final_folder
    fi

    cp blast.err $fastaFile $final_folder

    echo job done

    else 
    echo nothing to do for id $name 
fi


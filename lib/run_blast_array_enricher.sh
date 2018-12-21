#!/bin/bash


#SBATCH --job-name=targetEnricher
#SBATCH --partition=long-mobi
#SBATCH --qos=long-mobi
#SBATCH --ntasks=1
#SBATCH -N 1

module load pyproteins
module load clustalw
module load ncbi-blast/2.2.26 
module load pathos

echo "input parameters"
echo LIST $LIST
echo OUTPUT_DIR $OUTPUT_DIR 
echo UNICLUST_DB $UNICLUST_DB
echo PYTHON_SCRIPT $PYTHON_SCRIPT
cd $WORKDIR

cp $LIST ./list.temp

curFile=$(sed -n "$SLURM_ARRAY_TASK_ID"p list.temp)
curName=$(basename "$curFile" .seq)

cp $curFile ./input.fasta

echo "running blast for sequence $curName"
blastpgp -j 1  -i input.fasta  -d $UNICLUST_DB -m 7 -b 2500 2> blast.err 1> blast.out
cp $PYTHON_SCRIPT ./MsaFromBlast.py
python MsaFromBlast.py -s input.fasta -b blast.out -db $UNICLUST_DB -stat no 1>msaStats.out 2>msaStats.err

echo job done
echo ls
ls *
mkdir -p $OUTPUT_DIR/$curName
cp $curFile blast.err blast.out proteins.mfasta $OUTPUT_DIR/$curName

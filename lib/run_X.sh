#!/bin/bash

#SBATCH --job-name=log_process
#SBATCH --partition=medium-mobi
#SBATCH --qos=medium-mobi
#SBATCH --ntasks=1
#SBATCH -N 1
#SBATCH --output=runPostProcess_%A_%a.out

module load numpy/current


echo input parameters
echo output log file $LOGDIR/runX_%A_%a.out 
echo LIST $LIST
echo BLAST_OUTPUT_DIR $BLAST_OUTPUT_DIR
echo OUTPUT_DIR $OUTPUT_DIR
echo PYTHON_SCRIPT $PYTHON_SCRIPT
echo R6_INDEX $R6_INDEX
echo running task id $SLURM_ARRAY_TASK_ID 
echo task step is $SLURM_ARRAY_TASK_STEP

cd $WORKDIR

cp $LIST ./list.temp


first=$SLURM_ARRAY_TASK_ID
last=`expr $first + $SLURM_ARRAY_TASK_STEP `
last=`expr $last - 1 `


for index in `seq $first $last `
do

name=$(sed -n "$index"p list.temp)

input_folder=$BLAST_OUTPUT_DIR/${name:0:2}/$name/
final_folder=$OUTPUT_DIR/${name:0:2}/$name/

echo destination folder is $final_folder 

if [ ! -s $final_folder/logFileInR6 ]
then

mkdir -p $final_folder

	if [ -e $input_folder/blast.out.gz ]
	then 
	cp $input_folder/blast.out.gz .
	gunzip blast.out.gz
	cp $PYTHON_SCRIPT_LOG ./parser.py
	cp $R6_INDEX ./indexR6.temp

	python ./parser.py indexR6.temp blast.out >logFileInR6 
    
    cp logFileInR6 $final_folder
    
    if [ ! -z logFileInR6 ]
    then
        echo "logFileInR6 non empty producing json"
        cp $PYTHON_SCRIPT_CORE ./core.py
	    cp $R6_INDEX ./R6_index.temp

	    python core.py blast.out $R6_INDEX  ./temp.json 
	    mv temp.json $final_folder/$name.json
    fi

	
	echo job done
	rm -f blast.out
	
	else 
	echo WARNING: blast.out.gz not found in $input_folder
	fi
else 
echo nothing to do for id $name 
fi

done
echo iterations over

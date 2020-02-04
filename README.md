# divisomeFactory
## Content
Bundle of BASH and Python (2.7.X) files to run on a slurm-driven HPC
## Objectives
Detecting Homology between target proteome and PSICQUIC records

## STEPS

### Collecting Target Proteome

Fetch batch of fasta sequences using the [UNIPROT proteome API](https://www.uniprot.org/proteomes/).
Following guide will use [the Pneumococcus R6 strain](https://www.uniprot.org/proteomes/UP000000586) as exemple.

### Enrich Target Proteome sequence set

The iterative nature of the blast based homology calls for a space of intermediate sequences between two sets of sequences to compare. In practice we need to detect homologs of the target proteome and merge them in a single blast database.
This will make the blast search more sensitive.

#### Target proteome homologs agnostic search 

We aim at expanding the set of target proteome with homologs sequence found in [uniclust](http://gwdu111.gwdg.de/~compbiol/uniclust/2018_08/). Version used here is **uniclust30_2018_08**.

```bash
targetProteomeEnricher.sh -w /mobi/group/divisome/CLEAN_RUN/ENRICHMENT -i /mobi/group/divisome/R6_proteome -d /mobi/group/databases/blast/uniclust30_2018_08_seed.fasta -f MULTI_FASTA_SOURCE
```

Where,

* **-w|--workDir)** is the location of the working directory
* **-i|--inputDir)** is the directory containing target proteome in individual fasta sequence files
* **-d|--dataBase)** is the path to the reference blast database (eg:uniclust)

#### Compiling expanded target proteome database

Run batch of fastacmd to create enriched proteome multifasta and then build the Blast database

```bash
formatEnrichedTargetProteome.sh -i INPUTDIR -e ENRICHMENT_DIR -t OUTPUT_BLAST_DB_TAG -o OUTPUT_BLAST_DB_LOCATION -d REF_BLAST_DB
```

Where,

* **-i|--inputDir)**  is the folder storing the target proteome sequences
* **-e|--enrichDir)** is the folder storing previous step results(must contain the swork folder)
* **-d|--dataBase)**  is the database used in previous step, fasta sequences will be extracted from it
* **-o|--outputDir)** is the folder to store the enriched proteome blast database
* **-t|--blastTag)**  is the tag name for the enriched proteome blast database

### Building the molecular interaction dataset

Use the [Psicquic web API](https://psicquic.github.io/MITAB27Format.html) and [providers endpoints](http://www.ebi.ac.uk/Tools/webservices/psicquic/registry/registry?action=STATUS) to collect protein interaction records. Attention should be paid to the experimental techniques used to detect interaction.

Concatenated interaction record under mitab format need to be purged of entries featuring invalid uniprot identifier (obsolete or fragment entry) and for similar interaction in similar publication but from different providers (redundancy).
Currently peformed in the jupyter notebook named [interaction dataset building and uniprot FS API](https://github.com/glaunay/omegaLoMo).


### Looking for homologs of molecular interactors in the enriched target proteome

Runs a serie of psiblast for the valid biomolecules extracted from the above molecular interaction dataset against the enriched target proteome

```bash
psicquicVsEnrichedTargetProteome.sh -o BLAST_OUTPUT_DIR -l UNIPROT_ID_LIST -t BLAST_TARGET_DB -q QUERY_PROTEIN_FASTA_FSB -i TARGET_PROTEOME_FOLDER
```

Where,

* **-l|--input)** is a list of valid uniprot identifiers extracted from a PSICQUIC record
* **-o|--outputDir)** is the location of the result folder tree, will be created
* **-t|--targetDataBase)** is a blast formatted database of the enriched target proteome
* **-i|--targetFolder)** is the folder containing the original proteome sequences
* **-q|--querySeq)** is the TrEMBL fasta FSbased database
* **-s|--slice)** is a slice expression

Input list od identifier will be split into sublist of 10000 entries, use the `-s` flag to process specific sublists. A slice expression respects the following syntax:

* *X,* All sublists starting from the one numbered *X* included
* *,X* All sublists from first one until the one numbered *X* included
* *X,Y* All sublists numbered between *X* and *Y*, both included


### Generate JSON document storing homology relationships

Iterate through a folder tree storing BLAST RESULTS to accumlate homology search results.
Generate a unique json file with list of Psicquic interactors along w/ their homologs in target proteome

```bash
    generateHomologyTree.sh -i DATA_DIR -o OUTPUT_JSON_FILE
```
    
Where,

* **-i|--input)** is the location of the result folder tree, by default all uniprot identifer will be processed
* **-o|--output)** is the location of the file to dump the results, default="default.json"

## OUTPUTS

 1. *Molecular interaction File*. All entries compliant to the aformentioned check, but not all having homologs in target proteome. Further culling will be done in **targetTopology** notebook. It respects the mitab format.

 2. *homologyTree.json*. Two level dictionary of uniprot identier keys:

* primary keys are part of the molecular interactor set
* secondary keys are part of the target proteome set
* leaves are homology relationship data tuples of 9 elements
  * *[0]* target proteome protein(**TPP**) sequence length,
  * *[1]* **TPP** hsp start position
  * *[2]* **TPP** hsp stop position
  * *[3]* molecular interactor (**MP**) sequence length
  * *[4]* **MP** hsp start position
  * *[5]* **MP** hsp stop position
  * *[6]* HSP positive match number
  * *[7]* HSP identical match number
  * *[8]* HSP eValue

As an example look at the following data sample

```json
{
"P97760": {
  "P66709": [["311", "5", "235", "275", "5", "272", "95", "45", "4.79675e-27"]]
  },
"P98084": {
  "Q59947": [["1963", "262", "811", "750", "24", "572", "176", "95", "2.1715e-07"]],
  "Q8DQN5": [["1876", "191", "395", "750", "52", "281", "75", "47", "1.90067e-06"]]
  }
}
```

In cyan 1<sup>st</sup> level, a uniprot identifier of molecular interactor, 2<sup>nd</sup> level the one of a target proteome element.
In red, the 1<->2 homology relationship data.

## Installation & Dependancies

### Prepare Uniclust
TODO

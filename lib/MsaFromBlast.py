
import xml.etree.ElementTree as ET
import pyproteins.sequence.msa as msa
import subprocess
import sys
import json

stat_flag='no'

i=1
while i < len(sys.argv):
    arg=sys.argv[i]
    if arg == '-s':
        i=i+1
        protein_seq=sys.argv[i]   
    if arg == '-b':
        i=i+1
        blastFile=sys.argv[i]
    if arg == '-db':
        i=i+1
        db=sys.argv[i]
    if arg == '-stat':
        i=i+1
       	stat_flag=sys.argv[i]
    i=i+1


def createMsaFromBlast(fastaFile, blastFile,db,stat_flag='no'):
    root = ET.parse(blastFile)
    hits = [ elem.text for elem in root.findall('BlastOutput_iterations/Iteration/Iteration_hits/Hit/Hit_id') ]
    mfastaRaw = ''
    with open (fastaFile, 'r') as myfile:
        mfastaRaw=myfile.read()

    for name in list(set(hits)):
        output = subprocess.check_output(['fastacmd', '-d',db, '-s', str(name)])
        mfastaRaw += output

    with open('proteins.mfasta', 'w') as f:
        f.write(mfastaRaw)


    if stat_flag == 'yes':	
    	subprocess.call(['clustalw2', '-INFILE=proteins.mfasta'])
    	msaObj = msa.Msa(fileName='proteins.aln')
    	print "MSA length " + str(len(msaObj))
    	print msaObj.masterCoverage()
    
    	f=open("msaStat.json", "w")
    	f.write( json.dumps(msaObj.masterCoverage()) )
    	f.close()

if __name__ == '__main__':
   createMsaFromBlast(protein_seq, blastFile,db, stat_flag)


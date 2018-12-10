

import xml.etree.ElementTree as ET
import sys

def blastParser(listOfId, blastFile):
    #fileName="/tmp/blast.out" ## Job Specific
    #idList=["S7PMY1","A0A0V1HC87","A0A0V0S2P6","A0A1A9TZ10"] ## Should come from R6_uniprot.lst
    idList = []
    with open(listOfId, 'r') as f:
        for line in f:
            idList.append(line.split("|")[1])

    fileName = blastFile


    ## Extract from xml tree, the subtrees containing Hit_accession node text value present in idList
    ## Get last iteration
    tree=ET.parse(fileName)
    root = tree.getroot()
    parent_map = {c:p for p in root.iter() for c in p}

    blast_all_iter_node = root.find('./BlastOutput_iterations')
    lastIter_subnode=root.findall('./BlastOutput_iterations/Iteration/Iteration_iter-num')[-1]
    lastIter_number=lastIter_subnode.text
    for iter_node in root.findall('./BlastOutput_iterations/Iteration'):
        if(iter_node.find('Iteration_iter-num').text != lastIter_number):
            #print "removing iteration " + str(iter_node)
            #print "from " + str(blast_all_iter_node)
            blast_all_iter_node.remove(iter_node)
            
    lastIter = parent_map[lastIter_subnode]
    Iteration_hits_node = lastIter.find("./Iteration_hits")
    if not Iteration_hits_node:
        return
    
    for hit in Iteration_hits_node.findall("./Hit"):
        id = hit.find("Hit_accession")
        if id.text not in idList:
            #print "removing " + str(id) + ' from ' + str(Iteration_hits_node)
            Iteration_hits_node.remove(hit)
        else :
            stack = []
            coverList = []     

            ## Get hit score information and display stdout
            # loop over Hsp get Hsp_hit-from, Hsp_hit-to
            # permier arrive premier dedans
            # condition pour rentrer, etre non-chevauchant avec ceux deja presents.
            allowed = True
            

            #Iteration_hits_node.findall("./Hit/Hit_hsps/Hsp"):
            for hsp in hit.findall("./Hit_hsps/Hsp"):
                Hfrom = hsp[6].text  
                Hto = hsp[7].text
                seq = ""

                for seq in coverList:
                    #print seq, Hfrom, Hto
              
                    if (int(seq[0]) <= int(Hfrom) <= int(seq[1])) or (int(seq[0]) <= int(Hto) <= int(seq[1])):
                        allowed = False
                    if (int(Hfrom) <= int(seq[0]) and  int(Hto) >= int(seq[1])):
                        allowed = False

                if allowed:
                    stack.append([Hfrom, Hto, hit.find("Hit_hsps/Hsp/Hsp_positive").text, 
                                  hit.find("Hit_hsps/Hsp/Hsp_identity").text, 
                                  hit.find("Hit_hsps/Hsp/Hsp_evalue").text])
                    
                    coverList.append((Hfrom, Hto))
                
            print id.text + ":" + '|'.join([ ','.join(s) for s in stack ]) + '\n'
            # S_i (stack_i[1] - stack_i[0] + 1]) / Hit_len 
                 
            
    #ET.tostring(root)
    #tree.write('/tmp/pruned_blast.xml')

if __name__ == '__main__':
   blastParser(sys.argv[1], sys.argv[2])






import xml.etree.ElementTree as ET
import sys, json

def blastParser(listOfId, blastFile):
    idList = []
    with open(listOfId, 'r') as f:
        for line in f:
            idList.append(line.split("_")[1])

    fileName = blastFile

    #print idList

    ## Extract from xml tree, the subtrees containing Hit_accession node text value present in idList
    ## Get last iteration
    tree=ET.parse(fileName)
    root = tree.getroot()
    parent_map = {c:p for p in root.iter() for c in p}

    qLength = root.find('BlastOutput_query-len').text
    blast_all_iter_node = root.find('./BlastOutput_iterations')
    lastIter_subnode=blast_all_iter_node[-1]


    data = {}
    for hit in lastIter_subnode.findall("./Iteration_hits/Hit"):
        hitID = hit.find("Hit_accession").text
        if hitID not in idList:
            continue
        hLength = hit.find("Hit_len").text
        stack = []
        coverList = []     

        ## Get hit score information and display stdout
        # loop over Hsp get Hsp_hit-from, Hsp_hit-to
        # permier arrive premier dedans
        # condition pour rentrer, etre non-chevauchant avec ceux deja presents.
        allowed = True

        #Iteration_hits_node.findall("./Hit/Hit_hsps/Hsp"):
        for hsp in hit.findall("./Hit_hsps/Hsp"):
            (eValue, qFrom, qTo, hFrom, hTo) = [ n.text for n in hsp[3:8] ]
            (hspIdentical, hpsPositive) =  [ n.text for n in hsp[10:12] ]
            for seq in coverList:
                if ( 
                    ( int(hFrom) >= int(seq[0]) and int(hFrom) <= int(seq[1]) ) or 
                    ( int(hTo)   >= int(seq[0]) and int(hTo)   <= int(seq[1]) ) 
                ):              
                    allowed = False
                    break

            if allowed:
                stack.append(
                [
                   hLength, hFrom, hTo,
                   qLength, qFrom, qTo,
                   hpsPositive, hspIdentical,
                   eValue,
                ])
                
                coverList.append((hFrom, hTo))
        data[hitID] = stack

    return data

if __name__ == '__main__':

    data = blastParser(sys.argv[1], sys.argv[2])
    if data:
        print ( json.dumps( { sys.argv[3] : data }) )
    else :
        print ('No R6 related hits found', file=sys.stderr)




'''
<Hsp>
              <Hsp_num>1</Hsp_num>
              <Hsp_bit-score>87.5355</Hsp_bit-score>
              <Hsp_score>216</Hsp_score>
              <Hsp_evalue>3.02566e-17</Hsp_evalue>
              <Hsp_query-from>3</Hsp_query-from>
              <Hsp_query-to>98</Hsp_query-to>
              <Hsp_hit-from>1</Hsp_hit-from>
              <Hsp_hit-to>105</Hsp_hit-to>
              <Hsp_query-frame>1</Hsp_query-frame>
              <Hsp_hit-frame>1</Hsp_hit-frame>
              <Hsp_identity>49</Hsp_identity>
              <Hsp_positive>66</Hsp_positive>
              <Hsp_gaps>9</Hsp_gaps>
              <Hsp_align-len>105</Hsp_align-len>
              <Hsp_qseq>ADKVKLSAKEILEKEFKTGVRGYKQEDVDKFLDMIIKDYETFHQEIEELQQENLQLKKQLEEASKKQPVQ---------SNTTNFDILKRLSNLEKHVFGSKLYD</Hsp_qseq>
              <Hsp_hseq>MASIIFSAKDIFEQEFGREVRGYNKVEVDEFLDDVIKDYETYAALVKSLRQEIADLKEELTRKPKPSPVQAEPLEAAITSSMTNFDILKRLNRLEKEVFGKQILD</Hsp_hseq>
              <Hsp_midline>   +  SAK+I E+EF   VRGY + +VD+FLD +IKDYET+   ++ L+QE   LK++L    K  PVQ         S+ TNFDILKRL+ LEK VFG ++ D</Hsp_midline>
            </Hsp>
'''

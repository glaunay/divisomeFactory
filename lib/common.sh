# Generate the interval of list_slice to process
# list_slice* files must have been already generated
# ARGV_2 specifies the range of list_slice to process, number corresponds to the alphanumeric rank of the file
# X => Only number X
# X, => From 1 to X
# ,X => From X to the last one
# X,Y => From X to Y, both included

generateMinMax() {
    MIN=""
    MAX=""
    if [ "$1" !=  "_" ]
    then
	    MIN=`echo $1 | perl -pe 's/^([0-9]+){0,1},{0,1}([0-9]+){0,1}$/$1/;'`
	    MAX=`echo $1 | perl -pe 's/^([0-9]+){0,1},{0,1}([0-9]+){0,1}$/$2/;'`
	    SINGLE=`echo $1 | perl -ne 'if ($_ =~ /^[0-9]+$/){print}'`
	    if [ ! -z "$SINGLE" ];then
		    MAX=$MIN
	    fi
    fi

    if [ -z "$MIN" ];then
	    MIN=1;
    fi
    if [ -z "$MAX" ];then
	    MAX=$2
    fi

    echo "$MIN" "$MAX"
}


function splitAndSplice () {
    local LIST=$1
    local SLICE=$2
    split -l 10000 $LIST list_slice_
    _MAX=`ls list_slice_* | wc -l`

    read MIN MAX < <(generateMinMax $SLICE $_MAX)
    echo "$MIN" "$MAX"
}
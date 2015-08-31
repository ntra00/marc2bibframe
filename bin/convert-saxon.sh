#!/bin/bash


MYDIR=`dirname $0`
MYPROG=`basename $0`

source "$MYDIR/marc2bibframe.conf"

function usage {
    echo "Usage: $0 [-s serialization] [-u baseuri] [-j path-to-saxon-jar] marcxml-input-path output-path" 1>&2
    exit 1
}
function die {
    echo $*1>&2
    exit 1
}
function valid_serialization {
    case $1 in
        rdfxml) return 0 ;;
        rdfxml-raw) return 0 ;;
        ntriples) return 0 ;;
        json) return 0 ;;
        exhibitJSON) return 0 ;;
    esac
    return 1
}


while getopts "s:u:j:" arg; do
    case $arg in
        s) SERIALIZATION=$OPTARG ;;
        u) BASEURI=$OPTARG ;;
        j) SAXON_JAR=$OPTARG ;;
        *) usage ;;
    esac
done

shift $((OPTIND-1))

if [ $# -ne 2 ]; then
    usage
fi

# validate options
[[ -f $SAXON_JAR ]] || die "Cannot find saxon: $SAXON_JAR"

valid_serialization $SERIALIZATION || die "Invalid serialization: $SERIALIZATION"

BN_ARG='usebnodes=false'

# Note - saxon Xquery changes to xbin sub-directory, so we make all paths absolute
# readlink also validates the paths

#MARCPATH=`readlink -e $1`
MARCPATH=$1
[[ -n "$MARCPATH" ]] || die "marcxml-input-path '$1' must exist"

#OUTPUT=`readlink -f $2`
OUTPUT=$2
[[ -n "$OUTPUT" ]] || die "output-path '$2' all directory components must exist"


# Okay - run the conversion

java -cp $SAXON_JAR net.sf.saxon.Query $MYDIR/../xbin/saxon.xqy marcxmluri="$MARCPATH" baseuri="$BASEURI" serialization="$SERIALIZATION" $BN_ARG 1>$OUTPUT


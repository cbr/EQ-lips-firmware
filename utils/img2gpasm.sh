#!/bin/bash
if [ $# -lt 4 ]
then
    echo "Usage: $0 <input_filename> <output_filename> <image_width> <image_height>" 1>&2
    exit -1
fi

IN_FILE=$1
OUT_FILE=$2
WIDTH=$3
HEIGHT=$4

GROUP_SIZE=4
BYTE_SIZE=8

# This function reverse the bits in a byte.
# The algo comes from:
#   http://graphics.stanford.edu/~seander/bithacks.html#BitReverseObvious
#   Reverse the bits in a byte with 3 operations (64-bit multiply and modulus division):
function reverseBitsInByte
{
    VALUE=$1
    #printf "0x%02X" "$(((VALUE * 0x0202020202 & 0x010884422010) % 1023))"
    RES=0
    for bitNum in `seq 0 7`
    do
	RES="$(( RES | (((VALUE >> bitNum) & 1) << (7-bitNum)) ))"
    done
    printf "0x%02X" "$RES"
}


#convert -rotate 90 -negate $IN_FILE $OUT_FILE.mono
convert -rotate 90 $IN_FILE $OUT_FILE.mono
TEMP=`hexdump  -e '8/1 "0x%02X "' -e '"\n"' -v $OUT_FILE.mono`
TEMP_ARRAY=( `echo $TEMP | tr '\n' ' '` )
rm -f $OUT_FILE
for pos_y in `seq 0 $((HEIGHT / BYTE_SIZE - 1))`
do
    for pos_x in `seq 0 $((WIDTH / GROUP_SIZE - 1))`
    do
        echo -n "    dt " >> $OUT_FILE
        for j in `seq 0 $((GROUP_SIZE - 1))`
        do
            if [ ! $j -eq 0 ]
            then
                echo -n ", " >> $OUT_FILE
            fi

            VALUE=${TEMP_ARRAY[$(( ((HEIGHT / BYTE_SIZE - 1) - pos_y) + j * (HEIGHT / BYTE_SIZE) + pos_x * GROUP_SIZE * (HEIGHT / BYTE_SIZE) ))]}
            reverseBitsInByte $VALUE >> $OUT_FILE
        done
        echo >> $OUT_FILE
    done
    echo >> $OUT_FILE
done

rm -f $OUT_FILE.mono

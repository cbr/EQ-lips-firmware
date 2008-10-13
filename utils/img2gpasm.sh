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


convert -rotate 90 -negate $IN_FILE $OUT_FILE.mono
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
            echo -n "${TEMP_ARRAY[$((j + pos_x * GROUP_SIZE + pos_y * HEIGHT / BYTE_SIZE ))]}" >> $OUT_FILE
        done
        echo >> $OUT_FILE
    done
    echo
done

rm -f $OUT_FILE.mono

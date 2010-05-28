#!/usr/bin/env python

import numpy as np
import math
import sys

NB_VALUE=32

# Draw gain of filter given its Pot value (P2) R1 and RL

# index = np.arange(0, 256, 1)
index = np.linspace(0,255, 256)
a = index / 255.0

P2 = 10000.0
RL = 470.0
R1 = 3300.0
R2 = R1

y = 20*np.log10(( RL + a*(R1 + (1-a)*P2))/( RL + (1-a)*(R2+a*P2) ))

minValue = y[0]
maxValue = y[255]

#mappingValues=np.linspace(minValue, maxValue, NB_VALUE)
mappingValues=[0]*NB_VALUE
zeroIndex = (NB_VALUE-1)/2
mappingValues[:zeroIndex]=np.linspace(minValue, 0, NB_VALUE/2)
mappingValues[zeroIndex:]=np.linspace(0, maxValue, NB_VALUE/2+1)
mappingIndex=[0]*NB_VALUE
mappingCloserValue=[0]*NB_VALUE
def getCloserIndexAndValue(value):
    closerValue = 0xFFFF
    closerIndex = 0
    for i in range(0, 256):
        if math.fabs(y[i]-value) < math.fabs(closerValue-value):
            closerValue = y[i]
            closerIndex = i

    return closerIndex, closerValue

num_val_in_line=0

if len(sys.argv) != 3:
    sys.stderr.write("Not enough parameters\n")
    sys.exit(-1)

mapping_file = open(sys.argv[1], "w")

for i in range(0, NB_VALUE):
    if (num_val_in_line==8):
        mapping_file.write("\n")
        num_val_in_line=0

    if (num_val_in_line == 0):
        mapping_file.write("    dt ")
    else:
        mapping_file.write(", ")

    mappingIndex[i], mappingCloserValue[i] = getCloserIndexAndValue(mappingValues[i])
    mapping_file.write("0x%02X" % mappingIndex[i])
    num_val_in_line=num_val_in_line+1

mapping_file.write("\n")
mapping_file.close()

value_file = open(sys.argv[2], "w")
value_file.write("    dt ")
for i in range(NB_VALUE/2 - 1, NB_VALUE):
    val = 10 * mappingCloserValue[i]
    value_file.write("0x%02X" % val)
    if i < (NB_VALUE - 1):
        value_file.write(", ")
value_file.write("\n")
value_file.close()

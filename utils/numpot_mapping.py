#!/bin/env python

import matplotlib.pyplot as pp
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
mappingValues=np.linspace(minValue, maxValue, NB_VALUE)
mappingIndex=[0]*NB_VALUE
def getCloserIndex(value):
    closerValue = 0xFFFF
    closerIndex = 0
    for i in range(0, 256):
        if math.fabs(y[i]-value) < math.fabs(closerValue-value):
            closerValue = y[i]
            closerIndex = i

    return closerIndex

num_val_in_line=0
for i in range(0, NB_VALUE):
    if (num_val_in_line==8):
        sys.stdout.write("\n")
        num_val_in_line=0

    if (num_val_in_line == 0):
        sys.stdout.write("    dt ")
    else:
        sys.stdout.write(", ")

    mappingIndex[i] = getCloserIndex(mappingValues[i])
    sys.stdout.write("0x%02X" % mappingIndex[i])
    num_val_in_line=num_val_in_line+1

sys.stdout.write("\n")



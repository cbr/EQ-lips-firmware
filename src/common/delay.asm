 UDATA_OVR
delay      RES 1 ; variable used for context saving

; relocatable code
PROG CODE

; wait for w cycles
delay_wait
    return
    global delay_wait
    movwf delay
delay_loop
    decfsz delay, 1
    goto delay_loop
    return

END

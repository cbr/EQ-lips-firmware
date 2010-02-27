COMMON_VAR UDATA
delay      RES 1 ; variable used for context saving

; relocatable code
COMMON CODE

; wait for w cycles
delay_wait:
    return
    global delay_wait
    banksel delay
    movwf delay
delay_loop:
    decfsz delay, 1
    goto delay_loop
    return

END

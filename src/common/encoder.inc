#define ENCODER_STABLE_STATE_NB     3

encoder_it macro

#if (ENC_A_PORT != ENC_B_PORT)
#error config_error
#endif

    ; *************** ENCODER
#ifdef RABIF
    btfss INTCON, RABIF
#else
    btfss INTCON, RBIF
#endif
    goto encoder_other_it

    ; test if rising edge
    ; wait until edge value is stable
#if 1
encoder_it_wait_stable:
    banksel 0
    ; init counter
    movlw ENCODER_STABLE_STATE_NB
    movwf interrupt_var_2
    ; read reference value
    movf ENC_A_PORT, W
    movwf interrupt_var_1
    movlw (1 << ENC_A_BIT | 1 << ENC_B_BIT)
    andwf interrupt_var_1, F
encoder_it_continue:
    ; read value to compare to reference value
    movlw (1 << ENC_A_BIT | 1 << ENC_B_BIT)
    andwf ENC_A_PORT, W
    ; compare to reference value
    subwf interrupt_var_1, W
    ; if bit Z of status is not set, the value is different from the reference, so we restart
    btfss STATUS, Z
    goto encoder_it_wait_stable

    decfsz interrupt_var_2, F
    goto encoder_it_continue

#else
    movlw 0xFF
    call delay_wait
#endif

    btfss ENC_A_PORT, ENC_A_BIT
    goto encoder_ack_it_enc

    ; test enc_b
    btfsc ENC_B_PORT, ENC_B_BIT
    goto encoder_rotate_ccw
encoder_rotate_cw
    incf encoder_value, F
    ;incf encoder_value, F
    ;incf encoder_value, F
    ;incf encoder_value, F
    ;incf encoder_value, F
    goto encoder_ack_it_enc
encoder_rotate_ccw
    ;decf encoder_value, F
    ;decf encoder_value, F
    ;decf encoder_value, F
    ;decf encoder_value, F
    decf encoder_value, F


encoder_ack_it_enc
    ; ack it
    movf ENC_A_PORT, F
#ifdef RABIF
    bcf INTCON, RABIF
#else
    bcf INTCON, RBIF
#endif
encoder_other_it
    endm


#ifndef ENCODER_M
    ; Functions
    extern encoder_init
#endif


encoder_set_value macro current_value, value_min, value_max
    ;; Disable it
    ;; todo
    ;; enable it
    movlw current_value
    movwf encoder_value
    endm

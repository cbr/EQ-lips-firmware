#define ENCODER_STABLE_STATE_NB     3

    extern encoder_min_value
    extern encoder_max_value

filter_io macro port_register, port_mask, counter
    local encoder_it_wait_stable
    local encoder_it_continue
    ; test if rising edge
    ; wait until edge value is stable
encoder_it_wait_stable:
    banksel 0
    ; init counter
    movlw counter
    movwf interrupt_var_2
    ; read reference value
    movf port_register, W
    movwf interrupt_var_1
    movlw port_mask
    andwf interrupt_var_1, F
encoder_it_continue:
    ; read value to compare to reference value
    movlw port_mask
    andwf port_register, W
    ; compare to reference value
    subwf interrupt_var_1, W
    ; if bit Z of status is not set, the value is different from the reference, so we restart
    btfss STATUS, Z
    goto encoder_it_wait_stable

    decfsz interrupt_var_2, F
    goto encoder_it_continue
    endm

encoder_it macro

#if (ENC_A_PORT != ENC_B_PORT)
#error config_error
#endif

#if (ENC_SW_PORT != ENC_B_PORT)
#error config_error
#endif

    ; *************** ENCODER
#ifdef RABIF
    btfss INTCON, RABIF
#else
    btfss INTCON, RBIF
#endif
    goto encoder_other_it
    filter_io ENC_A_PORT, (1 << ENC_A_BIT | 1 << ENC_B_BIT | 1 << ENC_SW_BIT), ENCODER_STABLE_STATE_NB

    ;; Check encoder switch
    btfss ENC_SW_PORT, ENC_SW_BIT
    incf encoder_sw, F

    ;; Check if encoder rotation need to be reevaluated
    btfsc ENC_A_PORT, ENC_A_BIT
    goto encoder_ack_it_enc

    ; test enc_b
    btfss ENC_B_PORT, ENC_B_BIT
    goto encoder_rotate_ccw
encoder_rotate_cw:
    ;; Test if not already max value
    movf encoder_value, W
    banksel encoder_max_value
    subwf encoder_max_value, W
    btfsc STATUS, Z
    goto encoder_ack_it_enc
    ;; Not max value
    incf encoder_value, F
    goto encoder_ack_it_enc
encoder_rotate_ccw:
    ;; Test if not already min value
    movf encoder_value, W
    banksel encoder_min_value
    subwf encoder_min_value, W
    btfsc STATUS, Z
    goto encoder_ack_it_enc
    ;; Not min value
    decf encoder_value, F


encoder_ack_it_enc:
    banksel 0
    ; ack it
    movf ENC_A_PORT, F
#ifdef RABIF
    bcf INTCON, RABIF
#else
    bcf INTCON, RBIF
#endif
encoder_other_it:
    endm


#ifndef ENCODER_M
    ; Functions
    extern encoder_init
#endif


encoder_set_value macro current_value, value_min, value_max
    interrupt_disable
    movlw current_value
    movwf encoder_value
    movlw value_min
    banksel encoder_min_value
    movwf encoder_min_value
    movlw value_max
    banksel encoder_max_value
    movwf encoder_max_value
    interrupt_enable
    banksel 0
    endm

;;; Reinitialize encoder switch counter
encoder_ack_sw macro
    clrf encoder_sw
    endm

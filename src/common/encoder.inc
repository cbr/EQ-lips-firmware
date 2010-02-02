#define ENCODER_STABLE_STATE_NB     0x40

    extern encoder_min_value
    extern encoder_max_value

filter_io macro port_register, port_mask, counter, result_reg
    local encoder_it_wait_stable
    local encoder_it_continue
    ; test if rising edge
    ; wait until edge value is stable
encoder_it_wait_stable:
    banksel 0
    ; init counter
    movlw counter
    movwf interrupt_var_1
    ; read reference value
    banksel port_register
    movf port_register, W
    banksel result_reg
    movwf result_reg
    movlw port_mask
    andwf result_reg, F
encoder_it_continue:
    ; read value and mask
    movlw port_mask
    banksel port_register
    andwf port_register, W
    ; compare to reference value
    banksel result_reg
    subwf result_reg, W
    ; if bit Z of status is not set, the value is different from the reference, so we restart
    btfss STATUS, Z
    goto encoder_it_wait_stable

    decfsz interrupt_var_1, F
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

    ;; Filter value of register (put into encoder_reg_current_value)
    filter_io ENC_A_PORT, (1 << ENC_A_BIT | 1 << ENC_B_BIT | 1 << ENC_SW_BIT), ENCODER_STABLE_STATE_NB, encoder_reg_current_value

    ;; Check if some changes have occured :
    ;; using XOR only bit which have change are equal to 1
    ;; -> put this result in interrupt_var_1
    banksel encoder_reg_current_value
    movf encoder_reg_current_value, W
    banksel encoder_reg_last_value
    xorwf encoder_reg_last_value, W
    movwf interrupt_var_1

    ;; Check encoder switch
encoder_switch_check:
    btfss interrupt_var_1, ENC_SW_BIT
    ;; The bit has not changed
    goto encoder_switch_check_end
    ;; The bit has changed, check if it has been pressed
    banksel encoder_reg_current_value
    btfss encoder_reg_current_value, ENC_SW_BIT
    incf encoder_sw, F
encoder_switch_check_end:

    ;; Check if encoder rotation need to be reevaluated
    btfss interrupt_var_1, ENC_A_BIT
    ;; The bit has not changed
    goto encoder_ack_it_enc
    ;; The bit has changed, check its new state
    btfsc encoder_reg_current_value, ENC_A_BIT
    goto encoder_ack_it_enc

    ; test enc_b
    btfss encoder_reg_current_value, ENC_B_BIT
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
    ;; Memorize register filtered value
    movf encoder_reg_current_value, W
    banksel encoder_reg_last_value
    movwf encoder_reg_last_value
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

#ifndef ENCODER_M
    ; Functions
    extern encoder_init
    extern encoder_set_value
    extern encoder_reg_last_value
    extern encoder_reg_current_value
#endif



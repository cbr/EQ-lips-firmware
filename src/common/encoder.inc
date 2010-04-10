#define ENCODER_MASK                (1 << ENC_A_BIT | 1 << ENC_B_BIT | 1 << ENC_SW_BIT)

    extern encoder_min_value
    extern encoder_max_value

encoder_it macro reg_current_value, reg_changed_bit

#if (ENC_A_PORT != ENC_B_PORT)
#error config_error
#endif

#if (ENC_SW_PORT != ENC_B_PORT)
#error config_error
#endif

    ;; Check encoder switch
encoder_switch_check:
    btfss reg_changed_bit, ENC_SW_BIT
    ;; The bit has not changed
    goto encoder_switch_check_end
    ;; The bit has changed, check if it has been pressed
    banksel reg_current_value
    btfss reg_current_value, ENC_SW_BIT
    incf encoder_sw, F
encoder_switch_check_end:

    ;; Check if encoder rotation need to be reevaluated
    btfss reg_changed_bit, ENC_A_BIT
    ;; The bit has not changed
    goto encoder_it_end
    ;; The bit has changed, check its new state
    btfsc reg_current_value, ENC_A_BIT
    goto encoder_it_end

    ; test enc_b
    btfss reg_current_value, ENC_B_BIT
    goto encoder_rotate_ccw
encoder_rotate_cw:
    ;; Test if not already max value
    movf encoder_value, W
    banksel encoder_max_value
    subwf encoder_max_value, W
    btfsc STATUS, Z
    goto encoder_it_end
    ;; Not max value
    incf encoder_value, F
    goto encoder_it_end
encoder_rotate_ccw:
    ;; Test if not already min value
    movf encoder_value, W
    banksel encoder_min_value
    subwf encoder_min_value, W
    btfsc STATUS, Z
    goto encoder_it_end
    ;; Not min value
    decf encoder_value, F

encoder_it_end:
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
#endif



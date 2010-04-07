#define IO_FILTER_NB_STABLE_STATE     0x40

io_interrupt macro
#ifdef RABIF
    btfss INTCON, RABIF
#else
    btfss INTCON, RBIF
#endif
    goto no_io_it

    ;; Filter value of register (put into reg_input_current_value)
    io_filter ENC_A_PORT, ENCODER_MASK, IO_FILTER_NB_STABLE_STATE, reg_input_current_value
    encoder_it reg_input_current_value, reg_input_last_value
ack_it_io:
    ;; Memorize register filtered value
    movf reg_input_current_value, W
    banksel reg_input_last_value
    movwf reg_input_last_value
    banksel 0
    ; ack it
    movf ENC_A_PORT, F
#ifdef RABIF
    bcf INTCON, RABIF
#else
    bcf INTCON, RBIF
#endif
no_io_it:

    endm


up_down_switch_it macro reg_current_value, reg_last_value
    ;; Check if some changes have occured:
    ;; using XOR only bit which have change are equal to 1
    ;; -> put this result in interrupt_var_1
    banksel reg_current_value
    movf reg_current_value, W
    banksel reg_last_value
    xorwf reg_last_value, W
    movwf interrupt_var_1

    ;; Check down switch
down_check:
    btfss interrupt_var_1, DOWN_SW_BIT
    ;; The bit has not changed
    goto down_check_end
    ;; The bit has changed, check if it has been pressed
    banksel reg_current_value
    btfss reg_current_value, DOWN_SW_BIT
    banksel down_cpt
    incf down_cpt, F
down_check_end:

    ;; Check up switch
up_check:
    btfss interrupt_var_1, UP_SW_BIT
    ;; The bit has not changed
    goto up_check_end
    ;; The bit has changed, check if it has been pressed
    banksel reg_current_value
    btfss reg_current_value, UP_SW_BIT
    banksel up_cpt
    incf up_cpt, F
up_check_end:

up_down_switch_it_end:
    endm



#ifndef IO_INTERRUPT_M
    extern reg_input_last_value
    extern reg_input_current_value
    extern up_cpt
    extern down_cpt
#endif

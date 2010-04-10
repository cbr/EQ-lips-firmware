#define IO_FILTER_NB_STABLE_STATE     0x40

io_interrupt macro
#ifdef RABIF
    btfss INTCON, RABIF
#else
    btfss INTCON, RBIF
#endif
    goto no_io_it

    ;; Filter value of register (put into reg_input_current_value)
    io_filter ENC_A_PORT, ENCODER_MASK | (1 << DOWN_SW_BIT) | (1 << UP_SW_BIT), IO_FILTER_NB_STABLE_STATE, reg_input_current_value

    ;; Check if some changes have occured:
    ;; using XOR only bit which have change are equal to 1
    ;; -> put this result in interrupt_var_1
    banksel reg_input_current_value
    movf reg_input_current_value, W
    banksel reg_input_last_value
    xorwf reg_input_last_value, W
    movwf interrupt_var_1

    encoder_it reg_input_current_value, interrupt_var_1
    io_check_button reg_input_current_value, interrupt_var_1, DOWN_SW_BIT, down_button_pressed, down_button_released
    io_check_button reg_input_current_value, interrupt_var_1, UP_SW_BIT, up_button_pressed, up_button_released
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


#ifndef IO_INTERRUPT_M
    extern reg_input_last_value
    extern reg_input_current_value
    extern down_button_pressed
    extern down_button_released
    extern up_button_pressed
    extern up_button_released
#endif

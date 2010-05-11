#define IO_LONG_PRESS_NB_CYCLE     (0x5DC/(TIMER_PERIOD_MS))

#define LCD_ALL_BIT_IN_SAME_REG
LCD_DATA_0_TRIS equ TRISA
LCD_DATA_0_PORT equ PORTA
LCD_DATA_0_BIT  equ 0

LCD_DATA_1_TRIS equ TRISA
LCD_DATA_1_PORT equ PORTA
LCD_DATA_1_BIT  equ 1

LCD_DATA_2_TRIS equ TRISA
LCD_DATA_2_PORT equ PORTA
LCD_DATA_2_BIT  equ 2

LCD_DATA_3_TRIS equ TRISA
LCD_DATA_3_PORT equ PORTA
LCD_DATA_3_BIT  equ 3

LCD_DATA_4_TRIS equ TRISA
LCD_DATA_4_PORT equ PORTA
LCD_DATA_4_BIT  equ 4

LCD_DATA_5_TRIS equ TRISA
LCD_DATA_5_PORT equ PORTA
LCD_DATA_5_BIT  equ 5

LCD_DATA_6_TRIS equ TRISA
LCD_DATA_6_PORT equ PORTA
LCD_DATA_6_BIT  equ 6

LCD_DATA_7_TRIS equ TRISA
LCD_DATA_7_PORT equ PORTA
LCD_DATA_7_BIT  equ 7

#ifdef LCD_ALL_BIT_IN_SAME_REG
LCD_DATA_TRIS   equ TRISA
LCD_DATA_PORT   equ PORTA
#endif

LCD_E1_TRIS     equ TRISC
LCD_E1_PORT     equ PORTC
LCD_E1_BIT      equ 0

LCD_E2_TRIS     equ TRISC
LCD_E2_PORT     equ PORTC
LCD_E2_BIT      equ 1

LCD_WR_TRIS     equ TRISC
LCD_WR_PORT     equ PORTC
LCD_WR_BIT      equ 4

LCD_A0_TRIS     equ TRISC
LCD_A0_PORT     equ PORTC
LCD_A0_BIT      equ 2

SPI_CS_TRIS    equ TRISB
SPI_CS_PORT    equ PORTB
SPI_CS_BIT     equ 4

SPI_SDO_TRIS    equ TRISC
SPI_SDO_PORT    equ PORTC
SPI_SDO_BIT     equ 5

SPI_SCL_TRIS    equ TRISC
SPI_SCL_PORT    equ PORTC
SPI_SCL_BIT     equ 3

ENC_A_TRIS equ TRISB
ENC_A_PORT equ PORTB
ENC_A_BIT  equ 0

ENC_B_TRIS equ TRISB
ENC_B_PORT equ PORTB
ENC_B_BIT  equ 1

ENC_SW_TRIS equ TRISB
ENC_SW_PORT equ PORTB
ENC_SW_BIT  equ 2

DOWN_SW_TRIS     equ TRISB
DOWN_SW_PORT     equ PORTB
DOWN_SW_BIT      equ 5

UP_SW_TRIS     equ TRISB
UP_SW_PORT     equ PORTB
UP_SW_BIT      equ 3

io_filter macro port_register, port_mask, counter, result_reg
    local io_filter_wait_stable
    local io_filter_continue
    ; test if rising edge
    ; wait until edge value is stable
io_filter_wait_stable:
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
io_filter_continue:
    ; read value and mask
    movlw port_mask
    banksel port_register
    andwf port_register, W
    ; compare to reference value
    banksel result_reg
    subwf result_reg, W
    ; if bit Z of status is not set, the value is different from the reference, so we restart
    btfss STATUS, Z
    goto io_filter_wait_stable

    decfsz interrupt_var_1, F
    goto io_filter_continue
    endm

io_check_button macro filtered_port, port_changes, bit, pressed_register, released_register
    local io_check_button_end
    local io_check_button_pressed
    local io_check_button_released
    btfss port_changes, bit
    goto io_check_button_end

    btfss filtered_port, bit
    goto io_check_button_released
io_check_button_pressed:
    banksel pressed_register
    incf pressed_register, F
    goto io_check_button_end
io_check_button_released:
    banksel released_register
    incf released_register, F
io_check_button_end:
    endm

#ifdef TREMOLO
;;; Periodic check of button. Mange short press and long press callback.
;;; current_reg: register containing button state bit
;;; bit: bit number in current_reg of button state. Warning: logic is negative!
;;; time_cpt: 16 bit register containing the number of cycle the button is pressed
;;; label_short_press: label called when short press event is detected
;;; label_long_press: label called when long press event is detected
io_cycle_check_button macro current_reg, bit, time_cpt, label_short_press, label_long_press
    local time_cpt_is_zero
    local time_cpt_is_not_zero
    local io_cycle_check_button_end
    local button_unpressed
    local button_unpressed_no_short_press_event
    math_test_16 time_cpt
    btfss STATUS, Z
    goto time_cpt_is_not_zero

time_cpt_is_zero:
#if 0
    movlw 5
    movwf param1
    movlw 3
    movwf param2
    call_other_page lcd_locate
    movlw 1
    movwf param1
    clrf param2
    call_other_page lcd_int
#endif
    ;; Button was not previously pressed
    ;; Check new state
    banksel current_reg
    btfsc current_reg, bit      ; logic is negative
    goto io_cycle_check_button_end
    ;; increment time_cpt
    ;; (since it is equal to 0, only inc low order byte)
    banksel time_cpt
    incf time_cpt, F
    ;; Finish
    goto io_cycle_check_button_end

time_cpt_is_not_zero:
    ;; Button was previously pressed
    ;; Check new state
    banksel current_reg
    btfsc current_reg, bit      ; logic is negative
    goto button_unpressed

    ;; Button is still pressed
    ;; increment time_cpt
    math_inc_16 time_cpt

    ;; Check if we have a long press
    math_load_const number_a, IO_LONG_PRESS_NB_CYCLE
    math_equal number_a, time_cpt
    btfss STATUS, Z
    goto io_cycle_check_button_end

    ;; Yes, we have a long press!
    call_other_page label_long_press
    ;; Set time_cpt to max value
    ;; (so, when button is unpressed, if time_cpt
    ;;  is not equal to max value, then it means
    ;;  "long press" event has not occured, so
    ;;  "short press" event has to be triggered)
    math_load_const time_cpt, MATH_MAX_16S_VALUE
    goto io_cycle_check_button_end

button_unpressed:
    ;; Button is not pressed anymore
    ;; Check if we have a short press
    math_load_const number_a, MATH_MAX_16S_VALUE
    math_equal number_a, time_cpt
    btfsc STATUS, Z
    goto button_unpressed_no_short_press_event

    ;; Yes, we have a short press event
    call_other_page label_short_press

    ;; In all case, reinit time_cpt
button_unpressed_no_short_press_event:
    banksel time_cpt
    clrf time_cpt
    clrf time_cpt+1
io_cycle_check_button_end:
    endm
#endif

#ifndef IO_M
    extern io_configure
    extern io_config_lcd_data_output
    extern io_config_lcd_data_input
#endif

;;; Manage dialog screen for eqalizer editing

#define EDIT_COMMON_M

#include <cpu.inc>
#include <global.inc>
#include <std.inc>
#include <menu.inc>
#include <process.inc>
#include <bank.inc>
#include <lcd.inc>
#include <io_interrupt.inc>
#include <math.inc>
#include <io.inc>
#include <timer.inc>

PROG_VAR_1 UDATA
button_up_time_cpt  RES 2
button_down_time_cpt  RES 2

; relocatable code
EQ_PROG_1 CODE
edit_common_st_bank:
    global edit_common_st_bank
    dt "BANK: ", 0
edit_common_st_load:
    global edit_common_st_load
    dt "LOAD", 0
edit_common_st_save:
    global edit_common_st_save
    dt "SAVE", 0

edit_common_save:
    global edit_common_save

    movf current_bank, W
    movwf param1
    decf param1, F
    call_other_page bank_save
    return

edit_common_load:
    global edit_common_load

    movf current_bank, W
    movwf param1
    decf param1, F
    call_other_page bank_load
    call_other_page process_change_conf
    menu_ask_refresh
    return

edit_common_refresh:
    global edit_common_refresh

    menu_ask_refresh
    return


edit_common_sleep:
    global edit_common_sleep
    sleep
    return

#define LONG_PRESS_NB_CYCLE     (0x5DC/(TIMER_PERIOD_MS))

;;; Periodic check of button. Mange short press and long press callback.
;;; current_reg: register containing button state bit
;;; bit: bit number in current_reg of button state. Warning: logic is negative!
;;; time_cpt: 16 bit register containing the number of cycle the button is pressed
;;; label_short_press: label called when short press event is detected
;;; label_long_press: label called when long press event is detected
cycle_check_button macro current_reg, bit, time_cpt, label_short_press, label_long_press
    local time_cpt_is_zero
    local time_cpt_is_not_zero
    local cycle_check_button_end
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
    goto cycle_check_button_end
    ;; increment time_cpt
    ;; (since it is equal to 0, only inc low order byte)
    banksel time_cpt
    incf time_cpt, F
    ;; Finish
    goto cycle_check_button_end

time_cpt_is_not_zero:
    ;; Button was previously pressed
    ;; Check new state
    banksel current_reg
    btfsc current_reg, bit      ; logic is negative
    goto button_unpressed

#if 0
    movlw 5
    movwf param1
    movlw 3
    movwf param2
    call_other_page lcd_locate
    movlw 2
    movwf param1
    clrf param2
    call_other_page lcd_int
#endif
    ;; Button is still pressed
    ;; increment time_cpt
    math_inc_16 time_cpt

    ;; Check if we have a long press
    math_load_const number_a, LONG_PRESS_NB_CYCLE
    math_equal number_a, time_cpt
    btfss STATUS, Z
    goto cycle_check_button_end

    ;; Yes, we have a long press!
    call_other_page label_long_press
    ;; Set time_cpt to max value
    ;; (so, when button is unpressed, if time_cpt
    ;;  is not equal to max value, then it means
    ;;  "long press" event has not occured, so
    ;;  "short press" event has to be triggered)
    math_load_const time_cpt, MATH_MAX_16S_VALUE
    goto cycle_check_button_end

button_unpressed:
#if 0
    movlw 5
    movwf param1
    movlw 3
    movwf param2
    call_other_page lcd_locate
    movlw 0
    movwf param1
    clrf param2
    call_other_page lcd_int
#endif
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
cycle_check_button_end:
    endm

edit_common_down_short:
    clrf param1
    movlw 3
    movwf param2
    ;; call_other_page lcd_locate
    movlw 1
    movwf param1
    clrf param2
    ;; call_other_page lcd_int
    return
edit_common_down_long:
    clrf param1
    movlw 3
    movwf param2
    ;; call_other_page lcd_locate
    movlw 2
    movwf param1
    clrf param2
    ;; call_other_page lcd_int
    return
edit_common_up_short:
    clrf param1
    movlw 3
    movwf param2
    ;; call_other_page lcd_locate
    movlw 3
    movwf param1
    clrf param2
    ;; call_other_page lcd_int
    return
edit_common_up_long:
    clrf param1
    movlw 3
    movwf param2
    ;; call_other_page lcd_locate
    movlw 4
    movwf param1
    clrf param2
    ;; call_other_page lcd_int
    return

;;; Function called periodically in order to do periodic actions:
;;; - evaluate button press (short/long)
;;; - update numpot values (very important for tremolo)
edit_common_cycle_period:
    global edit_common_cycle_period
    ;; Check up & down switches
    cycle_check_button reg_input_current_value, UP_SW_BIT, button_up_time_cpt, edit_common_up_short, edit_common_up_long
    cycle_check_button reg_input_current_value, DOWN_SW_BIT, button_down_time_cpt, edit_common_down_short, edit_common_down_long

#ifdef TREMOLO
    ;; Update numpot according to conf
    call_other_page process_update
#endif

#if 1
    movlw 5
    movwf param1
    movlw 3
    movwf param2
    call_other_page lcd_locate
    banksel reg_input_current_value
    movf reg_input_current_value, W
    andlw (1 << UP_SW_BIT) | (1 << DOWN_SW_BIT) | (1 << ENC_SW_BIT) | (1 << ENC_A_BIT) | (1 << ENC_B_BIT)
    movwf param1
    clrf param2
    call_other_page lcd_int
#endif
    return

END

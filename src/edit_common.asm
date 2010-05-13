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

#define BOTH_BUTTON_MASK    ((1 << DOWN_SW_BIT) | (1 << UP_SW_BIT))

#ifdef TREMOLO
#include <timer.inc>
#endif
PROG_VAR_1 UDATA
#ifdef TREMOLO
button_up_time_cpt  RES 2
button_down_time_cpt  RES 2
#endif
edit_common_var1 RES 1
edit_common_button_free_to_use RES 1
edit_common_button_last_value RES 1
;;; Counter of number of down switch released event
edit_common_down_btn_released RES 1
    global edit_common_down_btn_released
;;; Counter of number of up switch released event
edit_common_up_btn_released RES 1
    global edit_common_up_btn_released
;;; Counter of number of both button press event
edit_common_both_btn_pressed RES 1
    global edit_common_both_btn_pressed

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

;;;
;;; Initialize module
;;;
edit_common_init:
    global edit_common_init
    banksel edit_common_button_free_to_use
    movlw 0xFF
    movwf edit_common_button_free_to_use
    movwf edit_common_button_last_value
    return

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
    ;; Nothing to do -> put processor in sleep mode
    sleep
    nop
    ;; We have been wake up
    return


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

edit_common_check_buttons:
    global edit_common_check_buttons

    ;; Check if both button are pressed and not used
    ;; (bits are active when equal to 0, so the value is first negated)
    banksel reg_input_current_value
    comf reg_input_current_value, W
    banksel edit_common_button_free_to_use
    andwf edit_common_button_free_to_use, W
    andlw BOTH_BUTTON_MASK
    sublw BOTH_BUTTON_MASK
    btfss STATUS, Z
    goto chk_btn_both_button_not_pressed

    ;; Both button are pressed !
chk_btn_both_button_pressed:
    ;; Memorized that button state have been used
    banksel edit_common_button_free_to_use
    movlw BOTH_BUTTON_MASK
    movwf edit_common_button_free_to_use
    banksel edit_common_both_btn_pressed
    incf edit_common_both_btn_pressed, F
    call_other_page lcd_clear

    ;; Both button are not pressed
chk_btn_both_button_not_pressed:
    ;; Check pressed -> released transition
    ;; Put (state change AND reg_input_current_value AND edit_common_button_free_to_use) into edit_common_var1
    banksel edit_common_button_last_value
    movf edit_common_button_last_value, W
    banksel reg_input_current_value
    xorwf reg_input_current_value, W
    andwf reg_input_current_value, W
    banksel edit_common_button_free_to_use
    andwf edit_common_button_free_to_use, W
    banksel edit_common_var1
    movwf edit_common_var1
    ;; Check UP button
    btfss edit_common_var1, UP_SW_BIT
    goto chk_btn_up_button_not_released

    ;; Button UP released
chk_btn_up_button_released:
    banksel edit_common_up_btn_released
    incf edit_common_up_btn_released, F
    goto chk_btn_up_button_released_end

chk_btn_up_button_released_end:
chk_btn_up_button_not_released:
    ;; Check DOWN button
    btfss edit_common_var1, DOWN_SW_BIT
    goto chk_btn_down_button_not_released

    ;; Button DOWN released
chk_btn_down_button_released:
    banksel edit_common_down_btn_released
    incf edit_common_down_btn_released, F
    goto chk_btn_down_button_released_end

chk_btn_down_button_released_end:
chk_btn_down_button_not_released:

    ;; Memorize last button values
    banksel reg_input_current_value
    movf reg_input_current_value, W
    banksel edit_common_button_last_value
    movwf edit_common_button_last_value
    return



#ifdef TREMOLO
;;; Function called periodically in order to do periodic actions:
;;; - evaluate button press (short/long)
;;; - update numpot values (very important for tremolo)
edit_common_cycle_period:
    global edit_common_cycle_period
    clrf param1
    movlw 3
    movwf param2
    call_other_page lcd_locate
    clrf param2
    movf timer_cpt, W
    movwf param1
    call_other_page lcd_int

    ;; Check up & down switches
    io_cycle_check_button reg_input_current_value, UP_SW_BIT, button_up_time_cpt, edit_common_up_short, edit_common_up_long
    io_cycle_check_button reg_input_current_value, DOWN_SW_BIT, button_down_time_cpt, edit_common_down_short, edit_common_down_long

    ;; Update numpot according to conf
    call_other_page process_update

    return
#endif

END

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

#ifdef TREMOLO
#include <timer.inc>
#endif
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
    nop
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
#endif

END

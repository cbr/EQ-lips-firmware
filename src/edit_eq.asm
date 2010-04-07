;;; Manage dialog screen for eqalizer editing

#define EDIT_EQ_M

#include <cpu.inc>
#include <global.inc>
#include <std.inc>
#include <lcd.inc>
#include <menu.inc>
#include <menu_button.inc>
#include <menu_eq.inc>
#include <menu_edit.inc>
#include <encoder.inc>
#include <interrupt.inc>
#include <numpot.inc>
#include <math.inc>
#include <bank.inc>
#include <process.inc>
#include <edit_common.inc>
#include <edit_trem.inc>
;; #include <menu_label.inc>

PROG_VAR_1 UDATA
#if 0
gain16          RES 2
inc             RES 2
trem_nb_val     RES 1
#endif

; relocatable code
EQ_PROG_1 CODE
edit_eq_st_trem:
    dt "GOTO TREMOLO", 0

edit_eq_show:
    global edit_eq_show

    call_other_page lcd_clear

    menu_start edit_common_cycle_period
    ;; menu_label_int 0, current_bank
    menu_button_goto edit_eq_st_trem, 0, edit_trem_show
    menu_edit edit_common_st_bank, 1, 1, 1, 0x10, current_bank, edit_common_load, UNUSED_PARAM
    menu_edit_no_show edit_common_st_save, 1, 2, 1, 0x10, current_bank, edit_common_refresh, edit_common_save
    menu_eq (0x5*0 + 0x3D), bank_numpot_values, process_change_conf
    menu_eq (0x5*1 + 0x3D), bank_numpot_values+1, process_change_conf
    menu_eq (0x5*2 + 0x3D), bank_numpot_values+2, process_change_conf
    menu_eq (0x5*3 + 0x3D), bank_numpot_values+3, process_change_conf
    menu_eq (0x5*4 + 0x3D), bank_numpot_values+4, process_change_conf
    menu_eq (0x5*5 + 0x3D), bank_numpot_values+5, process_change_conf
    menu_eq (0x5*6 + 0x3D), bank_numpot_values+6, process_change_conf
    menu_eq (0x5*7 + 0x3D), bank_numpot_values+7, process_change_conf
    menu_eq (0x5*8 + 0x3D), bank_numpot_values+8, process_change_conf
    menu_eq (0x5*9 + 0x3D), bank_numpot_values+9, process_change_conf
    menu_eq (0x5*0xB + 0x3D), bank_numpot_values+0xA, process_change_conf
    menu_end

    return

#if 0
prepare_trem
    ;; init gain16
    banksel gain16
    movlw .16
    movwf gain16+1
    lshift_f gain16+1, 3
    clrf gain16

    ;; init inc
    ;; inc = amplitude / nb_val
    ;; inc = 16 (shifted) / nb_val
    ;; inc = 0x4000 / 50 = 0x147
    banksel inc
    movlw 0x47
    movwf inc
    movlw 0x01
    movwf inc+1

    ;; init nb val
    banksel trem_nb_val
    movlw 0x32
    movwf trem_nb_val
    return

trem_manage:
    ;; increment gain value
   ;; gain16 = gain16 + inc
    math_copy_16 gain16, number_a
    math_copy_16 inc, number_b
    math_banksel
    call_other_page math_add_1616s
    math_copy_16 number_b, gain16

    ;; Set gain value (keep only 5 high order bits)
    banksel gain16
    movf gain16+1, W
    movwf param2
    rshift_f param2, 3
    ;; gain is pot 9
    movlw 0xA
    movwf param1
    call_other_page numpot_set_one_value
    ;; incf tst_timer, F

    ;; send values
    call_other_page numpot_send_all

    ;; prepare next val
    banksel trem_nb_val
    decfsz trem_nb_val, F
    goto trem_manage_end
    ;; reinit nb_val
    movlw 0x32
    movwf trem_nb_val
    ;; inverse inc
    math_copy_16 inc, number_a
    math_banksel
    call_other_page math_neg_number_a_16s
    math_copy_16 number_a, inc
trem_manage_end:
    banksel 0
    return
#endif

END

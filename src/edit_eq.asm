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

#define EDIT_EQ_VALUE

PROG_VAR_1 UDATA

; relocatable code
EQ_PROG_2 CODE
edit_eq_st_trem:
    dt "GOTO TREMOLO", 0
button_sleep_st:
    dt "SLEEP", 0

tst_select_spec:
    menu_select_specific_entry 112
    return

edit_eq_show:
    global edit_eq_show

    call_other_page lcd_clear

#ifdef TREMOLO
    menu_start edit_common_cycle_period, UNUSED_PARAM
#else
    menu_start UNUSED_PARAM, edit_common_sleep

    ;; Before managing every element of menu, check buttons state
    call_other_page edit_common_check_buttons
    edit_common_basic_btn_mgt
#endif

    ;; menu_label_int 0, current_bank
#ifdef TREMOLO
    menu_button_goto edit_eq_st_trem, 0, edit_trem_show
#endif
    ;; menu_button edit_common_st_save, 0, tst_select_spec
    menu_edit 10, edit_common_st_bank, 1, 1, 1, BANK_NB, current_bank, edit_common_load, UNUSED_PARAM
    ;; menu_edit 10, edit_common_st_bank, 1, 1, 1, BANK_NB, current_bank, tst_select_spec, UNUSED_PARAM
    ;; menu_edit_no_show 11, edit_common_st_save, 1, 2, 1, BANK_NB, current_bank, edit_common_refresh, edit_common_save
    menu_eq 12, (0x5*0 + 0x3D), bank_numpot_values, process_change_conf
    menu_eq 13, (0x5*1 + 0x3D), bank_numpot_values+1, process_change_conf
    menu_eq 14, (0x5*2 + 0x3D), bank_numpot_values+2, process_change_conf
    menu_eq 15, (0x5*3 + 0x3D), bank_numpot_values+3, process_change_conf
    menu_eq 16, (0x5*4 + 0x3D), bank_numpot_values+4, process_change_conf
    menu_eq 17, (0x5*5 + 0x3D), bank_numpot_values+5, process_change_conf
    menu_eq 18, (0x5*6 + 0x3D), bank_numpot_values+6, process_change_conf
    menu_eq 19, (0x5*7 + 0x3D), bank_numpot_values+7, process_change_conf
    menu_eq 110, (0x5*8 + 0x3D), bank_numpot_values+8, process_change_conf
    menu_eq 111, (0x5*9 + 0x3D), bank_numpot_values+9, process_change_conf
    menu_eq 112,(0x5*0xB + 0x3D), bank_numpot_values+0xA, process_change_conf
    menu_button_hidden ID_BANK_UP, edit_common_bank_up
    menu_button_hidden ID_BANK_DOWN, edit_common_bank_down
    menu_end

    return


END

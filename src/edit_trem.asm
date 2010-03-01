;;; Manage dialog screen for eqalizer editing

#define EDIT_TREM_M

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
#include <edit_eq.inc>

PROG_VAR_1 UDATA

; relocatable code
EQ_PROG_2 CODE
edit_trem_st_eq:
    dt "GOTO EQUALIZER", 0

edit_trem_show:
    global edit_trem_show

    call_other_page lcd_clear
    menu_start process_update
    menu_button_goto edit_trem_st_eq, 0, edit_eq_show
    menu_edit edit_common_st_bank, 1, 1, 0x10, current_bank, edit_common_load, 0
    menu_edit_no_show edit_common_st_save, 2, 1, 0x10, current_bank, edit_common_refresh, edit_common_save
    menu_end
    return


END

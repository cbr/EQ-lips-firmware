;;; Manage dialog screen for eqalizer editing

#define EDIT_COMMON_M

#include <cpu.inc>
#include <global.inc>
#include <std.inc>
#include <menu.inc>
#include <process.inc>
#include <bank.inc>
#include <lcd.inc>
PROG_VAR_1 UDATA

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

edit_common_cycle_period:
    global edit_common_cycle_period
    ;; Check up & down switches

    ;; Update numpot according to conf
    call_other_page process_update
    return

END

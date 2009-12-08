;;; Manage dialog screen for eqalizer editing

#define EDIT_EQ_M

#include <cpu.inc>
#include <global.inc>
#include <std.inc>
#include <lcd.inc>

    UDATA
edit_eq_tmp      RES 1


; relocatable code
PROG CODE
edit_eq_show:
    global edit_eq_show
    ;; Erase screen
    call lcd_clear

    ;; Draw eq
END

#define MENU_M

#include <cpu.inc>
#include <lcd.inc>
#include <std.inc>
#include <global.inc>
#include <menu.inc>
#include <encoder.inc>

#define MENU_BUTTON_NB_DRAW_SELECT  0x8

    UDATA
menu_var1               RES 1
menu_state              RES 1
    global menu_state
menu_leave_state        RES 1
    global menu_leave_state

;;; relocatable code
COMMON CODE

END

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

;;; relocatable code
COMMON CODE

END

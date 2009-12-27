#define MENU_EDIT_M

#include <cpu.inc>
#include <lcd.inc>
#include <std.inc>
#include <global.inc>
#include <menu.inc>
#include <menu_edit.inc>
#include <encoder.inc>
#include <delay.inc>

#define MENU_EDIT_NB_DRAW_SELECT  0x8

    UDATA
menu_edit_var1               RES 1
menu_edit_var2               RES 1

;;; relocatable code
COMMON CODE

;;; param1: y position of edit
menu_edit_select_func:
    global menu_edit_select_func

#if 1
    ;; rectanle for the selected line only

    ;; draw the focus rectangle twice with XOR
    movlw MENU_EDIT_NB_DRAW_SELECT
    banksel menu_edit_var1
    movwf menu_edit_var1
menu_edit_select_func_draw:
    movf param1, W
    movwf param2
    lshift_f param2, LCD_CHAR_HEIGH_SHIFT

    clrf param1
    movlw LCD_WIDTH
    movwf param3
    movf param2, W
    movwf param4
    movlw LCD_CHAR_HEIGH
    movwf param4
    bsf param5, LCD_XOR
    call_other_page lcd_rectangle
    banksel menu_edit_var1
    decfsz menu_edit_var1, F
    goto menu_edit_select_func_draw
#endif

    lcd_send_cmd_1 LCD_DISPLAY_START_LINE, 0

    return
END

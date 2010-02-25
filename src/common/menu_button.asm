#define MENU_BUTTON_M

#include <cpu.inc>
#include <lcd.inc>
#include <std.inc>
#include <global.inc>
#include <menu.inc>
#include <menu_button.inc>
#include <encoder.inc>
#include <delay.inc>

#define MENU_BUTTON_NB_DRAW_SELECT  0x8

COMMON_VAR UDATA
menu_button_var1               RES 1
menu_button_var2               RES 1

;;; relocatable code
COMMON CODE

;;; param1: y position of button
menu_button_select_func:
    global menu_button_select_func

#if 1
    ;; rectanle for the selected line only

    ;; draw the focus rectangle twice with XOR
    movlw MENU_BUTTON_NB_DRAW_SELECT
    banksel menu_button_var1
    movwf menu_button_var1
menu_button_select_func_draw:
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
    banksel menu_button_var1
    decfsz menu_button_var1, F
    goto menu_button_select_func_draw
#endif
#if 0
    ;; rectangle for the entire screen

    ;; draw the focus rectangle twice with XOR
    movlw MENU_BUTTON_NB_DRAW_SELECT
    banksel menu_button_var1
    movwf menu_button_var1

menu_button_select_func_draw:
    clrf param1
    clrf param2
    movlw LCD_WIDTH/2
    movwf param3
    movlw LCD_HEIGH
    movwf param4
    bsf param5, LCD_XOR
    call_other_page lcd_rectangle

    movlw LCD_WIDTH/2
    movwf param1
    clrf param2
    movlw LCD_WIDTH/2
    movwf param3
    movlw LCD_HEIGH
    movwf param4
    bsf param5, LCD_XOR
    call_other_page lcd_rectangle
    banksel menu_button_var1
    decfsz menu_button_var1
    goto menu_button_select_func_draw
#endif

#if 0
    ;; scroll screen
    ;; too fast for now ! try again when a real delay will be available

    clrf menu_button_var2
    movlw 32
    movwf menu_button_var1
menu_button_select_func_draw:
    movlw LCD_DISPLAY_START_LINE
    movwf param1
    movf menu_button_var2, W
    iorwf param1, F
    bsf param2, LCD_COMMAND
    bsf param2, LCD_FIRST_CHIP
    call lcd_write

    ;; delay
    movlw 0xFF
    call delay_wait

    incf menu_button_var2, F
    decfsz menu_button_var1, F
    goto menu_button_select_func_draw

#endif
    lcd_send_cmd_1 LCD_DISPLAY_START_LINE, 0

    return
END

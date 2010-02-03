#define MENU_EDIT_M

#include <cpu.inc>
#include <lcd.inc>
#include <std.inc>
#include <global.inc>
#include <menu.inc>
#include <menu_edit.inc>
#include <encoder.inc>
#include <delay.inc>

    UDATA
menu_edit_var1               RES 1
;;; relocatable code
COMMON CODE

;;; Manage value change of edit
;;; param1: addrl of null terminated string
;;; param2: addrh of null terminated string
;;; param3: y position of edit
;;; param4: address of edit value
menu_edit_manage_select_value_change:
    global menu_edit_manage_select_value_change
    ;; save param3 and param4
    movf param3, W
    banksel menu_edit_var1
    movwf menu_edit_var1
    ;; FSR is not used by called functions, so it can be directly set
    movf param4, W
    movwf FSR

    ;; calculate size of string
    call std_strlen
    ;; Add MENU_STRING_POS_X to this size
    addlw MENU_STRING_POS_X
    ;; and store in param1
    movwf param1

    banksel menu_edit_var1
    ;; Check if y position is equal to MENU_EDIT_NO_PRINT_VAL
    movlw MENU_EDIT_NO_PRINT_VAL
    subwf menu_edit_var1, W
    btfsc STATUS, Z
    ;; equal -> do not print
    goto menu_edit_manage_select_value_change_after_print
    ;; not equal -> print value
    movf menu_edit_var1, W
    movwf param2
    call lcd_locate
    movf menu_select_value, W
    ;; FSR has been set at the beginning of function
    movwf INDF
    movwf param1
    call lcd_int
    ;; ***************
menu_edit_manage_select_value_change_after_print:
    menu_ask_refresh
    return

;;; draw selection/deselection rectangle of menu edit
;;; param1: size of edit string
;;; param2: y position of edit
menu_edit_draw_select:
    global menu_edit_draw_select
    ;; move param1 value to param3
    movf param1, W
    movwf param3
    lshift_f param3, LCD_CHAR_WIDTH_SHIFT

    ;; shift y pos in order to get pos in pixel
    lshift_f param2, LCD_CHAR_HEIGH_SHIFT

    ;; set param1 to the start of the menu string
    movlw MENU_STRING_POS_X
    movwf param1
    lshift_f param1, LCD_CHAR_WIDTH_SHIFT

    movlw LCD_CHAR_HEIGH
    movwf param4
    bsf param5, LCD_XOR
    call lcd_rectangle

    return

END

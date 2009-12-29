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
menu_edit_var2               RES 1
menu_edit_last_value         RES 1
;;; relocatable code
COMMON CODE

;;; param1: addrl of null terminated string
;;; param2: addrh of null terminated string
;;; param3: y position of edit
;;; param4: address of edit value
menu_edit_manage_selection:
    global menu_edit_manage_selection
    ;; save param3 and param4
    movf param3, W
    banksel menu_edit_var2
    movwf menu_edit_var2
    ;; FSR is not used by called functions, so it can be directly set
    movf param4, W
    movwf FSR

    ;; calculate size of string
    call std_strlen
    ;; store in menu_edit_var1
    banksel menu_edit_var1
    movwf menu_edit_var1

    ;; draw selection rectangle
    movwf param1
    banksel menu_edit_var2
    movf menu_edit_var2, W
    movwf param2
    call menu_edit_draw_select

menu_edit_manage_selection_loop:
    ;; Check events

menu_edit_manage_selection_check_sw:
    ;; Check if encoder switch is not 0
    movf encoder_sw, F
    btfsc STATUS, Z
    ;; equal to 0 -> next event
    goto menu_edit_manage_selection_check_rot
    ;; the encoder switch has been pressed
    ;; draw edit as unselect
    banksel menu_edit_var1
    movf menu_edit_var1, W
    movwf param1
    banksel menu_edit_var2
    movf menu_edit_var2, W
    movlw param2
    call menu_edit_draw_select
    ;; reset encoder_sw
    encoder_ack_sw
    ;; quit selection
    goto menu_edit_manage_selection_quit

menu_edit_manage_selection_check_rot:
    ;; check if encoder value has changed
    banksel menu_edit_last_value
    movf menu_edit_last_value, W
    subwf encoder_value, W
    btfsc STATUS, Z
    ;; values are equal -> nothing to do
    goto menu_edit_manage_selection_loop
    ;; values are not equal
    ;; -> manage changes
    ;; ***************
    ;; clear old value

    ;; print new value and memorize
    movlw MENU_STRING_POS_X
    movwf param1
    banksel menu_edit_var1
    movf menu_edit_var1, W
    addwf param1, F
    banksel menu_edit_var2
    movf menu_edit_var2, W
    movwf param2
    call lcd_locate
    movf encoder_value, W
    banksel menu_edit_last_value
    movwf menu_edit_last_value
    ;; FSR has been set at the beginning of function
    movwf INDF
    movwf param1
    call lcd_int
    ;; ***************
    goto menu_edit_manage_selection_loop

menu_edit_manage_selection_quit:
    return

;;; draw selection/deselection rectangle of menu edit
;;; param1: size of edit string
;;; param2: y position of edit
menu_edit_draw_select:

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

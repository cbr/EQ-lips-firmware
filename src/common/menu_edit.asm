;;;
;;; Copyright 2010 Cedric Bregardis.
;;;
;;; This file is part of EQ-lips firmware.
;;;
;;; EQ-lips firmware is free software: you can redistribute it and/or
;;; modify it under the terms of the GNU General Public License as
;;; published by the Free Software Foundation, version 3 of the
;;; License.
;;;
;;; EQ-lips firmware is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with EQ-lips firmware.  If not, see <http://www.gnu.org/licenses/>.
;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; MODULE DESCRIPTION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Manage the 'edit' menu entry.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#define MENU_EDIT_M

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; INCLUDES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
#include <cpu.inc>
#include <lcd.inc>
#include <std.inc>
#include <global.inc>
#include <menu.inc>
#include <menu_edit.inc>
#include <encoder.inc>
#include <delay.inc>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; VARIABLES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
COMMON_VAR UDATA
menu_edit_var1               RES 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; CODE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
COMMON CODE


;;;
;;; Manage value change of edit
;;; param1: addrl of null terminated string
;;; param2: addrh of null terminated string
;;; param3: x position of edit
;;; param4: y position of edit
;;; param5: address of edit value. IRP bit of STATUS register must be correctly
;;;         set before calling this function in order to read the value with the
;;;         help of FSR/INDF
;;; param6: configuration of value to print (format of param2 of lcd_int function)
;;;
menu_edit_manage_select_value_change:
    global menu_edit_manage_select_value_change
    ;; save param3
    movf param3, W
    banksel menu_edit_var1
    movwf menu_edit_var1
    ;; FSR is not used by called functions, so it can be directly set
    movf param5, W
    movwf FSR

    ;; calculate size of string
    call std_strlen
    ;; Store result
    movwf param1
    ;; Add pos x
    banksel menu_edit_var1
    movf menu_edit_var1, W
    addwf param1, F

    ;; Memorize value
    banksel menu_select_value
    movf menu_select_value, W
    ;; FSR has been set at the beginning of function
    movwf INDF

    ;; Check if y position is equal to MENU_EDIT_NO_PRINT_VAL
    movlw MENU_EDIT_NO_PRINT_VAL
    subwf param4, W
    btfsc STATUS, Z
    ;; equal -> do not print
    goto menu_edit_manage_select_value_change_after_print
    ;; not equal -> print value
    movf param4, W
    movwf param2
    call_other_page lcd_locate
    banksel menu_select_value
    movf menu_select_value, W
    movwf param1
    movf param6, W
    movwf param2
    call_other_page lcd_int
    ;; ***************
menu_edit_manage_select_value_change_after_print:

    return

;;;
;;; draw selection/deselection rectangle of menu edit
;;; param1: x position of edit
;;; param2: y position of edit
;;; param3: size of edit string
;;;
menu_edit_draw_select:
    global menu_edit_draw_select

    ;; shift y pos in order to get pos in pixel
    lshift_f param2, LCD_CHAR_HEIGH_SHIFT

    ;; shift x pos in order to get pos in pixel
    lshift_f param1, LCD_CHAR_WIDTH_SHIFT

    ;; shift w pos in order to get width in pixel
    lshift_f param3, LCD_CHAR_WIDTH_SHIFT

    movlw LCD_CHAR_HEIGH
    movwf param4

    bsf param5, LCD_XOR
    call_other_page lcd_rectangle

    return

END

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

#define MENU_EQ_M

#include <cpu.inc>
#include <lcd.inc>
#include <std.inc>
#include <global.inc>
#include <menu.inc>
#include <menu_eq.inc>
#include <encoder.inc>

#define MENU_EQ_BAND_WIDTH          0x04
#define MENU_EQ_BAND_FOCUS_WIDTH    0x05

#define MENU_EQ_VALUE_TO_LCD_SHT    0x00

COMMON_VAR UDATA
menu_eq_last_value         RES 1
    global menu_eq_last_value
menu_eq_var1               RES 1
menu_eq_var2               RES 1


;;; relocatable code
COMMON CODE

;;;
;;; Draw eq band rectangle value
;;; param1: band x position
;;; param2: band value.
;;;
menu_draw_eq_band:
    global menu_draw_eq_band

    ;; Offset of one pixel before the rectangle
    ;; (used by focus rectangle)
    incf param1, F

    movlw MENU_EQ_ZERO_VALUE
    subwf param2, W
    btfss STATUS, C
    goto menu_draw_eq_neg
menu_draw_eq_pos:
    ;; The substract result is the value to be drawn
    movwf param4
    ;; ... but lcd heigh is smaller than the eq resolution.
    ;; So the value is divided (=shifted) to get the heigh of rectangle
    rshift_f param4, MENU_EQ_VALUE_TO_LCD_SHT
    incf param4, F
    ;; Rectangle y start
    movf param4, W
    sublw (LCD_HEIGH / 2) + 1
    movwf param2
    goto menu_draw_eq_rect

menu_draw_eq_neg:
    ;; Get the opposite value to get the heigh of rectangle...
    movwf param4
    comf param4, F
    ;; ... but lcd heigh is smaller than the eq resolution.
    ;; So the value is divided (=shifted) to get the heigh of rectangle
    rshift_f param4, MENU_EQ_VALUE_TO_LCD_SHT
    incf param4, F

    ;; Rectangle y start
    movlw (LCD_HEIGH / 2) +1
    movwf param2

menu_draw_eq_rect:
    ;; Set eq width
    movlw MENU_EQ_BAND_WIDTH
    movwf param3

    bsf param5, LCD_SET_PIXEL

    call_other_page lcd_rectangle
    return

;;;
;;; Refresh band
;;; param1: band x position
;;; param2: band value
;;; Changed registers: menu_eq_var1, menu_eq_var2
;;;
menu_refresh_eq_band:
    global menu_refresh_eq_band
    ;; save params
    banksel menu_eq_var1
    movf param1, W
    movwf menu_eq_var1
    banksel menu_eq_var2
    movf param2, W
    movwf menu_eq_var2

    ;; erase
    incf param1, F
    clrf param2
    movlw MENU_EQ_BAND_WIDTH
    movwf param3
    movlw LCD_HEIGH
    movwf param4
    bcf param5, LCD_XOR
    bcf param5, LCD_SET_PIXEL
    call_other_page lcd_rectangle

    ;; draw the band
    banksel menu_eq_var1
    movf menu_eq_var1, W
    movwf param1
    banksel menu_eq_var2
    movf menu_eq_var2, W
    movwf param2
    call menu_draw_eq_band

    return

;;;
;;; Draw eq band focus
;;; param1: band x position
;;; Changed registers: menu_eq_var1
;;;
menu_draw_focus_eq_band:
    global menu_draw_focus_eq_band
    ;; save param
    movf param1, W
    banksel menu_eq_var1
    movwf menu_eq_var1
    ;; draw left vertical line
    clrf param2
    movlw 1
    movwf param3
    movlw LCD_HEIGH
    movwf param4
    bsf param5, LCD_XOR
    call_other_page lcd_rectangle
    ;; draw right vertical line
    banksel menu_eq_var1
    movf menu_eq_var1, W
    addlw MENU_EQ_BAND_FOCUS_WIDTH
    movwf param1
    clrf param2
    movlw 1
    movwf param3
    movlw LCD_HEIGH
    movwf param4
    bsf param5, LCD_XOR
    call_other_page lcd_rectangle
    return

;;;
;;; Draw the selection/deselection rectangle
;;; of eq band
;;; param1: band x position
;;;
menu_eq_draw_select:
    global menu_eq_draw_select
    incf param1, F
    clrf param2
    movlw MENU_EQ_BAND_WIDTH
    movwf param3
    movlw LCD_HEIGH
    movwf param4
    bsf param5, LCD_XOR
    call_other_page lcd_rectangle
    return


;;;
;;; Manage eq band selection: change value with encoder and return from selection
;;; when encoder sw is pressed
;;; param1: band x position
;;; param2: address of eq value. IRP bit of STATUS register must be correctly
;;;         set before calling this function in order to read the value with the
;;;         help of FSR/INDF
;;; Changed registers: menu_eq_var1
;;;
menu_eq_manage_select:
    global menu_eq_manage_select

    ;; Save params
    movf param1, W
    banksel menu_eq_var1
    movwf menu_eq_var1
    ;; FSR is not used by called functions, so it can be directly set
    movf param2, W
    movwf FSR

    ;; Draw selection
    call_other_page menu_eq_draw_select
    ;; mem current value
    ;; FSR has been set at the beginning of function
    movf INDF, W
    banksel menu_eq_last_value
    movwf menu_eq_last_value
    ;; configure encoder
    movwf param1
    clrf param2
    movlw MENU_EQ_MAX_INPUT
    movwf param3
    clrf param4
    call_other_page menu_selection_encoder_configure
    return

;;;
;;; Manage eq band selection: change value with encoder and return from selection
;;; when encoder sw is pressed
;;; param1: band x position
;;; Changed registers:
;;;
menu_eq_manage_unselect:
    global menu_eq_manage_unselect
    ;; draw eq as unselect
    call_other_page menu_eq_draw_select
    return

;;;
;;; Manage eq band selection: change value with encoder and return from selection
;;; when encoder sw is pressed
;;; param1: band x position
;;; param2: address of eq value. IRP bit of STATUS register must be correctly
;;;         set before calling this function in order to read the value with the
;;;         help of FSR/INDF
;;; Changed registers: menu_eq_var1
;;;
menu_eq_manage_select_value_change:
    global menu_eq_manage_select_value_change

    ;; Save params
    movf param1, W
    banksel menu_eq_var1
    movwf menu_eq_var1
    ;; FSR is not used by called functions, so it can be directly set
    movf param2, W
    ;; fixme: FSR bank
    movwf FSR

    ;; undraw band
    ;; (param1 is already set)
    banksel menu_eq_last_value
    movf menu_eq_last_value, W
    movwf param2
    call_other_page menu_draw_eq_band
    ;; draw new band and memorize
    banksel menu_eq_var1
    movf menu_eq_var1, W
    movwf param1
    banksel menu_select_value
    movf menu_select_value, W
    banksel menu_eq_last_value
    movwf menu_eq_last_value
    ;; FSR has been set at the beginning of function
    movwf INDF
    movwf param2
    call_other_page menu_draw_eq_band

    return

END

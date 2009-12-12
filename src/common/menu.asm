#define MENU_M



#include <cpu.inc>
#include <lcd.inc>
#include <std.inc>
#include <global.inc>

#define MENU_EQ_BAND_WIDTH          0x04
#define MENU_EQ_BAND_FOCUS_WIDTH    0x05
#define MENU_EQ_ZERO_VALUE          0x80
#define MENU_EQ_VALUE_TO_LCD_SHT    0x03
#define MENU_EQ_MAX_INPUT           0xFF

    UDATA
    global menu_last_value
menu_last_value         RES 1
menu_var1               RES 1



; relocatable code
COMMON CODE

;;; Draw eq band rectangle value
;;; param1: band x position
;;; param2: band value
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
    sublw (LCD_HEIGH / 2)
    movwf param2
    goto menu_draw_eq_rect

menu_draw_eq_neg:
    ;; Get the opposite value to get the heigh of rectangle...
    sublw MENU_EQ_MAX_INPUT
    movwf param4
    ;; ... but lcd heigh is smaller than the eq resolution.
    ;; So the value is divided (=shifted) to get the heigh of rectangle
    rshift_f param4, MENU_EQ_VALUE_TO_LCD_SHT
    incf param4, F

    ;; Rectangle y start
    movlw (LCD_HEIGH / 2)
    movwf param2

menu_draw_eq_rect:
    ;; Set eq width
    movlw MENU_EQ_BAND_WIDTH
    movwf param3

    bsf param5, LCD_SET_PIXEL

    call lcd_rectangle
    return

;;; Draw eq band focus
;;; param1: band x position
menu_draw_focus_eq_band:
    global menu_draw_focus_eq_band
    ;; save param
    movf param1, W
    movwf menu_var1
    ;; draw left vertical line
    clrf param2
    movlw 1
    movwf param3
    movlw LCD_HEIGH
    movwf param4
    bsf param5, LCD_XOR
    call lcd_rectangle
    ;; draw right vertical line
    movf menu_var1, W
    addlw MENU_EQ_BAND_FOCUS_WIDTH
    movwf param1
    clrf param2
    movlw 1
    movwf param3
    movlw LCD_HEIGH
    movwf param4
    bsf param5, LCD_XOR
    call lcd_rectangle
    return
END

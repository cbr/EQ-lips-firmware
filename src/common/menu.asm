#define MENU_M



#include <cpu.inc>
#include <lcd.inc>
#include <std.inc>
#include <global.inc>
#include <menu.inc>
#include <encoder.inc>

#define MENU_EQ_BAND_WIDTH          0x04
#define MENU_EQ_BAND_FOCUS_WIDTH    0x05
#define MENU_EQ_ZERO_VALUE          0x80
#define MENU_EQ_VALUE_TO_LCD_SHT    0x03

    UDATA
menu_eq_last_value         RES 1
    global menu_eq_last_value
menu_var1               RES 1
menu_var2               RES 1



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

;;; Refresh band
;;; param1: band x position
;;; param2: band value
;;; Changed registers: menu_var1, menu_var2
menu_refresh_eq_band:
    global menu_refresh_eq_band
    ;; save params
    banksel menu_var1
    movf param1, W
    movwf menu_var1
    banksel menu_var2
    movf param2, W
    movwf menu_var2

    ;; erase
    clrf param2
    movlw MENU_EQ_BAND_FOCUS_WIDTH
    movwf param3
    movlw LCD_HEIGH
    movwf param4
    bcf param5, LCD_XOR
    bcf param5, LCD_SET_PIXEL
    call lcd_rectangle

    ;; draw the band
    banksel menu_var1
    movf menu_var1, W
    movwf param1
    banksel menu_var2
    movf menu_var2, W
    movwf param2
    call menu_draw_eq_band

    return

;;; Draw eq band focus
;;; param1: band x position
;;; Changed registers: menu_var1
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

;;; Draw the selection/deselection rectangle
;;; of eq band
;;; param1: band x position
menu_draw_select:
    global menu_draw_select
    incf param1, F
    clrf param2
    movlw MENU_EQ_BAND_WIDTH
    movwf param3
    movlw LCD_HEIGH
    movwf param4
    bsf param5, LCD_XOR
    call lcd_rectangle
    return


;;;
;;; Manage eq band selection: change value with encoder and return from selection
;;; when encoder sw is pressed
;;; param1: band x position
;;; param2: address of eq value
;;; Changed registers: menu_var1
;;;
menu_eq_manage_selection_func:
    global menu_eq_manage_selection_func

    ;; Save params
    movf param1, W
    movwf menu_var1
    ;; FSR is not used by called functions, so it can be directly set
    movf param2, W
    movwf FSR

    ;; Draw selection
    call_other_page menu_draw_select
    ;; mem current value
    ;; FSR has been set at the beginning of function
    movf INDF, W
    movwf menu_eq_last_value
    ;; configure encoder
    movwf param1
    clrf param2
    movlw MENU_EQ_MAX_INPUT
    movwf param3
    call_other_page encoder_set_value

menu_eq_manage_selection_loop:
    ;; Check events

menu_eq_manage_selection_check_sw:
    ;; Check if encoder switch is not 0
    movf encoder_sw, F
    btfsc STATUS, Z
    ;; equal to 0 -> next event
    goto menu_eq_manage_selection_check_rot
    ;; the encoder switch has been pressed
    ;; draw eq as unselect
    movf menu_var1, W
    movwf param1
    call_other_page menu_draw_select
    ;; reset encoder_sw
    encoder_ack_sw
    ;; quit selection
    goto menu_eq_manage_selection_quit

menu_eq_manage_selection_check_rot:
    ;; check if encoder value has changed
    movf menu_eq_last_value, W
    subwf encoder_value, W
    btfsc STATUS, Z
    ;; values are equal -> nothing to do
    goto menu_eq_manage_selection_loop
    ;; values are not equal
    ;; -> manage changes
    ;; ***************
    ;; undraw band
    movf menu_var1, W
    movwf param1
    movf menu_eq_last_value, W
    movwf param2
    call_other_page menu_draw_eq_band
    ;; draw new band and memorize
    ;; FSR has been set at the beginning of function
    movf menu_var1, W
    movwf param1
    movf encoder_value, W
    movwf menu_eq_last_value
    movwf INDF
    movwf param2
    call_other_page menu_draw_eq_band
    ;; ***************
    goto menu_eq_manage_selection_loop

menu_eq_manage_selection_quit:

    return


END

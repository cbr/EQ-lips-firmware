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
;;; Manage NJU6450 based LCD. NJU6450 is almost SED1520.
;;; The interface between the controller and the MPU is 68 type
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#define LCD_M

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; INCLUDES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
#include <cpu.inc>
#include <global.inc>
#include <io.inc>
#include <delay.inc>
#include <std.inc>
#include <lcd.inc>


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; DEFINES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
#define DELAY_RESET 4
#define DELAY_CS 2

#define PIXEL_MASK     0x07

#define LCD_INT_DEC_POS_100    0x03
#define LCD_INT_DEC_POS_10     0x02
#define LCD_INT_DEC_POS_1      0x01

#define LCD_NB_BIG_CHAR_BY_LINE_SHT 3

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; VARIABLES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
COMMON_VAR UDATA
var1       RES 1
var2       RES 1
var3       RES 1
var4       RES 1
var5       RES 1
var6       RES 1
var7       RES 1
lcd_save_chip RES 1
lcd_save_x RES 1
lcd_save_y RES 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; MACROS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
set_lcd_data_bit macro num_bit, value
    local set_lcd_data_set
    local set_lcd_data_after

    btfsc value, num_bit
    goto set_lcd_data_set
    bcf LCD_DATA_#v(num_bit)_PORT, LCD_DATA_#v(num_bit)_BIT
    goto set_lcd_data_after
set_lcd_data_set:
    bsf LCD_DATA_#v(num_bit)_PORT, LCD_DATA_#v(num_bit)_BIT
set_lcd_data_after:
    endm

get_lcd_data_bit macro num_bit
    btfsc LCD_DATA_#v(num_bit)_PORT, LCD_DATA_#v(num_bit)_BIT
    bsf param1, num_bit
    endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; CODE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
COMMON_2 CODE

;;;
;;; Init LCD
;;; no parameters
;;;
lcd_init:
    global lcd_init    ; initial delay
    ;movlw 0xFF
    ;call delay_wait

    ;; reset lcd

    bcf LCD_E1_PORT, LCD_E1_BIT
    bcf LCD_E2_PORT, LCD_E2_BIT

    ;bsf LCD_WR_PORT, LCD_WR_BIT
    bcf LCD_WR_PORT, LCD_WR_BIT

    bcf LCD_A0_PORT, LCD_A0_BIT
#if 1
    ;; init lcd 1
    lcd_send_cmd_1 LCD_DISPLAY_ON_OFF, 0
    lcd_send_cmd_1 LCD_DISPLAY_START_LINE, 0
    lcd_send_cmd_1 LCD_STATIC_DRIVE_ON_OFF, 0
    lcd_send_cmd_1 LCD_COLUMN_ADDRESS, 0
    lcd_send_cmd_1 LCD_SET_PAGE_ADDRESS, 0

    lcd_send_cmd_1 LCD_SELECT_DUTY, 1
    lcd_send_cmd_1 LCD_SELECT_ADC, 0

    lcd_send_cmd_1 LCD_END, 0
#endif
    ;; init lcd 2
    lcd_send_cmd_2 LCD_DISPLAY_ON_OFF, 0

    lcd_send_cmd_2 LCD_DISPLAY_START_LINE, 0
    lcd_send_cmd_2 LCD_STATIC_DRIVE_ON_OFF, 0
    lcd_send_cmd_2 LCD_COLUMN_ADDRESS, 0
    lcd_send_cmd_2 LCD_SET_PAGE_ADDRESS, 0

    lcd_send_cmd_2 LCD_SELECT_DUTY, 1
    lcd_send_cmd_2 LCD_SELECT_ADC, 0

    lcd_send_cmd_2 LCD_END, 0


    call_other_page lcd_clear

    lcd_send_cmd_1 LCD_DISPLAY_ON_OFF, 1
    lcd_send_cmd_2 LCD_DISPLAY_ON_OFF, 1

    return

;;;
;;; Clear the entire LCD
;;; Changed registers : param1
;;;	Local: var1, var2
lcd_clear:
    global lcd_clear
    movlw 4 ; number of page
    banksel var1
    movwf var1

loop_pages:
    movlw 40 ; number of column
    movwf var2

    ;; set column 0
    movlw LCD_COLUMN_ADDRESS
    movwf param1

    bsf param2, LCD_COMMAND
    bsf param2, LCD_FIRST_CHIP
    call_other_page lcd_write
    bcf param2, LCD_FIRST_CHIP
    call_other_page lcd_write

    ;; set page var1
    movlw LCD_SET_PAGE_ADDRESS
    banksel var1
    decf var1, F
    iorwf var1, W
    movwf param1
    incf var1, F

    ;; second chip (bit unset on previous command)
    call_other_page lcd_write
    ;; first chip
    bsf param2, LCD_FIRST_CHIP
    call_other_page lcd_write

    bcf param2, LCD_COMMAND
loop_column:
    clrf param1
    bsf param2, LCD_FIRST_CHIP
    call_other_page lcd_write
    bcf param2, LCD_FIRST_CHIP
    call_other_page lcd_write

    banksel var2
    decfsz var2, F
    goto loop_column

    decfsz var1, F
    goto loop_pages

    return

;;;
;;; plot in lcd
;;; param1 : x
;;; param2 : y
;;; param3 : - Use xor or not (LCD_XOR bit).
;;;          - Set or unset pixels (LCD_SET_PIXEL bit). Only valid if xor is not activated.
;;;

lcd_plot:
    global lcd_plot
    ;; store param1
    movf param1, W
    banksel var1
    movwf var1
    ;; store param2
    movf param2, W
    movwf var2

    ;; *** set X
    ;; w = param1 - (LCD_WIDTH/2)
    movlw LCD_WIDTH/2
    subwf var1, W

    ;; if x is greater than LCD_WIDTH/2, goto lcd_plot_prepare_clmn_2
    btfsc STATUS, C
    goto lcd_plot_prepare_clmn_2

lcd_plot_prepare_clmn_1:
    movf var1, W
    bsf param2, LCD_FIRST_CHIP
    goto lcd_plot_set_clmn

lcd_plot_prepare_clmn_2:
    bcf param2, LCD_FIRST_CHIP

lcd_plot_set_clmn:
    ;; w |= LCD_COLUMN_ADDRESS
    iorlw LCD_COLUMN_ADDRESS
    movwf param1
    bsf param2, LCD_COMMAND
    call_other_page lcd_write

    ;; *** get pixel number in byte to set
    ;; w = var2 & PIXEL_MASK
    movlw PIXEL_MASK
    banksel var2
    andwf var2, W
    ;; put it in var1
    movwf var1

    ;; *** set Y
    ;; calculate page number: w = w / 8
    bcf STATUS, C
    rrf var2, F
    bcf STATUS, C
    rrf var2, F
    bcf STATUS, C
    rrf var2, F
    ;; set param 1 of command:
    ;; w = LCD_SET_PAGE_ADDRESS
    movlw LCD_SET_PAGE_ADDRESS
    ;; w = w | var2
    iorwf var2, W
    ;; param1 = w
    movwf param1
    call_other_page lcd_write

    ;; *** Start "read modify write mode"
    movlw LCD_READ_MODIFY_WRITE
    movwf param1
    call_other_page lcd_write

    ;; *** Get pixel in param1
    bcf param2, LCD_COMMAND
    call_other_page lcd_read
    call_other_page lcd_read

    ;; *** Set pixel
    ;; var2 = 1
    movlw 0x01
    banksel var2
    movwf var2
    ;; if var1 = 0 then goto lcd_plot_set_pix_after
    movf var1, F
    btfsc STATUS, Z
    goto lcd_plot_set_pix_after
    ;; shift bar2
    bcf STATUS, C
lcd_plot_set_pix:
    banksel var2
    rlf var2, F
    ;; var-- and loop while != 0
    decfsz var1, F
    goto lcd_plot_set_pix
lcd_plot_set_pix_after:

    ;; *** Set or unset pixel?
    btfsc param3, LCD_SET_PIXEL
    goto lcd_plot_set
lcd_plot_unset:
    ;; var2 = !var2 (equiv to xor 0xFF)
    movlw 0xFF
    banksel var2
    xorwf var2, W
    andwf param1, F
    goto lcd_plot_write

lcd_plot_set:
    ;; move var2 in w (mask to write)
    banksel var2
    movf var2, W
    ;; param1 = param1 | w
    iorwf param1, F

lcd_plot_write:
    ;; call command
    call_other_page lcd_write

    ;; *** End "read modify write mode"
    bsf param2, LCD_COMMAND
    movlw LCD_END
    movwf param1
    call_other_page lcd_write

    return

;;;
;;; write rectangle on LCD. Warning: the rectangle have to be
;;; only in one half on the lcd, of the two
;;; param1 : x
;;; param2 : y
;;; param3 : w
;;; param4 : h
;;; param5 : - Use xor or not (LCD_XOR bit).
;;;          - Set or unset pixels (LCD_SET_PIXEL bit). Only valid if xor is not activated.
;;;
lcd_rectangle:
    global lcd_rectangle

    ;; store param1
    movf param1, W
    banksel var1
    movwf var1
    ;; store param2
    movf param2, W
    movwf var2

    ;; *** Set chip
    ;; w = param1 - (LCD_WIDTH/2)
    movlw LCD_WIDTH/2
    subwf var1, W

    ;; if x is greater than LCD_WIDTH/2, goto lcd_rect_prepare_clmn_2
    btfsc STATUS, C
    goto lcd_rect_chip_2

lcd_rect_chip_1:
    bsf param2, LCD_FIRST_CHIP
    goto lcd_rect_y

lcd_rect_chip_2:
    ;; memorize x in chip 2 in param1
    banksel var1
    movwf var1
    bcf param2, LCD_FIRST_CHIP

    ;; *** Y
lcd_rect_y:
    ;; ** get lastpixel number in byte to set
    ;; param4 = var2 + param4 - 1(= absolute y2)
    banksel var2
    movf var2, W
    addwf param4, F
    decf param4, F
    ;; w = param4 & PIXEL_MASK
    movlw PIXEL_MASK
    andwf param4, W
    ;; var4 = w
    movwf var4

    ;; ** Get end page (y2 page) of rectangle
    ;; calculate page number: w = w / 8
    movf param4, W
    movwf var5
    bcf STATUS, C
    rrf var5, F
    bcf STATUS, C
    rrf var5, F
    bcf STATUS, C
    rrf var5, F

    ;; now:
    ;;  var5 is last page
    ;;  var4 is last pixel number in this page
    ;;  param4 is absolute y2 position

    ;; ** Get start y of rectangle
    ;; calculate page number: var3 = var2 / 8
    movf var2, W
    movwf var3
    bcf STATUS, C
    rrf var3, F
    bcf STATUS, C
    rrf var3, F
    bcf STATUS, C
    rrf var3, F

    ;; ** get first pixel number in byte to set
    ;; var2 = var2 & PIXEL_MASK
    movlw PIXEL_MASK
    andwf var2, F

    ;; now:
    ;;  var3 is first page
    ;;  var2 is fisrt pixel number in this page
    ;;  param2 is absolute y1 position


    ;; ** calculate number of pages (var5 = var5 - var3 + 1)
    movf var3, W
    subwf var5, W
    movwf var5
    incf var5, F


    ;; now:
    ;;  var5 is the number of page

lcd_rect_page_loop:
    ;; set param 1 of command:
    ;; w = LCD_SET_PAGE_ADDRESS
    movlw LCD_SET_PAGE_ADDRESS
    ;; w = w | var3
    banksel var3
    iorwf var3, W
    ;; param1 = w
    movwf param1
    bsf param2, LCD_COMMAND
    call_other_page lcd_write



    ;; ** Calculate mask to write
    ;; * begining of the rectangle
    ;; var7 = 0xFF
    movlw 0xFF
    banksel var7
    movwf var7

    ;; if var2 = 0 then goto lcd_rect_set_pix_start_after
    movf var2, F
    btfsc STATUS, Z
    goto lcd_rect_set_pix_start_after
    ;; shift var7
lcd_rect_set_pix_start:
    bcf STATUS, C
    banksel var7
    rlf var7, F
    ;; var-- and loop while != 0
    decfsz var2, F
    goto lcd_rect_set_pix_start
lcd_rect_set_pix_start_after:

    ;; * end of the rectangle
    ;; if var5 (number of page) is 1, it means it is the last page
    ;; So wee need to calculate the end rectangle mask
    movlw 1
    banksel var5
    subwf var5, W
    btfss STATUS, Z
    goto lcd_rect_set_clmn

    ;; This is the last page: there won't be another page loop
    ;; So, we can use var2 for another usage: put in it the result
    ;; of mask of the end the rectangle
    ;; var2 = 1
    movlw 1
    movwf var2

    ;; if var4 = 0 then goto lcd_rect_set_pix_end_after
    movf var4, F
    btfsc STATUS, Z
    goto lcd_rect_set_pix_end_after

    ;; shift var2 (and include 1 with CARRY flag)
lcd_rect_set_pix_end:
    bsf STATUS, C
    banksel var2
    rlf var2, F
    ;; var-- and loop while != 0
    decfsz var4, F
    goto lcd_rect_set_pix_end
lcd_rect_set_pix_end_after:
    ;; apply end mask (var2) on var7
    banksel var2
    movf var2, W
    andwf var7, F

    ;; ** set start column (x1)
lcd_rect_set_clmn:
    ;; w = var1
    banksel var1
    movf var1, W
    ;; w |= LCD_COLUMN_ADDRESS
    iorlw LCD_COLUMN_ADDRESS
    movwf param1
    bsf param2, LCD_COMMAND
    call_other_page lcd_write

    ;; *** Start "read modify write mode"
    movlw LCD_READ_MODIFY_WRITE
    movwf param1
    call_other_page lcd_write

    movf param3, W
    banksel var6
    movwf var6
lcd_rect_column_loop:
    ;; *** Get pixel in param1

    bcf param2, LCD_COMMAND
    call_other_page lcd_read
    call_other_page lcd_read

    ;; *** XOR ?
    btfss param5, LCD_XOR
    goto lcd_rect_set_unset
    ;; param1 = param1 xor var7
    banksel var7
    movf var7, W
    xorwf param1, F
    goto lcd_rect_write
lcd_rect_set_unset:
    ;; *** Set or unset pixels?
    btfsc param5, LCD_SET_PIXEL
    goto lcd_rect_set
lcd_rect_unset:
    ;; var7 = !var7 (equiv to xor 0xFF)
    movlw 0xFF
    banksel var7
    xorwf var7, W
    andwf param1, F
    goto lcd_rect_write

lcd_rect_set:
    ;; move var7 in w (mask to write)
    banksel var7
    movf var7, W
    ;; param1 = param1 | w
    iorwf param1, F

lcd_rect_write:
    ;; call command
    call_other_page lcd_write

    banksel var6
    decfsz var6, F
    goto lcd_rect_column_loop

    ;; w = var7
    movf var7, W
;///////////////////////////////

    ;; *** End "read modify write mode"
    bsf param2, LCD_COMMAND
    movlw LCD_END
    movwf param1
    call_other_page lcd_write

    ;; ** manage end of page loop
    banksel var3
    incf var3, F
    decfsz var5, 1
    goto lcd_rect_page_loop



    return




;;;
;;; write data to lcd
;;; param1 : data to write
;;; param2 : write status :
;;;       LCD_COMMAND    -> command if set, data otherwise
;;;       LCD_FIRST_CHIP -> write on first chip if set, on second otherwise
;;;
lcd_write:
    global lcd_write
    banksel LCD_A0_PORT
    ;; Set A0 if data, unset else
    btfss param2, LCD_COMMAND
    bsf LCD_A0_PORT, LCD_A0_BIT
    btfsc param2, LCD_COMMAND
    bcf LCD_A0_PORT, LCD_A0_BIT
    ;; Clear W
    bcf LCD_WR_PORT, LCD_WR_BIT
    ;; write data on bus
    call set_lcd_data
    ;; Set E1 if LCD_FIRST_CHIP is set
    btfsc param2, LCD_FIRST_CHIP
#ifdef INVERT_E
    bsf LCD_E2_PORT, LCD_E2_BIT
#else
    bsf LCD_E1_PORT, LCD_E1_BIT
#endif

    ;; Set E2 if LCD_FIRST_CHIP is clear
    btfss param2, LCD_FIRST_CHIP
#ifdef INVERT_E
    bsf LCD_E1_PORT, LCD_E1_BIT
#else
    bsf LCD_E2_PORT, LCD_E2_BIT
#endif
#ifdef LCD_DELAY
    ;; delay
    movlw DELAY_CS
    call delay_wait
#endif

    ;; Clear E1 and E2
    bcf LCD_E1_PORT, LCD_E1_BIT
    bcf LCD_E2_PORT, LCD_E2_BIT
    return

;;;
;;; read data from lcd
;;; param1 : return value
;;; param2 : write status :
;;;       LCD_COMMAND    -> command if set, data otherwise
;;;       LCD_FIRST_CHIP -> write on first chip if set, on second otherwise
;;;
lcd_read:
    global lcd_read
    banksel LCD_A0_PORT
    ;; Set A0 if data, unset else
    btfss param2, LCD_COMMAND
    bsf LCD_A0_PORT, LCD_A0_BIT
    btfsc param2, LCD_COMMAND
    bcf LCD_A0_PORT, LCD_A0_BIT

    ;; Set W
    bsf LCD_WR_PORT, LCD_WR_BIT

    ;; Set E1 if LCD_FIRST_CHIP is set
    btfsc param2, LCD_FIRST_CHIP
#ifdef INVERT_E
    bsf LCD_E2_PORT, LCD_E2_BIT
#else
    bsf LCD_E1_PORT, LCD_E1_BIT
#endif

    ;; Set E2 if LCD_FIRST_CHIP is clear
    btfss param2, LCD_FIRST_CHIP
#ifdef INVERT_E
    bsf LCD_E1_PORT, LCD_E1_BIT
#else
    bsf LCD_E2_PORT, LCD_E2_BIT
#endif

#ifdef LCD_DELAY
    ;; delay
    movlw DELAY_CS
    call delay_wait
#endif

    ;; read data from bus
    call get_lcd_data

    ;; Clear E1 and E2
    bcf LCD_E1_PORT, LCD_E1_BIT
    bcf LCD_E2_PORT, LCD_E2_BIT

    return

;;;
;;; set  data on lcd data bus
;;; param1 : data to write
;;;
set_lcd_data:
    global set_lcd_data


    ;; configure gpio
    call_other_page io_config_lcd_data_output

#ifdef LCD_ALL_BIT_IN_SAME_REG
    banksel LCD_DATA_PORT
    movf param1, W
    movwf LCD_DATA_PORT
#else
    ;; set lcd_data
    set_lcd_data_bit 0, param1
    set_lcd_data_bit 1, param1
    set_lcd_data_bit 2, param1
    set_lcd_data_bit 3, param1
    set_lcd_data_bit 4, param1
    set_lcd_data_bit 5, param1
    set_lcd_data_bit 6, param1
    set_lcd_data_bit 7, param1
#endif
    return


;;;
;;; get data on lcd data bus
;;; param1 : return value
;;;
get_lcd_data:
    global get_lcd_data
    ;; configure gpio
    call_other_page io_config_lcd_data_input

    ;; clear param1
    clrf param1

#ifdef LCD_ALL_BIT_IN_SAME_REG
    banksel LCD_DATA_PORT
    movf LCD_DATA_PORT, W
    movwf param1
#else
    ;; set each bit according to IO
    get_lcd_data_bit 0
    get_lcd_data_bit 1
    get_lcd_data_bit 2
    get_lcd_data_bit 3
    get_lcd_data_bit 4
    get_lcd_data_bit 5
    get_lcd_data_bit 6
    get_lcd_data_bit 7
#endif

    return

;;;
;;; Print one characater from an integer value
;;; reg_value: register which contain the integer value
;;; unit: unit character which has to be printed
;;; max_unit: maximal possible value for the unit
;;; char_pos: character position
;;; var4 is used as configuration and let unchanged. Its format is the same as
;;; param2 from lcd_int function
;;; Changed registers: var2, var5, reg_value
;;;
lcd_int_print_unit macro reg_value, unit, max_unit, char_pos
    local lcd_int_print_unit_continue
    local lcd_int_print_unit_end
    local lcd_int_print_unit_before_print
    local lcd_int_print_unit_big_char
    local lcd_int_print_unit_after_print
    movlw 0x00
    banksel var2
    movwf var2

lcd_int_print_unit_continue:
    movlw unit
    subwf reg_value, W
    btfss STATUS, C
    goto lcd_int_print_unit_end
    movlw unit
    subwf reg_value, F
    incf var2, F
    movlw max_unit
    subwf var2, W
    btfsc STATUS, Z
    goto lcd_int_print_unit_end
    goto lcd_int_print_unit_continue

lcd_int_print_unit_end:
    ;; Print unit value
    banksel var2
    movf var2, W
#if 0
    btfsc STATUS, Z
    btfsc var4, LCD_INT_SHT_USELESS_ZERO
    goto lcd_int_print_unit_before_print
    goto lcd_int_print_unit_after_print
#else
    btfss STATUS, Z
    goto lcd_int_print_unit_before_print
    movf var4, W
    andlw LCD_INT_MASK_FILLING_ZERO
    movwf var5
    rshift_f var5, LCD_INT_SHT_FILLING_ZERO
    movf var5, W
    sublw char_pos
    btfsc STATUS, C
    goto lcd_int_print_unit_after_print
    movf var2, W
#endif

lcd_int_print_unit_before_print:
    addlw '0'
    movwf param1
    banksel var4
    btfsc var4, LCD_INT_SHT_BIG_CHAR
    goto lcd_int_print_unit_big_char
    call_other_page lcd_char
    goto lcd_int_print_unit_after_print
lcd_int_print_unit_big_char:
    call_other_page lcd_big_char
lcd_int_print_unit_after_print:
    endm

;;;
;;; Print an integer on current position of LCD
;;; param1: value of integer to be printed
;;; param2: bit 1 - 0: position of decimal point. If 0, no decimal point
;;;         bit 3 - 2: number of filling 0
;;;         bit 4: 0 for normal char, 1 for big char
;;; used variables: var1, var2, var3, var4
;;;
lcd_int:
    global lcd_int
    ;; Save param
    movf param1, W
    banksel var3
    movwf var3
    movf param2, W
    movwf var4

    movf var4, W
    sublw LCD_INT_DEC_POS_100
    btfss STATUS, Z
    goto lcd_int_print_100
    movlw '.'
    movwf param1
    call_other_page lcd_char
lcd_int_print_100:
    banksel var3
    lcd_int_print_unit var3, 0x64, 2, 2
    banksel var4
    movf var4, W
    andlw LCD_INT_MASK_COMA_POS
    sublw LCD_INT_DEC_POS_10
    btfss STATUS, Z
    goto lcd_int_print_10
    movlw '.'
    movwf param1
    call_other_page lcd_char
lcd_int_print_10:
    banksel var3
    lcd_int_print_unit var3, 0x0A, 9, 1
    banksel var4
    movf var4, W
    andlw LCD_INT_MASK_COMA_POS
    sublw LCD_INT_DEC_POS_1
    btfss STATUS, Z
    goto lcd_int_print_1
    movlw '.'
    movwf param1
    call_other_page lcd_char
lcd_int_print_1:
    ;; Print last unit
    banksel var3
    movf var3, W
    addlw '0'
    movwf param1
    btfsc var4, LCD_INT_SHT_BIG_CHAR
    goto lcd_int_print_big_char
    call_other_page lcd_char
    goto lcd_int_print_end
lcd_int_print_big_char:
    call_other_page lcd_big_char
lcd_int_print_end:
    return

;;;
;;; locate and draw a string
;;; param1: x
;;; param2: y
;;; param3: addrl of null terminated string
;;; param4: addrh of null terminated string
;;; used variables: var3, var4, var5
;;;
lcd_loc_string:
    global lcd_loc_string

    ;; store param1 and param2
    movf param1, W
    banksel var3
    movwf var3
    movf param2, W
    movwf var4

    ;; *** Draw string
    ;; init position counter (in var5)
    banksel var5
    clrf var5
lcd_loc_string_loop:
    ;; locate
    banksel var3
    movf var3, W
    movwf param1
    movf var4, W
    movwf param2
    call_other_page lcd_locate
#if 0
    ;; start read_modify_write
    movlw LCD_READ_MODIFY_WRITE
    movwf param1
    bsf param2, LCD_COMMAND
    call_other_page lcd_write
#endif
    ;;  set addr to read
    banksel var5
    movf var5, W
    addwf param3, W
    banksel EEADR
    movwf EEADR

    movf param4, W
    banksel EEADRH
    movwf EEADRH
    btfsc STATUS, C
    incf EEADRH, F

    ;;  read  flash
    banksel EECON1
    bsf EECON1, EEPGD
    bsf EECON1, RD
    nop
    nop
    ;; verify if last char
    banksel EEDAT
    movf EEDAT, W
    sublw 0
    btfsc STATUS, Z
    ;; It's 0 -> finished
    goto lcd_loc_string_end
    ;; write read data in param1 and draw char
    banksel EEDAT
    movf EEDAT, W
    movwf param1
    call_other_page lcd_char

    banksel var5
    incf var5, F
    incf var3, F
    goto lcd_loc_string_loop

#if 0
    ;; end of read modify write
    bsf param2, LCD_COMMAND
    movlw LCD_END
    movwf param1
    call_other_page lcd_write
#endif
lcd_loc_string_end:
#if 0
    lcd_send_cmd_1 LCD_END, 0
    lcd_send_cmd_2 LCD_END, 0
#endif
    return

;;;
;;; draw a string
;;; param1: addrl of null terminated string
;;; param2: addrh of null terminated string
;;; used variables: var3, var4, var5
;;;
lcd_string:
    global lcd_string
    ;; Save params
    movf param1, W
    banksel var3
    movwf var3
    movf param2, W
    movwf var4

    ;; *** Draw string
    ;; init position counter (in var5)
    clrf var5
lcd_string_loop:
#if 0
    ;; start read_modify_write
    movlw LCD_READ_MODIFY_WRITE
    movwf param1
    bsf param2, LCD_COMMAND
    call_other_page lcd_write
#endif
    ;;  set addr to read
    banksel var5
    movf var5, W
    addwf var3, W
    banksel EEADR
    movwf EEADR

    banksel var4
    movf var4, W
    banksel EEADRH
    movwf EEADRH
    btfsc STATUS, C
    incf EEADRH, F

    ;;  read  flash
    banksel EECON1
    bsf EECON1, EEPGD
    bsf EECON1, RD
    nop
    nop
    ;; verify if last char
    banksel EEDAT
    movf EEDAT, W
    sublw 0
    btfsc STATUS, Z
    ;; It's 0 -> finished
    goto lcd_string_end
    ;; write read data in param1 and draw char
    movf EEDAT, W
    banksel param1
    movwf param1
    call_other_page lcd_char

    banksel var5
    incf var5, F
    goto lcd_string_loop

#if 0
    ;; end of read modify write
    bsf param2, LCD_COMMAND
    movlw LCD_END
    movwf param1
    call_other_page lcd_write
#endif
lcd_string_end:
#if 0
    lcd_send_cmd_1 LCD_END, 0
    lcd_send_cmd_2 LCD_END, 0
#endif
    return

;;;
;;; set the text position
;;; param1: x
;;; param2: y
;;; used variables: var1, var2
;;;
lcd_locate:
    global lcd_locate
    ;; store param 1
    movf param1, W
    banksel lcd_save_x
    movwf lcd_save_x
    ;; store param 2
    movf param2, W
    banksel lcd_save_y
    movwf lcd_save_y
    banksel var2
    movwf var2

    ;; *** Set x position
    movlw LCD_WIDTH_TXT/2
    subwf param1, W

    ;; if x is greater than LCD_WIDTH/2, goto lcd_locate_chip_2
    btfsc STATUS, C
    goto lcd_locate_chip_2
lcd_locate_chip_1:
    ;; lcd chip 1
    bsf param2, LCD_FIRST_CHIP
    goto lcd_locate_mult_x
lcd_locate_chip_2:
    ;; lcd chip 2
    movwf param1
    bcf param2, LCD_FIRST_CHIP

lcd_locate_mult_x:
    ;; save param2 (to know what chip to use)
    movf param2, W
    banksel lcd_save_chip
    movwf lcd_save_chip
    banksel var1
    lshift_f param1, LCD_CHAR_WIDTH_SHIFT
    ;; Add 1 if chip 1, otherwise there would be a space between each chip
    btfsc param2, LCD_FIRST_CHIP
    incf param1, F

    movlw LCD_COLUMN_ADDRESS
    iorwf param1, F

    bsf param2, LCD_COMMAND
    call_other_page lcd_write

    ;; *** Set y position
    ;; lcd page 0
    banksel var2
    movf var2, W
    iorlw LCD_SET_PAGE_ADDRESS
    movwf param1
    bsf param2, LCD_COMMAND
    call_other_page lcd_write
    return

;;;
;;; draw a char
;;; param1: is the character number
;;; used variables: var1, param2
;;;
lcd_char:
    global lcd_char

    ;;  restore param2 (the chip to be used)
    banksel lcd_save_chip
    movf lcd_save_chip, W
    movwf param2

    movlw FIRST_FONT_CHAR_NUM
    subwf param1, F

    ;; set addr to read
    banksel EEADR
    movlw high font
    movwf EEADRH
    movlw low font
    movwf EEADR
    banksel var1
    ;; add offset of char (4 times the character position):
    ;; loop LCD_CHAR_WIDTH times
    movlw LCD_CHAR_WIDTH
    movwf var1
lcd_char_add_offset_loop:
    bcf STATUS, C
    movf param1, W
    banksel EEADR
    addwf EEADR, F
    btfsc STATUS, C
    incf EEADRH, F
    banksel var1
    decfsz var1, F
    goto lcd_char_add_offset_loop

#if 0
    ;; start read modify write
    movlw LCD_READ_MODIFY_WRITE
    movwf param1
    bsf param2, LCD_COMMAND
    call_other_page lcd_write
#endif
    ;; prepare loop var
    movlw LCD_CHAR_WIDTH
    banksel var1
    movwf var1

lcd_char_loop:
    ;;  read  flash
    banksel EECON1
    bsf EECON1, EEPGD
    bsf EECON1, RD
    nop
    nop

    ;; write data
    bcf param2, LCD_COMMAND
    banksel EEDAT
    ;; movlw FIRST_FONT_CHAR_NUM
    movf EEDAT, W
    movwf param1
    call_other_page lcd_write

    banksel EEADR
    incf EEADR, F
    btfss STATUS, Z
    goto loop_char_end_loop
    incf EEADRH, F
loop_char_end_loop:
    banksel var1
    decfsz var1, F
    goto lcd_char_loop
#if 0
    nop
    nop
    nop
    ;; end of read modify write
    bsf param2, LCD_FIRST_CHIP
    bsf param2, LCD_COMMAND
    movlw LCD_END
    movwf param1
    call_other_page lcd_write
    ;; end of read modify write
    bcf param2, LCD_FIRST_CHIP
    bsf param2, LCD_COMMAND
    movlw LCD_END
    movwf param1
    call_other_page lcd_write

#endif
    ;; increment saved x position
    banksel lcd_save_x
    incf lcd_save_x, F
    return

;;;
;;; draw a big char
;;; param1: is the character number
;;; used variables: var1, param2
;;;
lcd_big_char:
    global lcd_big_char

    ;;  restore param2 (the chip to be used)
    banksel lcd_save_chip
    movf lcd_save_chip, W
    movwf param2

    movlw FIRST_FONT_BIG_CHAR_NUM
    subwf param1, W
    movwf param1

    banksel var1
    movwf var1
    rshift_f var1, LCD_NB_BIG_CHAR_BY_LINE_SHT
    lshift_f var1, (LCD_NB_BIG_CHAR_BY_LINE_SHT + 1)

    movf param1, W
    andlw ((1 << LCD_NB_BIG_CHAR_BY_LINE_SHT) - 1)
    addwf var1, W
    movwf param1

    ;;  set addr to read
    banksel EEADR
    movlw high font_big
    movwf EEADRH
    movlw low font_big
    movwf EEADR
    banksel var1
    ;; add offset of char
    ;; loop LCD_BIG_CHAR_WIDTH times
    movlw LCD_BIG_CHAR_WIDTH
    movwf var1
lcd_big_char_add_offset_loop:
    bcf STATUS, C
    movf param1, W
    banksel EEADR
    addwf EEADR, F
    btfsc STATUS, C
    incf EEADRH, F
    banksel var1
    decfsz var1, F
    goto lcd_big_char_add_offset_loop

    ;; Draw top of char
    call lcd_big_char_sub_func
    ;; Prepare to drow bottom of char
    ;; Change lcd position
    banksel lcd_save_x
    movf lcd_save_x, W
    movwf param1
    banksel lcd_save_y
    movf lcd_save_y, W
    movwf param2
    incf param2, F
    call lcd_locate
    ;; Change offset in flash (add 1 line minus 1 char)


    ;; movlw (((1 << LCD_NB_BIG_CHAR_BY_LINE_SHT) - 1) * LCD_BIG_CHAR_WIDTH)
    movlw .56
    banksel EEADR
    addwf EEADR, F
    btfss STATUS, C
    goto big_char_next_line
    incf EEADRH, F
big_char_next_line:

    ;; Draw bottom of char
    call lcd_big_char_sub_func

    ;; Set location the new position
    banksel lcd_save_x
    movf lcd_save_x, W
    addlw 2
    movwf param1
    banksel lcd_save_y
    movf lcd_save_y, W
    movwf param2
    decf param2, F
    call lcd_locate

    return


;;;
;;; Sub function of lcd_big_char function
;;;
lcd_big_char_sub_func:
    ;; prepare loop var
    movlw LCD_BIG_CHAR_WIDTH
    banksel var1
    movwf var1
lcd_big_char_loop:
    ;;  read  flash
    banksel EECON1
    bsf EECON1, EEPGD
    bsf EECON1, RD
    nop
    nop

    ;; write data
    bcf param2, LCD_COMMAND
    banksel EEDAT
    ;; movlw FIRST_FONT_BIG_CHAR_NUM
    movf EEDAT, W
    movwf param1
    call_other_page lcd_write

    banksel EEADR
    incf EEADR, F

    btfss STATUS, Z
    goto loop_big_char_end_loop
    incf EEADRH, F

loop_big_char_end_loop:
    banksel var1
    decfsz var1, F
    goto lcd_big_char_loop
    return





#if 0
lcd_test_io_on:
    global lcd_test_io_on
#ifdef LCD_ALL_BIT_IN_SAME_REG
    movlw 0xFF
    movwf LCD_DATA_PORT
#else
    bsf LCD_DATA_0_PORT, LCD_DATA_0_BIT
    bsf LCD_DATA_1_PORT, LCD_DATA_1_BIT
    bsf LCD_DATA_2_PORT, LCD_DATA_2_BIT
    bsf LCD_DATA_3_PORT, LCD_DATA_3_BIT
    bsf LCD_DATA_4_PORT, LCD_DATA_4_BIT
    bsf LCD_DATA_5_PORT, LCD_DATA_5_BIT
    bsf LCD_DATA_6_PORT, LCD_DATA_6_BIT
    bsf LCD_DATA_7_PORT, LCD_DATA_7_BIT
#endif

    bsf LCD_E1_PORT, LCD_E1_BIT
    bsf LCD_E2_PORT, LCD_E2_BIT
    bsf LCD_WR_PORT, LCD_WR_BIT
    bsf LCD_A0_PORT, LCD_A0_BIT

    goto $
    ;; never return !
    return

lcd_test_io_off:
    global lcd_test_io_off
#ifdef LCD_ALL_BIT_IN_SAME_REG
    movlw 0x00
    movwf LCD_DATA_PORT
#else
    bcf LCD_DATA_0_PORT, LCD_DATA_0_BIT
    bcf LCD_DATA_1_PORT, LCD_DATA_1_BIT
    bcf LCD_DATA_2_PORT, LCD_DATA_2_BIT
    bcf LCD_DATA_3_PORT, LCD_DATA_3_BIT
    bcf LCD_DATA_4_PORT, LCD_DATA_4_BIT
    bcf LCD_DATA_5_PORT, LCD_DATA_5_BIT
    bcf LCD_DATA_6_PORT, LCD_DATA_6_BIT
    bcf LCD_DATA_7_PORT, LCD_DATA_7_BIT
#endif

    bcf LCD_E1_PORT, LCD_E1_BIT
    bcf LCD_E2_PORT, LCD_E2_BIT
    bcf LCD_WR_PORT, LCD_WR_BIT
    bcf LCD_A0_PORT, LCD_A0_BIT

    goto $
    ;; never return !
    return

lcd_test_io_blink:
    global lcd_test_io_blink
    call_other_page lcd_test_io_on

#ifdef LCD_DELAY
    movlw 0xFF
    call delay_wait
#endif

    call_other_page lcd_test_io_off

#ifdef LCD_DELAY
    movlw 0xFF
    call delay_wait
#endif

    goto lcd_test_io_blink
    ;; never return !
    return
#endif

font:
#include <font.inc>
font_big:
#include <font-big.inc>
END

; NJU6450 based LCD. NJU6450 is almost SED1520.
; The interface between the controller and the MPU is 68 type

#define LCD_M

#include <cpu.inc>
#include <global.inc>
#include <io.inc>
#include <delay.inc>
#include <lcd.inc>


#define DELAY_RESET 4
#define DELAY_CS 2

#define PIXEL_MASK     0x07

    UDATA
var1       RES 1
var2       RES 1
var3       RES 1
var4       RES 1
var5       RES 1
var6       RES 1
var7       RES 1

;#define DELAY_RESET 0xFF
;#define DELAY_CS 0xFF

set_lcd_data_bit macro num_bit, value
set_lcd_data_#v(num_bit)
        btfsc value, num_bit
        goto set_lcd_data_set_#v(num_bit)
        bcf LCD_DATA_#v(num_bit)_PORT, LCD_DATA_#v(num_bit)_BIT
        goto set_lcd_data_after_#v(num_bit)
set_lcd_data_set_#v(num_bit)
        bsf LCD_DATA_#v(num_bit)_PORT, LCD_DATA_#v(num_bit)_BIT
set_lcd_data_after_#v(num_bit)
    endm

get_lcd_data_bit macro num_bit
        btfsc LCD_DATA_#v(num_bit)_PORT, LCD_DATA_#v(num_bit)_BIT
        bsf param1, num_bit
    endm

; relocatable code
PROG CODE


; Init LCD
; no parameters
lcd_init
    global lcd_init    ; initial delay
    ;movlw 0xFF
    ;call delay_wait

    ; reset lcd

    bcf LCD_E1_PORT, LCD_E1_BIT
    bcf LCD_E2_PORT, LCD_E2_BIT

    ;bsf LCD_WR_PORT, LCD_WR_BIT
    bcf LCD_WR_PORT, LCD_WR_BIT

    bcf LCD_A0_PORT, LCD_A0_BIT
#if 1
    ; init lcd 1
    lcd_send_cmd_1 LCD_DISPLAY_ON_OFF, 0
    lcd_send_cmd_1 LCD_DISPLAY_START_LINE, 0
    lcd_send_cmd_1 LCD_STATIC_DRIVE_ON_OFF, 0
    lcd_send_cmd_1 LCD_COLUMN_ADDRESS, 0
    lcd_send_cmd_1 LCD_SET_PAGE_ADDRESS, 0

    lcd_send_cmd_1 LCD_SELECT_DUTY, 1
    lcd_send_cmd_1 LCD_SELECT_ADC, 0

    lcd_send_cmd_1 LCD_END, 0
#endif
    ; init lcd 2
    lcd_send_cmd_2 LCD_DISPLAY_ON_OFF, 0

    lcd_send_cmd_2 LCD_DISPLAY_START_LINE, 0
    lcd_send_cmd_2 LCD_STATIC_DRIVE_ON_OFF, 0
    lcd_send_cmd_2 LCD_COLUMN_ADDRESS, 0
    lcd_send_cmd_2 LCD_SET_PAGE_ADDRESS, 0

    lcd_send_cmd_2 LCD_SELECT_DUTY, 1
    lcd_send_cmd_2 LCD_SELECT_ADC, 0

    lcd_send_cmd_2 LCD_END, 0


    call lcd_clear

    lcd_send_cmd_1 LCD_DISPLAY_ON_OFF, 1
    lcd_send_cmd_2 LCD_DISPLAY_ON_OFF, 1

    return

; Clear the entire LCD
; no parameters
lcd_clear
    global lcd_clear
    movlw 4 ; number of page
    movwf var1

loop_pages
    movlw 40 ; number of column
    movwf var2

    ; set column 0
    movlw LCD_COLUMN_ADDRESS
    movwf param1

    bsf param2, LCD_COMMAND
    bsf param2, LCD_FIRST_CHIP
    call lcd_write
    bcf param2, LCD_FIRST_CHIP
    call lcd_write

    ; set page var1
    movlw LCD_SET_PAGE_ADDRESS
    decf var1, F
    iorwf var1, W
    movwf param1
    incf var1, F

    ; second chip (bit unset on previous command)
    call lcd_write
    ; first chip
    bsf param2, LCD_FIRST_CHIP
    call lcd_write

    bcf param2, LCD_COMMAND
loop_column
    movlw 0
    movwf param1
    bsf param2, LCD_FIRST_CHIP
    call lcd_write
    bcf param2, LCD_FIRST_CHIP
    call lcd_write


    decfsz var2, F
    goto loop_column

    decfsz var1, F
    goto loop_pages

    return

; plot in lcd
; param1 : x
; param2 : y
; param3 : - Use xor or not (LCD_XOR bit).
;          - Set or unset pixels (LCD_SET_PIXEL bit). Only valid if xor is not activated.

lcd_plot
    global lcd_plot
    ; store param1
    movf param1, W
    movwf var1
    ; store param2
    movf param2, W
    movwf var2

    ; *** set X
    ; w = param1 - (LCD_WIDTH/2)
    movlw LCD_WIDTH/2
    subwf var1, W

    ; if x is greater than LCD_WIDTH/2, goto lcd_plot_prepare_clmn_2
    btfsc STATUS, C
    goto lcd_plot_prepare_clmn_2

lcd_plot_prepare_clmn_1
    movf var1, W
    bsf param2, LCD_FIRST_CHIP
    goto lcd_plot_set_clmn

lcd_plot_prepare_clmn_2
    bcf param2, LCD_FIRST_CHIP

lcd_plot_set_clmn
    ; w |= LCD_COLUMN_ADDRESS
    iorlw LCD_COLUMN_ADDRESS
    movwf param1
    bsf param2, LCD_COMMAND
    call lcd_write

    ; *** get pixel number in byte to set
    ; w = var2 & PIXEL_MASK
    movlw PIXEL_MASK
    andwf var2, W
    ; put it in var1
    movwf var1

    ; *** set Y
    ; calculate page number: w = w / 8
    bcf STATUS, C
    rrf var2, F
    bcf STATUS, C
    rrf var2, F
    bcf STATUS, C
    rrf var2, F
    ; set param 1 of command:
    ; w = LCD_SET_PAGE_ADDRESS
    movlw LCD_SET_PAGE_ADDRESS
    ; w = w | var2
    iorwf var2, W
    ; param1 = w
    movwf param1
    call lcd_write

    ; *** Start "read modify write mode"
    movlw LCD_READ_MODIFY_WRITE
    movwf param1
    call lcd_write

    ; *** Get pixel in param1
    bcf param2, LCD_COMMAND
    call lcd_read
    call lcd_read

    ; *** Set pixel
    ; var2 = 1
    movlw 0x01
    movwf var2
    ; if var1 = 0 then goto lcd_plot_set_pix_after
    movf var1, F
    btfsc STATUS, Z
    goto lcd_plot_set_pix_after
    ; shift bar2
    bcf STATUS, C
lcd_plot_set_pix
    rlf var2, F
    ; var-- and loop while != 0
    decfsz var1, F
    goto lcd_plot_set_pix
lcd_plot_set_pix_after

    ; *** Set or unset pixel?
    btfsc param3, LCD_SET_PIXEL
    goto lcd_plot_set
lcd_plot_unset
    ; var2 = !var2 (equiv to xor 0xFF)
    movlw 0xFF
    xorwf var2, W
    andwf param1, F
    goto lcd_plot_write

lcd_plot_set
    ; move var2 in w (mask to write)
    movf var2, W
    ; param1 = param1 | w
    iorwf param1, F

lcd_plot_write
    ; call command
    call lcd_write

    ; *** End "read modify write mode"
    bsf param2, LCD_COMMAND
    movlw LCD_END
    movwf param1
    call lcd_write

    return

; write rectangle on LCD. Warning: the rectangle have to be
; only in one half on the lcd, of the two
; param1 : x
; param2 : y
; param3 : w
; param4 : h
; param5 : - Use xor or not (LCD_XOR bit).
;          - Set or unset pixels (LCD_SET_PIXEL bit). Only valid if xor is not activated.
lcd_rectangle
    global lcd_rectangle

    ; store param1
    movf param1, W
    movwf var1
    ; store param2
    movf param2, W
    movwf var2

    ; *** Set chip
    ; w = param1 - (LCD_WIDTH/2)
    movlw LCD_WIDTH/2
    subwf var1, W

    ; if x is greater than LCD_WIDTH/2, goto lcd_rect_prepare_clmn_2
    btfsc STATUS, C
    goto lcd_rect_chip_2

lcd_rect_chip_1
    bsf param2, LCD_FIRST_CHIP
    goto lcd_rect_y

lcd_rect_chip_2
    ; memorize x in chip 2 in param1
    movwf var1
    bcf param2, LCD_FIRST_CHIP

    ; *** Y
lcd_rect_y
    ; ** get lastpixel number in byte to set
    ; param4 = var2 + param4 - 1(= absolute y2)
    movf var2, W
    addwf param4, F
    decf param4, F
    ; w = param4 & PIXEL_MASK
    movlw PIXEL_MASK
    andwf param4, W
    ; var4 = w
    movwf var4

    ; ** Get end page (y2 page) of rectangle
    ; calculate page number: w = w / 8
    movf param4, W
    movwf var5
    bcf STATUS, C
    rrf var5, F
    bcf STATUS, C
    rrf var5, F
    bcf STATUS, C
    rrf var5, F

    ; now:
    ;  var5 is last page
    ;  var4 is last pixel number in this page
    ;  param4 is absolute y2 position

    ; ** Get start y of rectangle
    ; calculate page number: var3 = var2 / 8
    movf var2, W
    movwf var3
    bcf STATUS, C
    rrf var3, F
    bcf STATUS, C
    rrf var3, F
    bcf STATUS, C
    rrf var3, F

    ; ** get first pixel number in byte to set
    ; var2 = var2 & PIXEL_MASK
    movlw PIXEL_MASK
    andwf var2, F

    ; now:
    ;  var3 is first page
    ;  var2 is fisrt pixel number in this page
    ;  param2 is absolute y1 position


    ; ** calculate number of pages (var5 = var5 - var3 + 1)
    movf var3, W
    subwf var5, W
    movwf var5
    incf var5, F


    ; now:
    ;  var5 is the number of page

lcd_rect_page_loop
    ; set param 1 of command:
    ; w = LCD_SET_PAGE_ADDRESS
    movlw LCD_SET_PAGE_ADDRESS
    ; w = w | var3
    iorwf var3, W
    ; param1 = w
    movwf param1
    bsf param2, LCD_COMMAND
    call lcd_write



    ; ** Calculate mask to write
    ; * begining of the rectangle
    ; var7 = 0xFF
    movlw 0xFF
    movwf var7

    ; if var2 = 0 then goto lcd_rect_set_pix_start_after
    movf var2, F
    btfsc STATUS, Z
    goto lcd_rect_set_pix_start_after
    ; shift var7
lcd_rect_set_pix_start
    bcf STATUS, C
    rlf var7, F
    ; var-- and loop while != 0
    decfsz var2, F
    goto lcd_rect_set_pix_start
lcd_rect_set_pix_start_after

    ; * end of the rectangle
    ; if var5 (number of page) is 1, it means it is the last page
    ; So wee need to calculate the end rectangle mask
    movlw 1
    subwf var5, W
    btfss STATUS, Z
    goto lcd_rect_set_clmn

    ; This is the last page: there won't be another page loop
    ; So, we can use var2 for another usage: put in it the result
    ; of mask of the end the rectangle
    ; var2 = 1
    movlw 1
    movwf var2

    ; if var4 = 0 then goto lcd_rect_set_pix_end_after
    movf var4, F
    btfsc STATUS, Z
    goto lcd_rect_set_pix_end_after

    ; shift var2 (and include 1 with CARRY flag)
lcd_rect_set_pix_end
    bsf STATUS, C
    rlf var2, F
    ; var-- and loop while != 0
    decfsz var4, F
    goto lcd_rect_set_pix_end
lcd_rect_set_pix_end_after
    ; apply end mask (var2) on var7
    movf var2, W
    andwf var7, F

    ; ** set start column (x1)
lcd_rect_set_clmn
    ; w = var1
    movf var1, W
    ; w |= LCD_COLUMN_ADDRESS
    iorlw LCD_COLUMN_ADDRESS
    movwf param1
    bsf param2, LCD_COMMAND
    call lcd_write

    ; *** Start "read modify write mode"
    movlw LCD_READ_MODIFY_WRITE
    movwf param1
    call lcd_write

    movf param3, W
    movwf var6
lcd_rect_column_loop
    ; *** Get pixel in param1

    bcf param2, LCD_COMMAND
    call lcd_read
    call lcd_read

    ; *** XOR ?
    btfss param5, LCD_XOR
    goto lcd_rect_set_unset
    ; param1 = param1 xor var7
    movf var7, W
    xorwf param1, F
    goto lcd_rect_write
lcd_rect_set_unset
    ; *** Set or unset pixels?
    btfsc param5, LCD_SET_PIXEL
    goto lcd_rect_set
lcd_rect_unset
    ; var7 = !var7 (equiv to xor 0xFF)
    movlw 0xFF
    xorwf var7, W
    andwf param1, F
    goto lcd_rect_write

lcd_rect_set
    ; move var7 in w (mask to write)
    movf var7, W
    ; param1 = param1 | w
    iorwf param1, F

lcd_rect_write
    ; call command
    call lcd_write


    decfsz var6, F
    goto lcd_rect_column_loop

    ; w = var7
    movf var7, W
;///////////////////////////////

    ; *** End "read modify write mode"
    bsf param2, LCD_COMMAND
    movlw LCD_END
    movwf param1
    call lcd_write

    ; ** manage end of page loop
    incf var3, F
    decfsz var5, 1
    goto lcd_rect_page_loop



    return





; write data to lcd
; param1 : data to write
; param2 : write status :
;       LCD_COMMAND    -> command if set, data otherwise
;       LCD_FIRST_CHIP -> write on first chip if set, on second otherwise
lcd_write
    global lcd_write

    ; Set A0 if data, unset else
    btfss param2, LCD_COMMAND
    bsf LCD_A0_PORT, LCD_A0_BIT
    btfsc param2, LCD_COMMAND
    bcf LCD_A0_PORT, LCD_A0_BIT
    ; Clear W
    bcf LCD_WR_PORT, LCD_WR_BIT
    ; write data on bus
    call set_lcd_data
    ; Set E1 if LCD_FIRST_CHIP is set
    btfsc param2, LCD_FIRST_CHIP
#ifdef INVERT_E
    bsf LCD_E2_PORT, LCD_E2_BIT
#else
    bsf LCD_E1_PORT, LCD_E1_BIT
#endif

    ; Set E2 if LCD_FIRST_CHIP is clear
    btfss param2, LCD_FIRST_CHIP
#ifdef INVERT_E
    bsf LCD_E1_PORT, LCD_E1_BIT
#else
    bsf LCD_E2_PORT, LCD_E2_BIT
#endif
#ifdef LCD_DELAY
    ; delay
    movlw DELAY_CS
    call delay_wait
#endif

    ; Clear E1 and E2
    bcf LCD_E1_PORT, LCD_E1_BIT
    bcf LCD_E2_PORT, LCD_E2_BIT
    return

; read data from lcd
; param1 : return value
; param2 : write status :
;       LCD_COMMAND    -> command if set, data otherwise
;       LCD_FIRST_CHIP -> write on first chip if set, on second otherwise
lcd_read
    global lcd_read

    ; Set A0 if data, unset else
    btfss param2, LCD_COMMAND
    bsf LCD_A0_PORT, LCD_A0_BIT
    btfsc param2, LCD_COMMAND
    bcf LCD_A0_PORT, LCD_A0_BIT

    ; Set W
    bsf LCD_WR_PORT, LCD_WR_BIT

    ; Set E1 if LCD_FIRST_CHIP is set
    btfsc param2, LCD_FIRST_CHIP
#ifdef INVERT_E
    bsf LCD_E2_PORT, LCD_E2_BIT
#else
    bsf LCD_E1_PORT, LCD_E1_BIT
#endif

    ; Set E2 if LCD_FIRST_CHIP is clear
    btfss param2, LCD_FIRST_CHIP
#ifdef INVERT_E
    bsf LCD_E1_PORT, LCD_E1_BIT
#else
    bsf LCD_E2_PORT, LCD_E2_BIT
#endif

#ifdef LCD_DELAY
    ; delay
    movlw DELAY_CS
    call delay_wait
#endif

    ; read data from bus
    call get_lcd_data

    ; Clear E1 and E2
    bcf LCD_E1_PORT, LCD_E1_BIT
    bcf LCD_E2_PORT, LCD_E2_BIT

    return

; set  data on lcd data bus
; param1 : data to write
set_lcd_data
    global set_lcd_data


    ; configure gpio
    call io_config_lcd_data_output

    ; set lcd_data
    set_lcd_data_bit 0, param1
    set_lcd_data_bit 1, param1
    set_lcd_data_bit 2, param1
    set_lcd_data_bit 3, param1
    set_lcd_data_bit 4, param1
    set_lcd_data_bit 5, param1
    set_lcd_data_bit 6, param1
    set_lcd_data_bit 7, param1
    return



; get data on lcd data bus
; param1 : return value
get_lcd_data
    global get_lcd_data
    ; configure gpio
    call io_config_lcd_data_input

    ; clear param1
    clrf param1

    ; set each bit according to IO
    get_lcd_data_bit 0
    get_lcd_data_bit 1
    get_lcd_data_bit 2
    get_lcd_data_bit 3
    get_lcd_data_bit 4
    get_lcd_data_bit 5
    get_lcd_data_bit 6
    get_lcd_data_bit 7

    return

lcd_test_io_on
    global lcd_test_io_on
    bsf LCD_DATA_0_PORT, LCD_DATA_0_BIT
    bsf LCD_DATA_1_PORT, LCD_DATA_1_BIT
    bsf LCD_DATA_2_PORT, LCD_DATA_2_BIT
    bsf LCD_DATA_3_PORT, LCD_DATA_3_BIT
    bsf LCD_DATA_4_PORT, LCD_DATA_4_BIT
    bsf LCD_DATA_5_PORT, LCD_DATA_5_BIT
    bsf LCD_DATA_6_PORT, LCD_DATA_6_BIT
    bsf LCD_DATA_7_PORT, LCD_DATA_7_BIT
#if 1
    bsf LCD_E1_PORT, LCD_E1_BIT
    bsf LCD_E2_PORT, LCD_E2_BIT
    bsf LCD_WR_PORT, LCD_WR_BIT
    bsf LCD_A0_PORT, LCD_A0_BIT
#endif

    goto $
    ; never return !
    return

lcd_test_io_off
    global lcd_test_io_off
    bcf LCD_DATA_0_PORT, LCD_DATA_0_BIT
    bcf LCD_DATA_1_PORT, LCD_DATA_1_BIT
    bcf LCD_DATA_2_PORT, LCD_DATA_2_BIT
    bcf LCD_DATA_3_PORT, LCD_DATA_3_BIT
    bcf LCD_DATA_4_PORT, LCD_DATA_4_BIT
    bcf LCD_DATA_5_PORT, LCD_DATA_5_BIT
    bcf LCD_DATA_6_PORT, LCD_DATA_6_BIT
    bcf LCD_DATA_7_PORT, LCD_DATA_7_BIT
    bcf LCD_E1_PORT, LCD_E1_BIT
    bcf LCD_E2_PORT, LCD_E2_BIT
    bcf LCD_WR_PORT, LCD_WR_BIT
    bcf LCD_A0_PORT, LCD_A0_BIT

    goto $
    ; never return !
    return

lcd_test_io_blink
    global lcd_test_io_blink
    bsf LCD_DATA_0_PORT, LCD_DATA_0_BIT
    bsf LCD_DATA_1_PORT, LCD_DATA_1_BIT
    bsf LCD_DATA_2_PORT, LCD_DATA_2_BIT
    bsf LCD_DATA_3_PORT, LCD_DATA_3_BIT
    bsf LCD_DATA_4_PORT, LCD_DATA_4_BIT
    bsf LCD_DATA_5_PORT, LCD_DATA_5_BIT
    bsf LCD_DATA_6_PORT, LCD_DATA_6_BIT
    bsf LCD_DATA_7_PORT, LCD_DATA_7_BIT
    bsf LCD_E1_PORT, LCD_E1_BIT
    bsf LCD_E2_PORT, LCD_E2_BIT
    bsf LCD_WR_PORT, LCD_WR_BIT
    bsf LCD_A0_PORT, LCD_A0_BIT

#ifdef LCD_DELAY
    movlw 0xFF
    call delay_wait
#endif

    bcf LCD_DATA_0_PORT, LCD_DATA_0_BIT
    bcf LCD_DATA_1_PORT, LCD_DATA_1_BIT
    bcf LCD_DATA_2_PORT, LCD_DATA_2_BIT
    bcf LCD_DATA_3_PORT, LCD_DATA_3_BIT
    bcf LCD_DATA_4_PORT, LCD_DATA_4_BIT
    bcf LCD_DATA_5_PORT, LCD_DATA_5_BIT
    bcf LCD_DATA_6_PORT, LCD_DATA_6_BIT
    bcf LCD_DATA_7_PORT, LCD_DATA_7_BIT
    bcf LCD_E1_PORT, LCD_E1_BIT
    bcf LCD_E2_PORT, LCD_E2_BIT
    bcf LCD_WR_PORT, LCD_WR_BIT
    bcf LCD_A0_PORT, LCD_A0_BIT

#ifdef LCD_DELAY
    movlw 0xFF
    call delay_wait
#endif

    goto lcd_test_io_blink
    ; never return !
    return


;;; locate and draw a string
;;; param1: x
;;; param2: y
;;; param3: addrl of null terminated string
;;; param4: addrh of null terminated string
;;; used variables: var3, var4, var5
lcd_loc_string
    global lcd_loc_string

    ;; store param1 and param2
    movf param1, W
    movwf var3
    movf param2, W
    movwf var4

    ;; *** Draw string
    ;; init position counter (in var5)
    banksel var5
    movlw 0
    movwf var5
lcd_loc_string_loop:
    ;; locate
    movf var3, W
    movwf param1
    movf var4, W
    movwf param2
    call lcd_locate
#if 0
    ;; start read_modify_write
    movlw LCD_READ_MODIFY_WRITE
    movwf param1
    bsf param2, LCD_COMMAND
    call lcd_write
#endif
    ;;  set addr to read
    movf var5, W
    addwf param3, W
    banksel EEADR
    movwf EEADR

    banksel param4
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
    banksel 0
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
    banksel param1
    movwf param1
    call lcd_char

    banksel 0
    incf var5, F
    incf var3, F
    goto lcd_loc_string_loop

#if 0
    ;; end of read modify write
    banksel 0
    bsf param2, LCD_COMMAND
    movlw LCD_END
    movwf param1
    call lcd_write
#endif
lcd_loc_string_end:
    banksel 0
#if 0
    lcd_send_cmd_1 LCD_END, 0
    lcd_send_cmd_2 LCD_END, 0
#endif
    return

;;; draw a string
;;; param3: addrl of null terminated string
;;; param4: addrh of null terminated string
;;; used variables: var5
lcd_string
    global lcd_string

    ;; *** Draw string
    ;; init position counter (in var5)
    banksel var5
    movlw 0
    movwf var5
lcd_string_loop:
#if 0
    ;; start read_modify_write
    movlw LCD_READ_MODIFY_WRITE
    movwf param1
    bsf param2, LCD_COMMAND
    call lcd_write
#endif
    ;;  set addr to read
    movf var5, W
    addwf param3, W
    banksel EEADR
    movwf EEADR

    banksel param4
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
    banksel 0
    ;; verify if last char
    banksel EEDAT
    movf EEDAT, W
    sublw 0
    btfsc STATUS, Z
    ;; It's 0 -> finished
    goto lcd_string_end
    ;; write read data in param1 and draw char
    banksel EEDAT
    movf EEDAT, W
    banksel param1
    movwf param1
    call lcd_char

    banksel 0
    incf var5, F
    goto lcd_string_loop

#if 0
    ;; end of read modify write
    banksel 0
    bsf param2, LCD_COMMAND
    movlw LCD_END
    movwf param1
    call lcd_write
#endif
lcd_string_end:
    banksel 0
#if 0
    lcd_send_cmd_1 LCD_END, 0
    lcd_send_cmd_2 LCD_END, 0
#endif
    return


;;; set the text position
;;; param1: x
;;; param2: y
;;; used variables: var1, var2
lcd_locate
    global lcd_locate
    ;; store param 2
    movf param2, W
    movwf var2

    ;; *** Set x position
    movlw LCD_WIDTH_TXT/2
    subwf param1, W

    ; if x is greater than LCD_WIDTH/2, goto lcd_locate_chip_2
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
    movlw LCD_CHAR_WIDTH_SHIFT
    movwf var1
lcd_locate_mult_x_loop:
    bcf STATUS, C
    rlf param1, F
    decfsz var1, F
    goto lcd_locate_mult_x_loop
    ;; Add 1 if chip 1, otherwise there would be a space between each chip
    btfsc param2, LCD_FIRST_CHIP
    incf param1, F

    movlw LCD_COLUMN_ADDRESS
    iorwf param1, F

    bsf param2, LCD_COMMAND
    call lcd_write

    ;; *** Set y position
    ;; lcd page 0
    movf var2, W
    iorlw LCD_SET_PAGE_ADDRESS
    movwf param1
    bsf param2, LCD_COMMAND
    call lcd_write
    return

;;; draw a char
;;; param1: is the character number
;;; used variables: var1
lcd_char:
    global lcd_char

    movlw FIRST_FONT_CHAR_NUM
    subwf param1, F

    ;;  set addr to read
    banksel EEADR
    movlw high font
    movwf EEADRH
    movlw low font
    movwf EEADR
    banksel 0
    ;; add offset of char (4 times the character position):
    ;; loop LCD_CHAR_WIDTH times
    movlw LCD_CHAR_WIDTH
    movwf var1
lcd_char_add_offset_loop:
    banksel param1
    bcf STATUS, C
    movf param1, W
    banksel EEADR
    addwf EEADR, F
    btfsc STATUS, C
    incf EEADRH, F
    banksel var1
    decfsz var1, F
    goto lcd_char_add_offset_loop

    banksel 0
#if 0
    ;; start read modify write
    movlw LCD_READ_MODIFY_WRITE
    movwf param1
    bsf param2, LCD_COMMAND
    call lcd_write
#endif
    ;; prepare loop var
    movlw LCD_CHAR_WIDTH
    movwf var1

lcd_char_loop:
    ;;  read  flash
    banksel EECON1
    bsf EECON1, EEPGD
    bsf EECON1, RD
    nop
    nop

    banksel 0

    ;; write data
    bcf param2, LCD_COMMAND
    banksel EEDAT
    ;; movlw FIRST_FONT_CHAR_NUM
    movf EEDAT, W
    banksel 0
    movwf param1
    call lcd_write

    banksel EEADR
    incf EEADR, F
    btfss STATUS, Z
    goto loop_char_end_loop
    movlw 0
    movwf EEADR
    incf EEADRH, F
loop_char_end_loop:
    banksel 0
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
    call lcd_write
    ;; end of read modify write
    bcf param2, LCD_FIRST_CHIP
    bsf param2, LCD_COMMAND
    movlw LCD_END
    movwf param1
    call lcd_write

#endif
    return
font:
#include <font.inc>
END

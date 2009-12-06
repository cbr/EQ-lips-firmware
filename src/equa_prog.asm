; -----------------------------------------------------------------------
#include <cpu.inc>


; -----------------------------------------------------------------------
; Configuration bits
;    __CONFIG _CONFIG1, _EXTRC_OSC_CLKOUT & _WDT_ON & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOR_ON & _IESO_ON & _FCMEN_ON & _LVP_ON & _DEBUG_OFF
    __CONFIG _CONFIG1, _INTOSCIO  & _WDT_OFF & _PWRTE_ON & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOR_ON & _IESO_ON & _FCMEN_ON & _LVP_OFF & _DEBUG_OFF
    __CONFIG _CONFIG2, _BOR21V & _WRT_OFF
;    __CONFIG _INTOSCIO & _WDT_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOR_ON & _IESO_ON & _FCMEN_ON

#include <global.inc>
#include <interrupt.inc>
#include <io.inc>
#include <lcd.inc>
#include <encoder.inc>
#include <delay.inc>
#include <std.inc>
#include <menu.inc>
#include <spi.inc>
#include <numpot.inc>
; -----------------------------------------------------------------------
; Variable declaration

; -----------------------------------------------------------------------
; Startup vector
STARTUP CODE 0x000
    nop                    ; necessary for debug with ICD2
    movlw   high start     ; load high order byte from start label
    movwf   PCLATH         ; initialiee PCLATH
    goto    start          ; start

; interrupt vector
INT_VECTOR CODE 0x004
    goto    interrupt      ; go to begining of interrupt code

; relocatable code
PROG CODE
interrupt:
    movwf   w_saved        ; save context
    swapf   STATUS,w
    movwf   status_saved
    movf    PCLATH,w       ; only necessary if using more than the first page
    movwf   pclath_saved
    clrf    PCLATH
    ;; Manage encode interrupt
    encoder_it


    movf    pclath_saved,w ; restore context
    movwf   PCLATH
    swapf   status_saved,w
    movwf   STATUS
    swapf   w_saved,f
    swapf   w_saved,w
    retfie

st_eqprog:
    dt "-= EQ_PROG =-", 0
st_de:
    dt "DE", 0

start:

    ; init clock
    BSF  STATUS,RP0 ;Bank 1
    BCF  STATUS,RP1 ;
    movlw 0x0F
    andwf OSCCON, 1
    ;movlw 0x70 ; 8 MHz
    movlw 0x30 ; 500kHz
    ;movlw 0x00 ; 31kHz
    iorwf OSCCON, 1
    BCF  STATUS,RP0 ;Bank 0
    BCF  STATUS,RP1 ;

    ; disable adc (necessary to use io)
    banksel ANSEL
    clrf ANSEL
    clrf ANSELH
    banksel 0

    ; init
    call io_configure
    call lcd_init
    call encoder_init
    call spi_init

    ; enable interrupt
    interrupt_enable

#if 1
#define INIT_VAL    0x7F
    NUMPOT_SET_ONE_VALUE 0x0, INIT_VAL
    NUMPOT_SET_ONE_VALUE 0x1, INIT_VAL
    NUMPOT_SET_ONE_VALUE 0x2, INIT_VAL
    NUMPOT_SET_ONE_VALUE 0x3, INIT_VAL
    NUMPOT_SET_ONE_VALUE 0x4, INIT_VAL
    NUMPOT_SET_ONE_VALUE 0x5, INIT_VAL
    NUMPOT_SET_ONE_VALUE 0x6, INIT_VAL
    NUMPOT_SET_ONE_VALUE 0x7, INIT_VAL
    NUMPOT_SET_ONE_VALUE 0x8, INIT_VAL
    NUMPOT_SET_ONE_VALUE 0x9, INIT_VAL
    NUMPOT_SET_ONE_VALUE 0xA, INIT_VAL
    NUMPOT_SET_ONE_VALUE 0xB, INIT_VAL
#if 0
    NUMPOT_SET_ONE_VALUE 0x0, 0x32
    NUMPOT_SET_ONE_VALUE 0x1, 0x32
    NUMPOT_SET_ONE_VALUE 0x2, 0x32
    NUMPOT_SET_ONE_VALUE 0x3, 0x4B
    NUMPOT_SET_ONE_VALUE 0x4, 0x7F
    NUMPOT_SET_ONE_VALUE 0x5, 0x64
    NUMPOT_SET_ONE_VALUE 0x6, 0x4B
    NUMPOT_SET_ONE_VALUE 0x7, 0x32
    NUMPOT_SET_ONE_VALUE 0x8, 0x32
    NUMPOT_SET_ONE_VALUE 0x9, 0x32
#endif
    NUMPOT_SET_ONE_VALUE 0xA, 0xFF
    NUMPOT_SET_ONE_VALUE 0xB, 0xFF

;; spi_test:
    call numpot_send_all

    ;; goto spi_test


#endif


#if 0
spi_test:
    movlw 0x13
    movwf param1
    movlw 0xFF
    movwf param2
    call spi_send

    goto spi_test

    movlw 0xFF
    movwf param3


loop_spi_inc
    movlw 0x13
    movwf param1
    movf param3, W
    movwf param2

    call spi_send

    movlw 0x70
    call delay_wait

    incfsz param3
    goto loop_spi_inc

loop_spi_dec
    movlw 0x13
    movwf param1
    movf param3, W
    movwf param2

    call spi_send

    movlw 0x70
    call delay_wait

    decfsz param3
    goto loop_spi_dec

    goto loop_spi_inc

#endif


#if 1
    ;; *** TEST MENU ***
    menu_start
    menu_entry st_eqprog
    ;; menu_entry st_de
    menu_entry st_eqprog
    menu_entry st_de
    menu_end
    goto $
    ;; movlw 0
    ;; movwf param1
    ;; movlw 0
    ;; movwf param2
    ;; movlw LCD_WIDTH
    ;; movwf param3
    ;; movlw 9
    ;; movwf param4
    ;; bsf param5, LCD_XOR
    ;; call lcd_rectangle
#endif

#if 0
    ;; *** TEST LCD ***
    ; draw rectangle
    movlw 1
    movwf param1
    movlw 1
    movwf param2
    movlw (LCD_WIDTH / 2) - 2
    movwf param3
    movlw LCD_HEIGH - 2
    movwf param4
    bsf param5, LCD_SET_PIXEL
    call lcd_rectangle
    ; draw a white plot on the rectangle
    movlw 5
    movwf param1
    movlw 5
    movwf param2
    bcf param3, LCD_SET_PIXEL
    call lcd_plot
    goto $
#endif

#if 0
    ;; *** TEST FONT PRINTING ***
    movlw 0x08
    movwf param1
    movlw 0
    movwf param2


    movlw low st_eqprog
    movwf param3
    movlw high st_eqprog
    movwf param4

    call lcd_loc_string

    ;; Print 'A' then 'B'
    movlw 0x05
    movwf param1
    movlw 1
    movwf param2
    nop
    call lcd_locate
    movlw 'A'
    movwf param1
    call lcd_char
    movlw 'B'
    movwf param1
    call lcd_char

    ;; Print 'C' then "DE"
    movlw 0x15
    movwf param1
    movlw 2
    movwf param2
    call lcd_locate
    movlw 'C'
    movwf param1
    call lcd_char
    movlw low st_de
    movwf param1
    movlw high st_de
    movwf param2
    call lcd_string

    ;; Print int
    movlw 0x02
    movwf param1
    movlw 0x03
    movwf param2
    call lcd_locate

    movlw 0xF0                  ; = 240
    movwf param1
    movlw 0x00
    movwf param2
    call lcd_int

    movlw 0x12
    movwf param1
    movlw 0x03
    movwf param2
    call lcd_locate

    movlw 0x7C                  ; = 1.24
    movwf param1
    movlw 0x02
    movwf param2
    call lcd_int

#endif

#if 0
    ;; *** DRAW RECT WITH ENCODER ***
loop_draw:

    movf encoder_last_value, W
    subwf encoder_value, W
    btfsc STATUS, Z
    goto loop_draw

    movlw 0
    movwf param1
    movlw 0
    movwf param2
    movlw 10
    movwf param3
    movlw LCD_HEIGH
    movwf param4
    bcf param5, LCD_SET_PIXEL
    call lcd_rectangle

    movlw 0
    movwf param1
    movlw 0
    movwf param2
    movlw 10
    movwf param3
    movf encoder_value, W
    movwf encoder_last_value
    movwf param4
#if 0
    bcf STATUS, C
    rrf param4, F
    bcf STATUS, C
    rrf param4, F
    bcf STATUS, C
    rrf param4, F
#endif
    bsf param5, LCD_SET_PIXEL
    call lcd_rectangle

    goto loop_draw
#endif

    goto    $              ; infinite loop

END

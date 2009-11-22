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
#include <menu.inc>
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

    ; enable interrupt
    interrupt_enable
#if 0
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

#if 1
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

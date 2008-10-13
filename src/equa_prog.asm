; -----------------------------------------------------------------------
; Fichier source modèle généré par Piklab
#include <cpu.inc>


; -----------------------------------------------------------------------
; Bits de configuration: adapté à votre dispositif et à vos besoins
;    __CONFIG _CONFIG1, _EXTRC_OSC_CLKOUT & _WDT_ON & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOR_ON & _IESO_ON & _FCMEN_ON & _LVP_ON & _DEBUG_OFF
    __CONFIG _CONFIG1, _INTOSCIO  & _WDT_OFF & _PWRTE_ON & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOR_ON & _IESO_ON & _FCMEN_ON & _LVP_OFF & _DEBUG_OFF
    __CONFIG _CONFIG2, _BOR21V & _WRT_OFF
;    __CONFIG _INTOSCIO & _WDT_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOR_ON & _IESO_ON & _FCMEN_ON

#include <global.inc>
#include <io.inc>
#include <lcd.inc>
#include <encoder.inc>
#include <delay.inc>
; -----------------------------------------------------------------------
; Déclaration des variables

; -----------------------------------------------------------------------
; vecteur de redémarrage
STARTUP CODE 0x000
    nop                    ; nécessaire pour le débogage avec l'ICD2
    movlw   high start     ; charge l'octet supérieur de l'étiquette « start »
    movwf   PCLATH         ; initialise PCLATH
    goto    start          ; va au début du code principal

; vecteur d'interruption
INT_VECTOR CODE 0x004
    goto    interrupt      ; va au début du code d'interruption

; code relogeable
PROG CODE
interrupt
    movwf   w_saved        ; sauvegarde du contexte
    swapf   STATUS,w
    movwf   status_saved
    movf    PCLATH,w       ; nécessaire seulement si on utilise plus que la première page
    movwf   pclath_saved
    clrf    PCLATH
    ; << insérer le code d'interruption >>
    encoder_it


    movf    pclath_saved,w ; restauration du contexte
    movwf   PCLATH
    swapf   status_saved,w
    movwf   STATUS
    swapf   w_saved,f
    swapf   w_saved,w
    retfie

start

    ; init clock
    BSF  STATUS,RP0 ;Bank 1
    BCF  STATUS,RP1 ;
    movlw 0x0F
    andwf OSCCON, 1
    movlw 0x70 ; 8 MHz
    ;movlw 0x30 ; 500kHz
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

#if 0
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
    movlw 1
    movwf param1
    call lcd_char

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
    movf encoder_value, 0
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


    goto    $              ; boucle indéfiniment

END

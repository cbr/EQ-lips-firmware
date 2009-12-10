;;; Manage dialog screen for eqalizer editing

#define EDIT_EQ_M

#include <cpu.inc>
#include <global.inc>
#include <std.inc>
#include <lcd.inc>
#include <menu.inc>

    UDATA
edit_eq_tmp      RES 1


; relocatable code
PROG CODE
edit_eq_show:
    global edit_eq_show
    ;; Erase screen
    call lcd_clear

    ;; position
    movlw (0x5*0 + 0x3E)
    movwf param1
    ;; value
    movlw 0xFF
    movwf param2
    call menu_draw_eq_band

    ;; position
    movlw (0x5*1 + 0x3E)
    movwf param1
    ;; value
    movlw 0x89
    movwf param2
    call menu_draw_eq_band

    ;; position
    movlw (0x5*2 + 0x3E)
    movwf param1
    ;; value
    movlw 0x81
    movwf param2
    call menu_draw_eq_band

    ;; position
    movlw (0x5*3 + 0x3E)
    movwf param1
    ;; value
    movlw 0x80
    movwf param2
    call menu_draw_eq_band

    ;; position
    movlw (0x5*4 + 0x3E)
    movwf param1
    ;; value
    movlw 0x7F
    movwf param2
    call menu_draw_eq_band

    ;; position
    movlw (0x5*5 + 0x3E)
    movwf param1
    ;; value
    movlw 0x77
    movwf param2
    call menu_draw_eq_band

    ;; position
    movlw (0x5*6 + 0x3E)
    movwf param1
    ;; value
    movlw 0x00
    movwf param2
    call menu_draw_eq_band

    ;; goto $
    ;; Draw eq
END

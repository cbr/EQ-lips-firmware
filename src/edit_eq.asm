;;; Manage dialog screen for eqalizer editing

#define EDIT_EQ_M

#include <cpu.inc>
#include <global.inc>
#include <std.inc>
#include <lcd.inc>
#include <menu.inc>
#include <encoder.inc>
#include <interrupt.inc>
#include <numpot.inc>

    UDATA
edit_eq_tmp      RES 1


; relocatable code
PROG CODE
st_toto:
    dt "TOTO", 0
edit_eq_show:
    global edit_eq_show
#if 1
    menu_start
st_eqprog:
    menu_entry st_toto, 0
    menu_eq (0x5*0 + 0x3D), potvalues, numpot_send_all
    menu_eq (0x5*1 + 0x3D), potvalues+1, numpot_send_all
    menu_eq (0x5*2 + 0x3D), potvalues+2, numpot_send_all
    menu_eq (0x5*3 + 0x3D), potvalues+3, numpot_send_all
    menu_eq (0x5*4 + 0x3D), potvalues+4, numpot_send_all
    menu_eq (0x5*5 + 0x3D), potvalues+5, numpot_send_all
    menu_eq (0x5*6 + 0x3D), potvalues+6, numpot_send_all
    menu_eq (0x5*7 + 0x3D), potvalues+7, numpot_send_all
    menu_eq (0x5*8 + 0x3D), potvalues+8, numpot_send_all
    menu_eq (0x5*9 + 0x3D), potvalues+9, numpot_send_all
    menu_eq (0x5*0xB + 0x3D), potvalues+0xA, numpot_send_all
    menu_end

#else
    ;; Erase screen
    call_other_page lcd_clear

    ;; position
    movlw (0x5*0 + 0x3D)
    movwf param1
    ;; value
    movlw 0xFF
    movwf param2
    call_other_page menu_draw_eq_band

    ;; position
    movlw (0x5*1 + 0x3D)
    movwf param1
    ;; value
    movlw 0x89
    movwf param2
    call_other_page menu_draw_eq_band

    ;; position
    movlw (0x5*2 + 0x3D)
    movwf param1
    ;; value
    movlw 0x81
    movwf param2
    call_other_page menu_draw_eq_band

    ;; position
    movlw (0x5*3 + 0x3D)
    movwf param1
    ;; value
    movlw 0x80
    movwf param2
    call_other_page menu_draw_eq_band

    ;; position
    movlw (0x5*4 + 0x3D)
    movwf param1
    ;; value
    movlw 0x7F
    movwf param2
    call_other_page menu_draw_eq_band

    ;; position
    movlw (0x5*5 + 0x3D)
    movwf param1
    ;; value
    movlw 0x77
    movwf param2
    call_other_page menu_draw_eq_band

    ;; position
    movlw (0x5*6 + 0x3D)
    movwf param1
    ;; value
    movlw 0x00
    movwf param2
    call_other_page menu_draw_eq_band
#endif
    ;; goto $
    ;; Draw eq
END

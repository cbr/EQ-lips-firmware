#define MENU_M

#include <cpu.inc>
#include <lcd.inc>
#include <std.inc>
#include <global.inc>
#include <menu.inc>
#include <encoder.inc>

#define MENU_BUTTON_NB_DRAW_SELECT  0x8

COMMON_VAR UDATA
menu_state              RES 1
    global menu_state
menu_state_asked_action        RES 1
    global menu_state_asked_action
menu_select_value       RES 1
    global menu_select_value
;;; relocatable code
COMMON CODE

;;; Configure encoder and memorize current value
;;; in order to manage encoder change for select sub sate
;;; param1: current_value
;;; param2: value_min
;;; param3: value_max
menu_selection_encoder_configure:
    global menu_selection_encoder_configure
    ;; Set encoder value
    call_other_page encoder_set_value
    ;; Memorize select value
    movf param1, W
    banksel menu_select_value
    movwf menu_select_value

    return

END

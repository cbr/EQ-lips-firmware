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

;;;
;;; This macro add a menu button into a dialog screen
;;; id: uniq id of menu_entry element
;;; string: label of the menu button.
;;; pos: y position of menu button
;;; on_select_function: function called on selection
;;; Changed registers: param1, param2, param3, param4
;;;
menu_button macro id, string, pos, on_select_function
    menu_button_common id, string, pos, on_select_function, 0, 0
    endm

;;;
;;; This macro add a menu button into a dialog screen. This variant
;;; goto the specified label on selection
;;; id: uniq id of menu_entry element
;;; string: label of the menu button
;;; pos: y position of menu button
;;; on_select_function: function 'gotoed' on selecttion
;;; Changed registers: param1, param2, param3, param4
;;;
menu_button_goto macro id, string, pos, on_select_function
    menu_button_common id, string, pos, on_select_function, 1, 0
    endm

;;;
;;; This macro add a hidden menu button into a dialog screen.
;;; This button is not drawn and does not get focus. It can only
;;; by activated with the help of macro menu_select_specific_entry.
;;; id: uniq id of menu_entry element
;;; on_select_function: function called on selection
;;; Changed registers: param1, param2, param3, param4
;;;
menu_button_hidden macro id, on_select_function
    menu_button_common id, 0, 0, on_select_function, 0, 1
    endm

;;;
;;; This macro add a hidden menu button into a dialog screen.
;;; This button is not drawn and does not get focus. It can only
;;; by activated with the help of macro menu_select_specific_entry.
;;; This variant goto the specified label on selection
;;; id: uniq id of menu_entry element
;;; on_select_function: function 'gotoed' on selecttion
;;; Changed registers: param1, param2, param3, param4
;;;
menu_button_hidden_goto macro id, on_select_function
    menu_button_common id, 0, 0, on_select_function, 1, 1
    endm

;;;
;;; This macro add a menu button into a dialog screen
;;; id: uniq id of menu_entry element
;;; string: label of the menu button
;;; pos: y position of menu button
;;; on_select_function: label used on selection
;;; use_goto: if 1, on_select_function is used as a goto, otherwise it is called
;;; hidden: if 0 the button is not hidden, otherwise it is hidden and does not get the focus
;;; Changed registers: param1, param2, param3, param4
;;;
menu_button_common macro id, string, pos, on_select_function, use_goto, hidden
    local menu_button_init_or_refresh
    local menu_button_undef
    local menu_button_focus
    local menu_button_unfocus
    local menu_button_select
    local menu_button_unselect

    menu_event_dispatch id, menu_button_init_or_refresh, menu_button_focus, menu_button_unfocus, menu_button_select, menu_button_unselect, UNUSED_PARAM, UNUSED_PARAM, menu_button_init_or_refresh
    goto menu_button_undef

menu_button_init_or_refresh:
    if hidden == 0
    ;; Print string
    movlw MENU_STRING_POS_X
    movwf param1
    movlw pos
    movwf param2


    movlw low string
    movwf param3
    movlw high string
    movwf param4

    call_other_page lcd_loc_string
    endif
    goto menu_button_undef

    if hidden == 0
#ifdef SIMPLE_FOCUS
menu_button_unfocus:
    clrf param1
    movlw pos
    movwf param2
    call_other_page lcd_locate
    movlw MENU_UNFOCUS_CHAR
    movwf param1
    call_other_page lcd_char
    goto menu_button_undef
menu_button_focus:
    ;; Current button
    clrf param1
    movlw pos
    movwf param2
    call_other_page lcd_locate
    movlw MENU_FOCUS_CHAR
    movwf param1
    call_other_page lcd_char
    goto menu_button_undef
#else
menu_button_unfocus:
menu_button_focus:
    ;; draw the focus rectangle with XOR
    ;; (So, the same operation can focus and also unfocus)
    ;; Current button
    clrf param1
    movlw pos
    movwf param2
    lshift_f param2, LCD_CHAR_HEIGH_SHIFT
    movlw LCD_WIDTH
    movwf param3
    movf param2, W
    movwf param4
    movlw LCD_CHAR_HEIGH
    movwf param4
    bsf param5, LCD_XOR
    call_other_page lcd_rectangle
#endif
    else
menu_button_unfocus:
menu_button_focus:
    endif
    goto menu_button_undef

menu_button_select:
    if hidden == 0
    movlw pos
    movwf param1
    call_other_page menu_button_select_func
    endif
    menu_leave_selection
    goto menu_button_undef

menu_button_unselect:
    ;; call on event function
    if (use_goto == 1)
        goto_other_page on_select_function
    else
        call_other_page on_select_function
    endif
    goto menu_button_undef

menu_button_undef:
    if hidden == 0
    MENU_NEW_ENTRY_WITH_FOCUS
    else
    MENU_NEW_ENTRY_WITHOUT_FOCUS
    endif
    endm

#ifndef MENU_BUTTON_M
    extern menu_button_select_func
#endif

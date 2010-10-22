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
;;; DEFINES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
#define MENU_EDIT_NO_PRINT_VAL      0xFF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; MACROS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;
;;; This macro add a menu edit into a dialog screen.
;;; The value managed by edit is printed just after the string.
;;; id: uniq id of menu_entry element
;;; string: label of the menu edit
;;; pos_y: y position of menu edit
;;; Changed registers: param1, param2, param3, param4
;;;
menu_edit macro id, string, pos_x, pos_y, min_value, max_value, value_addr, value_format, on_value_change_func, on_valid_value_func
    menu_edit_comon id, string, pos_x, pos_y, min_value, max_value, value_addr, value_format, on_value_change_func, on_valid_value_func, 1
    endm

;;;
;;; This macro add a menu edit into a dialog screen.
;;; The value managed by edit is not printed.
;;; id: uniq id of menu_entry element
;;; string: label of the menu edit
;;; pos_y: y position of menu edit
;;; Changed registers: param1, param2, param3, param4
;;;
menu_edit_no_show macro id, string, pos_x, pos_y, min_value, max_value, value_addr, value_format, on_value_change_func, on_valid_value_func
    menu_edit_comon id, string, pos_x, pos_y, min_value, max_value, value_addr, value_format, on_value_change_func, on_valid_value_func, 0
    endm

;;;
;;; This macro add a menu edit into a dialog screen.
;;; Simplier alias macro can be used instead: menu_edit, menu_edit_no_show
;;; id: uniq id of menu_entry element
;;; string: label of the menu edit
;;; pos_y: y position of menu edit
;;; Changed registers: param1, param2, param3, param4
;;;
menu_edit_comon macro id, string, pos_x, pos_y, min_value, max_value, value_addr, value_format, on_value_change_func, on_valid_value_func, print_value
    local menu_edit_init_or_refresh
    local menu_edit_undef
    local menu_edit_focus
    local menu_edit_unfocus
    local menu_edit_select
    local menu_edit_unselect
    local menu_edit_select_switch
    local menu_edit_select_value_change
    local menu_edit_select_unselect_draw
    menu_event_dispatch id, menu_edit_init_or_refresh, menu_edit_focus, menu_edit_unfocus, menu_edit_select, menu_edit_unselect, menu_edit_select_value_change, menu_edit_select_switch, menu_edit_init_or_refresh
    goto menu_edit_undef

menu_edit_init_or_refresh:
    ;; Print string
    movlw pos_x
    movwf param1
    movlw pos_y
    movwf param2
    movlw low string
    movwf param3
    movlw high string
    movwf param4
    call_other_page lcd_loc_string
#if print_value == 1
    ;; Print value
    movlw value_addr
    movwf FSR
    bankisel value_addr
    movf INDF, W
    movwf param1
    movlw value_format
    movwf param2
    call_other_page lcd_int
    goto menu_edit_undef
#endif

menu_edit_unfocus:
    movlw pos_x
    movwf param1
    decf param1, F
    movlw pos_y
    movwf param2
    call_other_page lcd_locate
    movlw MENU_UNFOCUS_CHAR
    movwf param1
    call_other_page lcd_char
    goto menu_edit_undef

menu_edit_focus:
    ;; Current edit
    movlw pos_x
    movwf param1
    decf param1, F
    movlw pos_y
    movwf param2
    call_other_page lcd_locate
    movlw MENU_FOCUS_CHAR
    movwf param1
    call_other_page lcd_char
    goto menu_edit_undef

menu_edit_select:
    ;; configure encoder
    banksel value_addr
    movf value_addr, W
    movwf param1
    movlw min_value
    movwf param2
    movlw low max_value
    movwf param3
    movlw 1
    movwf param4
    call_other_page menu_selection_encoder_configure
    ;; draw selection rectangle: the code is shared with unselect event, so
    ;; continue with select/unselect drawing part
    goto menu_edit_select_unselect_draw

menu_edit_unselect:

menu_edit_select_unselect_draw:
    ;; calculate size of string
    movlw low string
    movwf param1
    movlw high string
    movwf param2
    call_other_page std_strlen
    ;; store in param1
    movwf param3

    ;; draw selection rectangle
    movlw pos_x
    movwf param1
    movlw pos_y
    movwf param2
    call_other_page menu_edit_draw_select
    goto menu_edit_undef

menu_edit_select_switch:
    ;; Call value valid function callback
#if on_valid_value_func == UNUSED_PARAM
#else
    call_other_page on_valid_value_func
#endif
    menu_leave_selection
    goto menu_edit_undef

menu_edit_select_value_change:
    movlw low string
    movwf param1
    movlw high string
    movwf param2
    movlw pos_x
    movwf param3
#if print_value == 1
    movlw pos_y
#else
    movlw MENU_EDIT_NO_PRINT_VAL
#endif
    movwf param4
    bankisel value_addr
    movlw value_addr
    movwf param5
    movlw value_format
    movwf param6
    call_other_page menu_edit_manage_select_value_change
#if on_value_change_func == UNUSED_PARAM
#else
    call_other_page on_value_change_func
#endif
    goto menu_edit_undef

menu_edit_undef:
    MENU_NEW_ENTRY_WITH_FOCUS
    endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; PUBLIC DECLARATIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#ifndef MENU_EDIT_M
    extern menu_edit_draw_select
    extern menu_edit_manage_select_value_change
#endif

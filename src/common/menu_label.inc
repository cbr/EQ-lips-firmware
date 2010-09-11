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
;;; This macro add label representing int variable.
;;; pos: y position of menu edit
;;; value_addr: variable to be printed
;;; Changed registers: param1, param2, param3, param4
;;;
menu_label_int macro pos, value_addr
    local menu_label_init_or_refresh
    local menu_label_undef

    menu_event_dispatch menu_label_init_or_refresh, UNUSED_PARAM, UNUSED_PARAM, UNUSED_PARAM, UNUSED_PARAM, UNUSED_PARAM, UNUSED_PARAM, menu_label_init_or_refresh
    goto menu_label_undef

menu_label_init_or_refresh:
    ;; Print string
    movlw MENU_STRING_POS_X
    movwf param1
    movlw pos
    movwf param2
    call_other_page lcd_locate
    ;; Print value
    movlw value_addr
    movwf FSR
    bankisel value_addr
    movf INDF, W
    movwf param1
    clrf param2
    call_other_page lcd_int
    goto menu_label_undef


menu_label_undef:
    MENU_NEW_ENTRY_WITHOUT_FOCUS
    endm

#ifndef MENU_LABEL_M
#endif

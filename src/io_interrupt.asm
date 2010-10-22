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

#define IO_INTERRUPT_M

PROG_VAR_1 UDATA

;;; Last filtered input register
reg_input_last_value RES 1
    global reg_input_last_value
;;; Current filtered input register
reg_input_current_value RES 1
    global reg_input_current_value
;;; Tell if interrupt has been entered.
reg_input_it_entered RES 1
    global reg_input_it_entered

;;; relocatable code
EQ_PROG_1 CODE

;;;
;;; Initialize module
;;;
io_interrupt_init:
    global io_interrupt_init
    banksel reg_input_last_value
    movlw 0xFF
    movwf reg_input_last_value
    movwf reg_input_current_value
    return
END

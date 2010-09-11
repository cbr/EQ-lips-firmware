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

#define IO_FILTER_NB_STABLE_STATE     0x80

io_interrupt macro
#ifdef RABIF
    btfss INTCON, RABIF
#else
    btfss INTCON, RBIF
#endif
    goto no_io_it

    ;; Memorize previous register filtered value
    banksel reg_input_current_value
    movf reg_input_current_value, W
    banksel reg_input_last_value
    movwf reg_input_last_value

    ;; Filter value of register (put into reg_input_current_value)
    io_filter ENC_A_PORT, ENCODER_MASK | (1 << DOWN_SW_BIT) | (1 << UP_SW_BIT), IO_FILTER_NB_STABLE_STATE, reg_input_current_value

    ;; Check if some changes have occured:
    ;; using XOR only bit which have change are equal to 1
    ;; -> put this result in interrupt_var_1
    banksel reg_input_current_value
    movf reg_input_current_value, W
    banksel reg_input_last_value
    xorwf reg_input_last_value, W
    movwf interrupt_var_1

    encoder_it reg_input_current_value, interrupt_var_1
ack_it_io:
    ; ack it
    banksel ENC_A_PORT
    movf ENC_A_PORT, F
#ifdef RABIF
    bcf INTCON, RABIF
#else
    bcf INTCON, RBIF
#endif
no_io_it:

    endm


#ifndef IO_INTERRUPT_M
    ;; Variables
    extern reg_input_last_value
    extern reg_input_current_value
    ;; Functions
    extern io_interrupt_init
#endif

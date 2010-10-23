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
;;; MODULE DESCRIPTION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Driver for rotary numeric encoder ALPS EC12E24
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


#define SPI_M

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; INCLUDES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
#include <cpu.inc>
#include <global.inc>
#include <io.inc>
#include <delay.inc>
#include <interrupt.inc>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; DEFINES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
#define ENCODER_DEFAULT_VALUE 0x9
#define ENCODER_DEFAULT_MIN_VALUE 0x00
#define ENCODER_DEFAULT_MAX_VALUE 0x15

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; VARIABLES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
COMMON_VAR UDATA
encoder_min_value RES 1 ; encoder minimum value
    global encoder_min_value
encoder_max_value RES 1 ; encoder maximum value
    global encoder_max_value
encoder_loopback RES 1 ; encoder loopback
    global encoder_loopback

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; CODE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
COMMON CODE

;;;
;;; init encoder
;;;   no param
encoder_init:
    global encoder_init

    ;; configure ENC_A and ENC_B
    ;; Activate interrupt for ENC_A
    banksel IOCB
    bsf IOCB, ENC_A_BIT
    ;; Activate interrupt for ENC_SW
    bsf IOCB, ENC_SW_BIT
    ;; Activate interrupt for PORTA/PORTB change
    banksel 0
#ifdef RABIE
    bsf INTCON, RABIE
#else
    bsf INTCON, RBIE
#endif
    ;; init encoder_sw counter
    clrf encoder_sw
    ;; Set default encoder values
    movlw ENCODER_DEFAULT_VALUE
    movwf encoder_value
    movlw ENCODER_DEFAULT_MIN_VALUE
    banksel encoder_min_value
    movwf encoder_min_value
    movlw ENCODER_DEFAULT_MAX_VALUE
    banksel encoder_max_value
    movwf encoder_max_value
    banksel encoder_loopback
    clrf encoder_loopback
    banksel 0

    return


;;;
;;; param1: current_value
;;; param2: value_min
;;; param3: value_max
;;; param4: loopback (0=no, other=yes)
encoder_set_value:
    global encoder_set_value
    interrupt_disable
    movf param1, W
    movwf encoder_value
    movf param2, W
    banksel encoder_min_value
    movwf encoder_min_value
    movf param3, W
    banksel encoder_max_value
    movwf encoder_max_value
    movf param4, W
    banksel encoder_loopback
    movwf encoder_loopback
    interrupt_enable
    banksel 0
    return

END

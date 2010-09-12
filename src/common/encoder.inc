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

#define ENCODER_MASK                (1 << ENC_A_BIT | 1 << ENC_B_BIT | 1 << ENC_SW_BIT)

    extern encoder_min_value
    extern encoder_max_value
    extern encoder_loopback

encoder_it macro reg_current_value, reg_changed_bit

#if (ENC_A_PORT != ENC_B_PORT)
#error config_error
#endif

#if (ENC_SW_PORT != ENC_B_PORT)
#error config_error
#endif

    ;; Check encoder switch
encoder_switch_check:
    btfss reg_changed_bit, ENC_SW_BIT
    ;; The bit has not changed
    goto encoder_switch_check_end
    ;; The bit has changed, check if it has been pressed
    banksel reg_current_value
    btfss reg_current_value, ENC_SW_BIT
    incf encoder_sw, F
encoder_switch_check_end:

    ;; Check if encoder rotation need to be reevaluated
    btfss reg_changed_bit, ENC_A_BIT
    ;; The bit has not changed
    goto encoder_it_end
    ;; The bit has changed, check its new state
    btfsc reg_current_value, ENC_A_BIT
    goto encoder_it_end

    ; test enc_b
    btfss reg_current_value, ENC_B_BIT
    goto encoder_rotate_ccw
encoder_rotate_cw:
    ;; Test if not already max value
    movf encoder_value, W
    banksel encoder_max_value
    subwf encoder_max_value, W
    btfsc STATUS, Z
    ;; This is max value, check if loopback is needed
    goto encoder_loopback_min_check
    ;; Not max value
    incf encoder_value, F
    goto encoder_it_end
encoder_rotate_ccw:
    ;; Test if not already min value
    movf encoder_value, W
    banksel encoder_min_value
    subwf encoder_min_value, W
    btfsc STATUS, Z
    ;; This is min value, check if loopback is needed
    goto encoder_loopback_max_check
    ;; Not min value
    decf encoder_value, F
    goto encoder_it_end
encoder_loopback_min_check:
    ;; Check if loopback is activated
    banksel encoder_loopback
    movf encoder_loopback, W
    btfsc STATUS, Z
    ;; Loopback is not activated
    goto encoder_it_end
    ;; Loopback is activated
    banksel encoder_min_value
    movf encoder_min_value, W
    movwf encoder_value
    goto encoder_it_end
encoder_loopback_max_check:
    ;; Check if loopback is activated
    banksel encoder_loopback
    movf encoder_loopback, W
    btfsc STATUS, Z
    ;; Loopback is not activated
    goto encoder_it_end
    ;; Loopback is activated
    banksel encoder_max_value
    movf encoder_max_value, W
    movwf encoder_value

encoder_it_end:
    endm

encoder_set_value macro current_value, value_min, value_max, loopback
    interrupt_disable
    movlw current_value
    movwf encoder_value
    movlw value_min
    banksel encoder_min_value
    movwf encoder_min_value
    movlw value_max
    banksel encoder_max_value
    movwf encoder_max_value
    movlw loopback
    banksel encoder_loopback
    movwf encoder_loopback
    interrupt_enable
    banksel 0
    endm

;;; Reinitialize encoder switch counter
encoder_ack_sw macro
    clrf encoder_sw
    endm

#ifndef ENCODER_M
    ; Functions
    extern encoder_init
    extern encoder_set_value
#endif



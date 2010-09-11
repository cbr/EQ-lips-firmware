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

#define IO_M
#include <cpu.inc>
#include <io.inc>

; relocatable code
COMMON CODE

    ; configure ios
io_configure:
    global io_configure

    banksel PORTA

    CLRF PORTA      ;Init PORTA
    CLRF PORTB      ;Init PORTB
    CLRF PORTC      ;Init PORTC

    banksel TRISA

    ;; Outputs
    bcf LCD_E1_TRIS, LCD_E1_BIT
    bcf LCD_E2_TRIS, LCD_E2_BIT
    bcf LCD_WR_TRIS, LCD_WR_BIT
    bcf LCD_A0_TRIS, LCD_A0_BIT
    bcf SPI_CS_TRIS, SPI_CS_BIT

    ;; Inputs
    bsf ENC_A_TRIS, ENC_A_BIT
    bsf ENC_B_TRIS, ENC_B_BIT
    bsf ENC_SW_TRIS, ENC_SW_BIT
    bsf DOWN_SW_TRIS, DOWN_SW_BIT
    bsf UP_SW_TRIS, UP_SW_BIT

    banksel WPUB
    bsf WPUB, DOWN_SW_BIT
    bsf WPUB, UP_SW_BIT
    banksel 0
    return

;;; Configure LCD IO data as output
io_config_lcd_data_output:
    global io_config_lcd_data_output
#ifdef LCD_ALL_BIT_IN_SAME_REG
    banksel LCD_DATA_TRIS
    clrf LCD_DATA_TRIS
#else
    ;; All TRIS are one the same bank, so we
    ;; just select the first one
    banksel LCD_DATA_0_TRIS
    bcf LCD_DATA_0_TRIS, LCD_DATA_0_BIT
    bcf LCD_DATA_1_TRIS, LCD_DATA_1_BIT
    bcf LCD_DATA_2_TRIS, LCD_DATA_2_BIT
    bcf LCD_DATA_3_TRIS, LCD_DATA_3_BIT
    bcf LCD_DATA_4_TRIS, LCD_DATA_4_BIT
    bcf LCD_DATA_5_TRIS, LCD_DATA_5_BIT
    bcf LCD_DATA_6_TRIS, LCD_DATA_6_BIT
    bcf LCD_DATA_7_TRIS, LCD_DATA_7_BIT
#endif
    banksel 0
    return

;;; Configure LCD IO data as input
io_config_lcd_data_input:
    global io_config_lcd_data_input
#ifdef LCD_ALL_BIT_IN_SAME_REG
    banksel LCD_DATA_TRIS
    movlw 0xFF
    movwf LCD_DATA_TRIS
#else
    ;; All TRIS are one the same bank, so we
    ;; just select the first one
    banksel LCD_DATA_0_TRIS
    bsf LCD_DATA_0_TRIS, LCD_DATA_0_BIT
    bsf LCD_DATA_1_TRIS, LCD_DATA_1_BIT
    bsf LCD_DATA_2_TRIS, LCD_DATA_2_BIT
    bsf LCD_DATA_3_TRIS, LCD_DATA_3_BIT
    bsf LCD_DATA_4_TRIS, LCD_DATA_4_BIT
    bsf LCD_DATA_5_TRIS, LCD_DATA_5_BIT
    bsf LCD_DATA_6_TRIS, LCD_DATA_6_BIT
    bsf LCD_DATA_7_TRIS, LCD_DATA_7_BIT
#endif
    banksel 0
    return



END
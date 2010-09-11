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

; Driver for SPI controller of PIC16F690

#define SPI_M

#include <cpu.inc>
#include <global.inc>
#include <io.inc>
#include <delay.inc>
#include <spi.inc>

COMMON CODE

; init spi
;   no param
spi_init:
    global spi_init
    ;; unset CS
    banksel SPI_CS_PORT
    bsf SPI_CS_PORT, SPI_CS_BIT

    ;; Configure spi
    banksel SSPSTAT
    movlw (1 << SMP) | (1 << CKE)
    movwf SSPSTAT

    ;;  Configure SPI pins
    banksel SPI_SDO_TRIS
    bcf SPI_SDO_TRIS, SPI_SDO_BIT
    banksel SPI_SCL_TRIS
    bcf SPI_SCL_TRIS, SPI_SCL_BIT


    ;; Activate SPI
    banksel SSPCON
    movlw (1 << SSPEN)
    movwf SSPCON
    banksel 0
    return




END

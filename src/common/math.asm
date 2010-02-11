#define MATH_M

#include <cpu.inc>
#include <global.inc>
#include <std.inc>
#include <math.inc>

#define MSB         7
#define LSB         0
#define _C      STATUS,0
#define _Z      STATUS,2
;;; bit4 = not-a-number exception flag
#define NAN     4

    UDATA
var1       RES 1
;;; save location for sign in MSB
SIGN       RES 1

TEMPB3     RES 1
;;; temporary storage
TEMP       RES 1
;;; binary operation arguments
AARGB1     RES 1
AARGB0     RES 1
BARGB1     RES 1
BARGB0     RES 1

;;; Less significant byte of remainder
REMB1      RES 1
;;; Lost significant byte of remainder
REMB0      RES 1
;;; loop counter
LOOPCOUNT  RES 1
;;; floating point library exception flags
FPFLAGS    RES 1

;*********************************************************************************************
;
;;; GENERAL MATH LIBRARY DEFINITIONS
;
;;; general literal constants

;;; define assembler constants

;; B0       equ 0
;; B1       equ 1
;; B2       equ 2
;; B3       equ 3
;; B4       equ 4
;; B5       equ 5
;; B6       equ 6
;; B7       equ 7

;; MSB      equ 7
;; LSB      equ 0


;     define commonly used bits

;     STATUS bit definitions

;
;       general register variables
;

;; ACCB7           equ     0x0C
;; ACCB6           equ     0x0D
;; ACCB5           equ     0x0E
;; ACCB4           equ     0x0F
;; ACCB3           equ     0x10
;; ACCB2           equ     0x11
;; ACCB1           equ     0x12
;; ACCB0           equ     0x13
;; ACC             equ     0x13    ; most significant byte of contiguous 8 byte accumulator
;
;; SIGN            equ     0x15    ; save location for sign in MSB
;
;; TEMPB3          equ     0x1C
;; TEMPB2          equ     0x1D
;; TEMPB1          equ     0x1E
;; TEMPB0          equ     0x1F
;; TEMP            equ     0x1F    ; temporary storage
;
;       binary operation arguments
;
;; AARGB7          equ     0x0C
;; AARGB6          equ     0x0D
;; AARGB5          equ     0x0E
;; AARGB4          equ     0x0F
;; AARGB3          equ     0x10
;; AARGB2          equ     0x11
;; AARGB1          equ     0x12
;; AARGB0          equ     0x13
;; AARG            equ     0x13    ; most significant byte of argument A
;
;; BARGB3          equ     0x17
;; BARGB2          equ     0x18
;; BARGB1          equ     0x19
;; BARGB0          equ     0x1A
;; BARG            equ     0x1A    ; most significant byte of argument B
;
;       Note that AARG and ACC reference the same storage locations
;
;*********************************************************************************************
;
;       FIXED POINT SPECIFIC DEFINITIONS
;
;       remainder storage
;
;; REMB3           equ     0x0C
;; REMB2           equ     0x0D
;; REMB1           equ     0x0E
;; REMB0           equ     0x0F    ; most significant byte of remainder

;; LOOPCOUNT       equ     0x20    ; loop counter
;
;*********************************************************************************************
;
;       FLOATING POINT SPECIFIC DEFINITIONS
;
;       literal constants
;
;; EXPBIAS         equ     D'127'
;
;       biased exponents
;
;; EXP             equ     0x14    ; 8 bit biased exponent

;; AEXP            equ     0x14    ; 8 bit biased exponent for argument A

;; BEXP            equ     0x1B    ; 8 bit biased exponent for argument B
;
;       floating point library exception flags
;
;; FPFLAGS         equ     0x16    ; floating point library exception flags

;; IOV             equ     0       ; bit0 = integer overflow flag

;; FOV             equ     1       ; bit1 = floating point overflow flag

;; FUN             equ     2       ; bit2 = floating point underflow flag

;; FDZ             equ     3       ; bit3 = floating point divide by zero flag

;; NAN      equ 4   ; bit4 = not-a-number exception flag

;; DOM      equ 5   ; bit5 = domain error exception flag

;; RND             equ     6       ; bit6 = floating point rounding flag, 0 = truncation
;;                                 ; 1 = unbiased rounding to nearest LSB

;; SAT             equ     7       ; bit7 = floating point saturate flag, 0 = terminate on
;;                                 ; exception without saturation, 1 = terminate on
;;                                 ; exception with saturation to appropriate value

;;;
;;; 16/16 Bit Division Macro
;;; Max Timing:     13+14*18+17+8 = 290 clks
;;; Min Timing:     13+14*16+15+3 = 255 clks
;;; PM: 42                                  DM: 7
;;;
SDIV1616L macro

    RLF         AARGB0,W
    RLF         REMB1, F
    RLF         REMB0, F
    MOVF        BARGB1,W
    SUBWF       REMB1, F
    MOVF        BARGB0,W
    BTFSS       _C
    INCFSZ      BARGB0,W
    SUBWF       REMB0, F
    RLF         AARGB1, F
    RLF         AARGB0, F

    MOVLW       D'15'
    MOVWF       LOOPCOUNT

LOOPS1616:
    RLF         AARGB0,W
    RLF         REMB1, F
    RLF         REMB0, F
    MOVF        BARGB1,W

    BTFSS       AARGB1,LSB
    GOTO        SADD66L

    SUBWF       REMB1, F
    MOVF        BARGB0,W
    BTFSS       _C
    INCFSZ      BARGB0,W
    SUBWF       REMB0, F
    GOTO        SOK66LL

SADD66L:
    ADDWF       REMB1, F
    MOVF        BARGB0,W
    BTFSC       _C
    INCFSZ      BARGB0,W
    ADDWF       REMB0, F

SOK66LL:
    RLF         AARGB1, F
    RLF         AARGB0, F

    DECFSZ      LOOPCOUNT, F
    GOTO        LOOPS1616

    BTFSC       AARGB1,LSB
    GOTO        SOK66L
    MOVF        BARGB1,W
    ADDWF       REMB1, F
    MOVF        BARGB0,W
    BTFSC       _C
    INCFSZ      BARGB0,W
    ADDWF       REMB0, F
SOK66L:
    endm

;;;
;;; 08x08 Bit Multiplication Macro
;;; Max Timing:     3+12+6*8+7 = 70 clks
;;; Min Timing:     3+7*6+5+3 = 53 clks
;;; PM: 19            DM: 4
;;;
UMUL0808L macro
    MOVLW   0x08
    MOVWF   LOOPCOUNT
    MOVF    AARGB0,W

LOOPUM0808A:
    RRF     BARGB0, F
    BTFSC   _C
    GOTO    LUM0808NAP
    DECFSZ  LOOPCOUNT, F
    GOTO    LOOPUM0808A

    CLRF    AARGB0
    RETLW   0x00

LUM0808NAP:
    BCF     _C
    GOTO    LUM0808NA

LOOPUM0808:
    RRF             BARGB0, F
    BTFSC   _C
    ADDWF   AARGB0, F
LUM0808NA:
    RRF    AARGB0, F
    RRF    AARGB1, F
    DECFSZ LOOPCOUNT, F
    GOTO   LOOPUM0808
    endm

;;; relocatable code
COMMON CODE

;;;
;;; 16/16 Bit Signed Fixed Point Divide 16/16 -> 16.16
;;;
;;; Input:
;;; 16 bit fixed point dividend in AARGB0, AARGB1
;;; 16 bit fixed point divisor in BARGB0, BARGB1
;;;
;;; Use:    CALL    FXD1616S
;;;
;;; Output:
;;; 16 bit fixed point quotient in AARGB0, AARGB1
;;; 16 bit fixed point remainder in REMB0, REMB1
;;;
;;; Result: AARG, REM  <--  AARG / BARG
;;;
;;; Max Timing:
;;; 24+290+5 = 319 clks             A > 0, B > 0
;;; 28+290+16 = 334 clks            A > 0, B < 0
;;; 28+290+16 = 334 clks            A < 0, B > 0
;;; 32+290+5 = 327 clks             A < 0, B < 0
;;; 8 clks                          A = 0
;;;
;;; Min Timing:
;;; 24+255+5 = 284 clks             A > 0, B > 0
;;; 28+255+16 = 299 clks            A > 0, B < 0
;;; 28+255+16 = 299 clks            A < 0, B > 0
;;; 32+255+5 = 292 clks             A < 0, B < 0
;;;
;;; PM: 32+42+15+39 = 128
;;; DM: 10
;;;
math_fxd1616s:
    global math_fxd1616s
    CLRF        SIGN
    CLRF        REMB0           ; clear partial remainder
    CLRF        REMB1
    MOVF        AARGB0,W
    IORWF       AARGB1,W
    BTFSC       _Z
    RETLW       0x00

    MOVF        AARGB0,W
    XORWF       BARGB0,W
    MOVWF       TEMP
    BTFSC       TEMP,MSB
    COMF        SIGN,F

    CLRF        TEMPB3          ; clear exception flag

    BTFSS       BARGB0,MSB        ; if MSB set, negate BARG
    GOTO        CA1616S

    COMF        BARGB1, F
    COMF        BARGB0, F
    INCF        BARGB1, F
    BTFSC       _Z
    INCF        BARGB0, F

CA1616S:
    BTFSS       AARGB0,MSB        ; if MSB set, negate AARG
    GOTO        C1616SX

    COMF        AARGB1, F
    COMF        AARGB0, F
    INCF        AARGB1, F
    BTFSC       _Z
    INCF        AARGB0, F

C1616SX:
    MOVF        AARGB0,W
    IORWF       BARGB0,W
    MOVWF       TEMP
    BTFSC       TEMP,MSB
    GOTO        C1616SX1

C1616S:
    SDIV1616L

    BTFSC       TEMPB3,LSB      ; test exception flag
    GOTO        C1616SX4

C1616SOK:
    BTFSS       SIGN,MSB
    RETLW       0x00

    COMF        AARGB1, F
    COMF        AARGB0, F
    INCF        AARGB1, F
    BTFSC       _Z
    INCF        AARGB0, F

    COMF        REMB1, F
    COMF        REMB0, F
    INCF        REMB1, F
    BTFSC       _Z
    INCF        REMB0, F

    RETLW       0x00

C1616SX1:
    BTFSS       BARGB0,MSB      ; test BARG exception
    GOTO        C1616SX3
    BTFSC       AARGB0,MSB      ; test AARG exception
    GOTO        C1616SX2
    MOVF        AARGB0,W
    MOVWF       REMB0           ; quotient = 0, remainder = AARG
    MOVF        AARGB1,W
    MOVWF       REMB1
    CLRF        AARGB0
    CLRF        AARGB1
    GOTO        C1616SOK
C1616SX2:
    CLRF        AARGB0          ; quotient = 1, remainder = 0
    CLRF        AARGB1
    INCF        AARGB1,F
    RETLW       0x00

C1616SX3:
    COMF        AARGB0,F        ; numerator = 0x7FFF + 1
    COMF        AARGB1,F
    INCF        TEMPB3,F
    GOTO        C1616S

C1616SX4:
    INCF        REMB1,F         ; increment remainder and test for
    BTFSC       _Z          ; overflow
    INCF        REMB0,F
    MOVF        BARGB1,W
    SUBWF       REMB1,W
    BTFSS       _Z
    GOTO        C1616SOK
    MOVF        BARGB0,W
    SUBWF       REMB0,W
    BTFSS       _Z
    GOTO        C1616SOK
    CLRF        REMB0           ; if remainder overflow, clear
    CLRF        REMB1           ; remainder, increment quotient and
    INCF        AARGB1,F        ; test for overflow exception
    BTFSC       _Z
    INCF        AARGB0,F
    BTFSS       AARGB0,MSB
    GOTO        C1616SOK
    BSF     FPFLAGS,NAN
    RETLW       0xFF


;;;
;;; 8x8 Bit Unsigned Fixed Point Multiply 8x8 -> 16
;;;
;;; Input:
;;; 8 bit unsigned fixed point multiplicand in AARGB0
;;; 8 bit unsigned fixed point multiplier in BARGB0
;;;
;;; Use:    CALL    FXM0808U
;;;
;;; Output:
;;; 8 bit unsigned fixed point product in AARGB0
;;;
;;; Result: AARG  <--  AARG x BARG
;;;
;;; Max Timing:
;;;     1+70+2 = 73 clks
;;;
;;; Min Timing:
;;;     1+53 = 54 clks
;;;
;;; PM: 1+19+1 = 21
;;; DM: 4
;;;
math_fxm0808u:
    global math_fxm0808u

    CLRF    AARGB1          ; clear partial product
    UMUL0808L
    RETLW           0x00

END

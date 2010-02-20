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

;;; Variables from math module are located in the same bank
;;; So a single 'banksel' of these variable have to be realized before
;;; using math variable or calling math functions
MATH_VAR    UDATA
number_a_lo  RES 1
    global number_a_lo
number_a_hi  RES 1
    global number_a_hi
number_b_lo  RES 1
    global number_b_lo
number_b_hi  RES 1
    global number_b_hi
number_c_lo  RES 1
    global number_c_lo
number_c_hi  RES 1
    global number_c_hi
number_d_lo  RES 1
    global number_d_lo
number_d_hi  RES 1
    global number_d_hi
count  RES 1
sign    RES 1

;;; relocatable code
COMMON CODE

;;;
;;; Double Precision Subtraction ( number_b - number_a -> number_b )
;;;
math_sub_1616s:
    global math_sub_1616s
    ;; At first negate number_a
    call    math_neg_number_a_16s
    ;; Then add
    ;; -> do not return, but continue execution with ADD function

;;;
;;; Double Precision  Addition ( number_b + number_a -> number_b )
;;;
math_add_1616s:
    global math_add_1616s
    movf    number_a_lo,W
	addwf   number_b_lo, F       ;add lsb
	btfsc   STATUS,C        ;add in carry
	incf    number_b_hi, F
	movf    number_a_hi,W
	addwf   number_b_hi, F       ;add msb
	retlw   0


                                ;
;;;
;;; Negate double precision number_a (INT16S)
;;;
math_neg_number_a_16s:
    global math_neg_number_a_16s
    comf    number_a_lo, F       ; negate number_a ( - number_a -> number_a )
	incf    number_a_lo, F
	btfsc   STATUS,Z
	decf    number_a_hi, F
	comf    number_a_hi, F
	retlw   0

;;;
;;; Negate double precision number_b (INT16S)
;;;
math_neg_number_b_16s:
    global math_neg_number_a_16s
    comf    number_b_lo, F       ; negate number_b ( - number_b -> number_b )
	incf    number_b_lo, F
	btfsc   STATUS,Z
	decf    number_b_hi, F
	comf    number_b_hi, F
	retlw   0



;;;
;;;       Double Precision Divide ( 16/16 -> 16 )
;;;
;;;         ( number_b / number_a -> number_b with remainder in number_c ) : 16 bit output
;;; with Quotiont in number_b (number_b_hi,number_b_lo) and Remainder in number_v (number_c_hi,number_c_lo).
;;;
;;;   NOTE  :  Before calling this routine, the user should make sure that
;;;            the Numerator(number_b) is greater than Denominator(number_a). If
;;;            the case is not true, the user should scale either Numerator
;;;            or Denominator or both such that Numerator is greater than
;;;            the Denominator.
;;;
;;;
math_div_16s16s_16s:
    global math_div_16s16s_16s

    movf    number_a_hi,W
	xorwf   number_b_hi,W
	movwf   sign
	btfss   number_b_hi,MSB        ; if MSB set go & negate number_b
	goto    chek_A

	comf    number_b_lo, F          ; negate number_b
	incf    number_b_lo, F
	btfsc   STATUS,Z
	decf    number_b_hi, F
	comf    number_b_hi, F

chek_A:
    btfsc   number_a_hi,MSB        ; if MSB set go & negate number_a
	call    math_neg_number_a_16s

    movlw   .16             ; for 16 shifts
	movwf   count
	movf    number_b_hi,W          ;move number_b to number_d
	movwf   number_d_hi
	movf    number_b_lo,W
	movwf   number_d_lo
	clrf    number_b_hi
	clrf    number_b_lo

	clrf    number_c_hi
	clrf    number_c_lo
dloop:
    bcf     STATUS,C
	rlf     number_d_lo, F
	rlf     number_d_hi, F
	rlf     number_c_lo, F
	rlf     number_c_hi, F
	movf    number_a_hi,W
	subwf   number_c_hi,W          ;check if a>c
	btfss   STATUS,Z
	goto    nochk
	movf    number_a_lo,W
	subwf   number_c_lo,W        ;if msb equal then check lsb
nochk:
    btfss   STATUS,C    ;carry set if c>a
	goto    nogo
	movf    number_a_lo,W        ;c-a into c
	subwf   number_c_lo, F
	btfss   STATUS,C
	decf    number_c_hi, F
	movf    number_a_hi,W
	subwf   number_c_hi, F
	bsf     STATUS,C    ;shift a 1 into b (result)
nogo:
    rlf     number_b_lo, F
	rlf     number_b_hi, F
	decfsz  count, F         ;loop untill all bits checked
	goto    dloop
;
	btfsc   sign, MSB        ; check sign if negative
	goto    math_neg_number_b_16s    ; negate number_b ( -number_b -> number_b )
	retlw   0



;;;
;;;   The 16 bit result is stored in 2 bytes
;;;
;;; Before calling this function, the multiplier should
;;; be loaded in location " number_a_lo ", and the multiplicand in
;;; " number_b_lo " . The 16 bit result is stored in locations
;;; number_c_hi & number_c_lo.
;;;
;;;       Performance :
;;;                       Program Memory  :  15 locations
;;;                       # of cycles     :  71
;;;                       Scratch RAM     :   0 locations
;;;
;;;
;;;       Program:          MULT8x8S.ASM
;;;       Revision Date:
;;;                         1-13-97      Compatibility with MPASMWIN 1.40
;;;
;;;  This routine is optimized for code efficiency ( looped code )
;;;  For time efficiency code refer to "mult8x8F.asm" ( straight line code )
;;;
math_mult_08u08u_16u:
    global math_mult_08u08u_16u

    clrf    number_c_hi
	clrf    number_c_lo
	movlw   8
	movwf   count
	movf    number_b_lo,W
	bcf     STATUS,C    ; Clear the carry bit in the status Reg.
loop:
    rrf     number_a_lo, F
	btfsc   STATUS,C
	addwf   number_c_hi, F
	rrf     number_c_hi, F
	rrf     number_c_lo,F
	decfsz  count, F
	goto    loop

	retlw   0

#if 1
#include <lcd.inc>

;;; Test math functions
;;; Result are printed on the screen as 2 byte value (without space)
;;; The expected result is printed in comment in the code
math_test:
    global math_test

    ;; **** TEST MATH ****
    call lcd_clear
    ;; Mult 1. Expected result: 004 218
    math_banksel
    movlw 0x12
    movwf number_a_lo
    movlw 0x45
    movwf number_b_lo
    call math_mult_08u08u_16u
    clrf param1
    clrf param2
    call lcd_locate
    math_banksel
    movf number_c_hi, W
    movwf param1
    clrf param2
    call lcd_int
    math_banksel
    movf number_c_lo, W
    movwf param1
    clrf param2
    call lcd_int

    ;; Mult 2. Expected result:  254 001
    math_banksel
    movlw 0xFF
    movwf number_a_lo
    movlw 0xFF
    movwf number_b_lo
    call math_mult_08u08u_16u
    movlw 0x11
    movwf param1
    clrf param2
    call lcd_locate
    math_banksel
    movf number_c_hi, W
    movwf param1
    clrf param2
    call lcd_int
    math_banksel
    movf number_c_lo, W
    movwf param1
    clrf param2
    call lcd_int

    ;; Add 1. Expected result: 034 080
    math_banksel
    movlw 0x12
    movwf number_a_lo
    clrf number_a_hi
    movlw 0x3E
    movwf number_b_lo
    movlw 0x22
    movwf number_b_hi
    call math_add_1616s
    clrf param1
    movlw 1
    movwf param2
    call lcd_locate
    math_banksel
    movf number_b_hi, W
    movwf param1
    clrf param2
    call lcd_int
    math_banksel
    movf number_b_lo, W
    movwf param1
    clrf param2
    call lcd_int

    ;; Add 2. Expected result: 065 016
    math_banksel
    movlw 0x12
    movwf number_a_lo
    movlw 0x41
    movwf number_a_hi
    ;; -2
    movlw 0xFE
    movwf number_b_lo
    movlw 0xFF
    movwf number_b_hi
    call math_add_1616s
    movlw 0x11
    movwf param1
    movlw 1
    movwf param2
    call lcd_locate
    math_banksel
    movf number_b_hi, W
    movwf param1
    clrf param2
    call lcd_int
    math_banksel
    movf number_b_lo, W
    movwf param1
    clrf param2
    call lcd_int

    ;; Neg. Expected result: 239 064
    math_banksel
    movlw 0x45
    movwf number_b_lo
    movlw 0xFF
    movwf number_b_hi
    movlw 0x05
    movwf number_a_lo
    movlw 0x10
    movwf number_a_hi
    call math_sub_1616s
    movlw 0x0
    movwf param1
    movlw 2
    movwf param2
    call lcd_locate
    math_banksel
    movf number_b_hi, W
    movwf param1
    clrf param2
    call lcd_int
    math_banksel
    movf number_b_lo, W
    movwf param1
    clrf param2
    call lcd_int

    ;; Div 1. Expected result: 000 007
    math_banksel
    movlw 0x45
    movwf number_b_lo
    movlw 0x7F
    movwf number_b_hi
    movlw 0x05
    movwf number_a_lo
    movlw 0x10
    movwf number_a_hi
    call math_div_16s16s_16s
    movlw 0x0
    movwf param1
    movlw 3
    movwf param2
    call lcd_locate
    math_banksel
    movf number_b_hi, W
    movwf param1
    clrf param2
    call lcd_int
    math_banksel
    movf number_b_lo, W
    movwf param1
    clrf param2
    call lcd_int

    ;; Div 2. Expected result: 254 038
    math_banksel
    movlw 0x00
    movwf number_b_lo
    movlw 0x80
    movwf number_b_hi
    movlw 0x45
    movwf number_a_lo
    movlw 0x00
    movwf number_a_hi
    call math_div_16s16s_16s
    movlw 0x11
    movwf param1
    movlw 3
    movwf param2
    call lcd_locate
    math_banksel
    movf number_b_hi, W
    movwf param1
    clrf param2
    call lcd_int
    math_banksel
    movf number_b_lo, W
    movwf param1
    clrf param2
    call lcd_int
    return
    goto $
#endif



END

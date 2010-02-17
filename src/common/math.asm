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
mulcnd  RES 1
mulplr  RES 1
H_byte  RES 1
L_byte  RES 1
count   RES 1


ACCaLO  RES 1
ACCaHI  RES 1
ACCbLO  RES 1
ACCbHI  RES 1
ACCcLO  RES 1
ACCcHI  RES 1
ACCdLO  RES 1
ACCdHI  RES 1
temp    RES 1
sign    RES 1

;;; relocatable code
COMMON CODE

;;;
;;; Double Precision Subtraction ( ACCb - ACCa -> ACCb )
;;;
math_sub_1616s:
    global math_sub_1616s
    ;; At first negate ACCa
    call    math_neg_16s
    ;; Then add
    ;; -> do not return, but continue execution with ADD function

;;;
;;; Double Precision  Addition ( ACCb + ACCa -> ACCb )
;;;
math_add_1616s:
    global math_add_1616s
    movf    ACCaLO,W
	addwf   ACCbLO, F       ;add lsb
	btfsc   STATUS,C        ;add in carry
	incf    ACCbHI, F
	movf    ACCaHI,W
	addwf   ACCbHI, F       ;add msb
	retlw   0


                                ;
;;;
;;; Negate double precision number (INT16S)
;;;
math_neg_16s:
    global math_neg_16s
    comf    ACCaLO, F       ; negate ACCa ( -ACCa -> ACCa )
	incf    ACCaLO, F
	btfsc   STATUS,Z
	decf    ACCaHI, F
	comf    ACCaHI, F
	retlw   0



;;;
;;;       Double Precision Divide ( 16/16 -> 16 )
;;;
;;;         ( ACCb/ACCa -> ACCb with remainder in ACCc ) : 16 bit output
;;; with Quotiont in ACCb (ACCbHI,ACCbLO) and Remainder in ACCc (ACCcHI,ACCcLO).
;;;
;;;   NOTE  :  Before calling this routine, the user should make sure that
;;;            the Numerator(ACCb) is greater than Denominator(ACCa). If
;;;            the case is not true, the user should scale either Numerator
;;;            or Denominator or both such that Numerator is greater than
;;;            the Denominator.
;;;
;;;
math_div_16s16s_16s:
    global math_div_16s16s_16s

    movf    ACCaHI,W
	xorwf   ACCbHI,W
	movwf   sign
	btfss   ACCbHI,MSB        ; if MSB set go & negate ACCb
	goto    chek_A

	comf    ACCbLO, F          ; negate ACCb
	incf    ACCbLO, F
	btfsc   STATUS,Z
	decf    ACCbHI, F
	comf    ACCbHI, F

chek_A:
    btfsc   ACCaHI,MSB        ; if MSB set go & negate ACCa
	call    math_neg_16s

    movlw   .16             ; for 16 shifts
	movwf   temp
	movf    ACCbHI,W          ;move ACCb to ACCd
	movwf   ACCdHI
	movf    ACCbLO,W
	movwf   ACCdLO
	clrf    ACCbHI
	clrf    ACCbLO

	clrf    ACCcHI
	clrf    ACCcLO
dloop:
    bcf     STATUS,C
	rlf     ACCdLO, F
	rlf     ACCdHI, F
	rlf     ACCcLO, F
	rlf     ACCcHI, F
	movf    ACCaHI,W
	subwf   ACCcHI,W          ;check if a>c
	btfss   STATUS,Z
	goto    nochk
	movf    ACCaLO,W
	subwf   ACCcLO,W        ;if msb equal then check lsb
nochk:
    btfss   STATUS,C    ;carry set if c>a
	goto    nogo
	movf    ACCaLO,W        ;c-a into c
	subwf   ACCcLO, F
	btfss   STATUS,C
	decf    ACCcHI, F
	movf    ACCaHI,W
	subwf   ACCcHI, F
	bsf     STATUS,C    ;shift a 1 into b (result)
nogo:
    rlf     ACCbLO, F
	rlf     ACCbHI, F
	decfsz  temp, F         ;loop untill all bits checked
	goto    dloop
;
	btfsc   sign, MSB        ; check sign if negative
	goto    math_neg_16s    ; negate ACCa ( -ACCa -> ACCa )
	retlw   0



;;;
;;;   The 16 bit result is stored in 2 bytes
;;;
;;; Before calling the subroutine " mpy ", the multiplier should
;;; be loaded in location " mulplr ", and the multiplicand in
;;; " mulcnd " . The 16 bit result is stored in locations
;;; H_byte & L_byte.
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

    clrf    H_byte
	clrf    L_byte
	movlw   8
	movwf   count
	movf    mulcnd,W
	bcf     STATUS,C    ; Clear the carry bit in the status Reg.
loop:
    rrf     mulplr, F
	btfsc   STATUS,C
	addwf   H_byte, F
	rrf     H_byte, F
	rrf     L_byte,F
	decfsz  count, F
	goto    loop

	retlw   0


END

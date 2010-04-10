#define MATH_MAX_16S_VALUE  0x7FFF
#define MATH_MIN_16S_VALUE  0x8000

#define number_a_lo     number_a
#define number_a_hi     (number_a+1)

#define number_b_lo     number_b
#define number_b_hi     (number_b+1)

#define number_c_lo     number_c
#define number_c_hi     (number_c+1)

#define number_d_lo     number_d
#define number_d_hi     (number_d+1)

math_banksel macro
    banksel number_a_lo
    endm

math_copy_16 macro number_from, number_to
    banksel (number_from)
    movf (number_from), W
    banksel (number_to)
    movwf (number_to)
    banksel (number_from)+1
    movf (number_from)+1, W
    banksel (number_to)+1
    movwf (number_to)+1
    endm

;;; This macro set the Z bit of STATUS register if number_test
;;; is equal to 0
math_test_16 macro number_test
    local math_test_16_end
    banksel number_test
    movf number_test, F
    btfss STATUS, Z
    goto math_test_16_end
    movf number_test+1, F
math_test_16_end:
    endm

;;; This macro set the Z bit of STATUS if the parameters are equal.
math_equal macro number_16_a, number_16_b
    local math_equal_end
    banksel number_16_a
    movf number_16_a, W
    banksel number_16_b
    subwf number_16_b, W
    btfss STATUS, Z
    goto math_equal_end

    banksel number_16_a
    movf number_16_a+1, W
    banksel number_16_b
    subwf number_16_b+1, W
math_equal_end:
    endm

;;; Load a 16 bit constant value into a 16 bit variable
math_load_const macro reg16, const_value
    banksel reg16
    movlw low const_value
    movwf reg16
    movlw high const_value
    movwf reg16+1
    endm

;;; Increment 16 bits number by taking care of roll over.
;;; changed registers: number_a
math_inc_16 macro number_16
    local math_inc_16_end
    math_load_const number_a, MATH_MAX_16S_VALUE
    math_equal number_16, number_a
    btfsc STATUS, Z
    goto math_inc_16_end
    ;; Not equal to highest value
    ;; -> can be incremented
    banksel number_16
    incf number_16, F
    btfss STATUS, Z
    goto math_inc_16_end
    incf number_16+1, F
math_inc_16_end:
    endm

#ifndef MATH_M
    extern number_a
    extern number_b
    extern number_c
    extern number_d

    extern math_sub_1616s
    extern math_add_1616s
    extern math_neg_number_a_16s
    extern math_neg_number_b_16s
    extern math_div_16s16s_16s
    extern math_mult_08u08u_16u

#if 0
    extern math_test
#endif
#endif

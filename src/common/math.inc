
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
    banksel number_from
    movf number_from, W
    banksel number_to+1
    movwf number_to+1
    banksel number_from+1
    movf number_from+1, W
    banksel number_to+1
    movwf number_to+1
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

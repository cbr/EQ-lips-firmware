math_banksel macro
    banksel number_a_lo
    endm
#ifndef MATH_M
    extern number_a_lo
    extern number_a_hi
    extern number_b_lo
    extern number_b_hi
    extern number_c_lo
    extern number_c_hi
    extern number_d_lo
    extern number_d_hi

    extern math_sub_1616s
    extern math_add_1616s
    extern math_neg_number_a_16s
    extern math_neg_number_b_16s
    extern math_div_16s16s_16s
    extern math_mult_08u08u_16u

#if 1
    extern math_test
#endif
#endif

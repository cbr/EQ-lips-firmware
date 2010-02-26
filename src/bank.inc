#define BANK_NB_NUMPOT_VALUES            0xB

#ifndef BANK_M
    ;; Variables
    extern bank_nb_inc
    extern bank_numpot_values_a
    extern bank_numpot_values_b
    extern bank_trem_type
    extern bank_trem_rate

    ;; Functions
    extern bank_load
    extern bank_save
#endif

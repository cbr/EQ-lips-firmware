#define BANK_NB_NUMPOT_VALUES            0xB

#ifndef BANK_M
    ;; Variables
    extern bank_nb_inc
    extern bank_numpot_values
    extern bank_trem_type
    extern bank_trem_rate

    ;; Functions
    extern bank_load
    extern bank_save
    extern bank_load_eq_gain
    extern bank_save_eq_gain
#endif

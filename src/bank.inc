#define BANK_NB_NUMPOT_VALUES            0xB
#define BANK_POS_GAIN_IN_NUMPOT          0xA
#define BANK_MAX_TREM_RATE_VALUE         0x64
#define BANK_MAX_TREM_SPEED_VALUE        0xFF

#define BANK_TREM_TYPE_NONE              0x00
#define BANK_TREM_TYPE_SIMPLE            0x01
#define BANK_TREM_TYPE_EQ                0x02


#ifndef BANK_M
    ;; Variables
    extern bank_nb_inc
    extern bank_numpot_values
    extern bank_trem_type
    extern bank_trem_rate
    extern bank_trem_target

    ;; Functions
    extern bank_load
    extern bank_save
    extern bank_load_eq_gain
    extern bank_save_eq_gain
#endif

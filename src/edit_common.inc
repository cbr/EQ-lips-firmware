
#ifndef EDIT_COMMON_M
    ;; Variables
    extern edit_common_st_bank
    extern edit_common_st_load
    extern edit_common_st_save
    extern edit_common_down_btn_released
    extern edit_common_up_btn_released
    extern edit_common_both_btn_pressed

    ; Functions
    extern edit_common_init
    extern edit_common_save
    extern edit_common_load
    extern edit_common_refresh
    extern edit_common_sleep
    extern edit_common_check_buttons
#ifdef TREMOLO
    extern edit_common_cycle_period
#endif

#endif

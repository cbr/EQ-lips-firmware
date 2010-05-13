edit_common_basic_btn_mgt macro reload_label
    local chk_down
    local chk_up
    local end_mgt

chk_down:
    banksel edit_common_down_btn_released
    movf edit_common_down_btn_released, W
    btfsc STATUS, Z
    goto chk_up
    ;; Down button pressed
    decf edit_common_down_btn_released, F
    ;; Try to dec bank number if possible
    banksel current_bank
    movf current_bank, W
    sublw 1
    btfsc STATUS, Z
    goto chk_up
    decf current_bank, F
    call_other_page edit_common_load
    goto_other_page reload_label
chk_up:
    banksel edit_common_up_btn_released
    movf edit_common_up_btn_released, W
    btfsc STATUS, Z
    goto end_mgt
    ;; Up button pressed
    decf edit_common_up_btn_released, F
    ;; Try to dec bank number if possible
    banksel current_bank
    movf current_bank, W
    sublw BANK_NB
    btfsc STATUS, Z
    goto end_mgt
    incf current_bank, F
    call_other_page edit_common_load
    goto_other_page reload_label

end_mgt:
    endm



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

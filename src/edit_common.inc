#define ID_BANK_UP      0x200
#define ID_BANK_DOWN    0x201

edit_common_basic_btn_mgt macro
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
    menu_select_specific_entry ID_BANK_DOWN
    goto end_mgt
chk_up:
    banksel edit_common_up_btn_released
    movf edit_common_up_btn_released, W
    btfsc STATUS, Z
    goto end_mgt
    ;; Up button pressed
    decf edit_common_up_btn_released, F
    menu_select_specific_entry ID_BANK_UP
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
    extern edit_common_bank_up
    extern edit_common_bank_down
#ifdef TREMOLO
    extern edit_common_cycle_period
#endif

#endif

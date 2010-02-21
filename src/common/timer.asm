#define TIMER_M

#include <cpu.inc>
#include <global.inc>
#include <std.inc>
#include <timer.inc>



    UDATA
var1       RES 1


; relocatable code
COMMON CODE

timer_get_data:
    global timer_get_data
    return
END

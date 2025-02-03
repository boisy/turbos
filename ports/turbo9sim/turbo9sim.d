                    ifne      TURBO9SIM.D-1
TURBO9SIM.D         set       1

********************************************************************
* Turbo9SimDefs - TurbOS System Definitions for the Turbo9 Simulator
*
* This is a high level view of the F256 memory map as setup by
* TurbOS
*
*     $0000----> ==================================
*               |                                  |
*               |        TurbOS Globals/Stack      |
*               |                                  |
*     $0500---->|==================================|
*               |                                  |
*                 . . . . . . . . . . . . . . . . .
*               |                                  |
*               |   RAM available for allocation   |
*               |         by TurbOS and Apps       |
*               |                                  |
*                 . . . . . . . . . . . . . . . . .
*               |                                  |
*     $FD00---->|==================================|
*               |    Constant RAM (for Level 2)    |
*     $FE00---->|==================================|
*               |                I/O               |
*               |            &  Vectors            |
*                ==================================
*
* F256 hardware is documented here:
*   https://github.com/pweingar/C256jrManual/blob/main/tex/f256jr_ref.pdf
*
* $Id$
*
* Edt/Rev  YYYY/MM/DD  Modified by
* Comment
* ------------------------------------------------------------------
*          2023/02/07  Boisy G. Pitre
* Started.
*
*          2023/08/16  Boisy G. Pitre
* Modified to address new memory map that Stefany created.

********************************************************************
* Ticks per second
*
TkPerSec            set       60

********************************************************************
*
* TurbOS Section
*
********************************************************************

********************************************************************
* Boot definitions for TurbOS
*
* These definitions are not strictly for 'Boot', but are for booting the
* system.
*
HW.Page             set       $FF                 device descriptor hardware page
                    endc

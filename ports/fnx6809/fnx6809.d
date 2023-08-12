*******************************************************************************
* TurbOS
*******************************************************************************
* See LICENSE.txt for licensing information.
*******************************************************************************
*
* Edt/Rev  YYYY/MM/DD  Modified by
* Comment
* ----------------------------------------------------------------------------
*          2023/08/11  Boisy Pitre
* Initial creation.
*
********************************************************************
*
* This is a high level view of the FNX6809 memory map as setup by
* the kernel.
*
*     $0000----> ================================== 
*               |      FNX6809 MMU Registers       |
*     $0010----> ================================== 
*               |                                  |
*               |       Kernel Globals/Stack       |
*               |                                  |
*     $0500---->|==================================|
*               |                                  |
*                 . . . . . . . . . . . . . . . . .
*               |                                  |
*               |   RAM available for allocation   |
*               |          by OS and Apps          |
*               |                                  |
*                 . . . . . . . . . . . . . . . . .
*               |                                  |
*     $C000---->|==================================|
*               |                                  |
*  $C000-$DFFF  |          RAM, but also           |
*               |    I/O for text and color data   |
*               |                                  |
*     $E000---->|==================================|
*               |                                  |
*  $E000-$FFFF  |               RAM                |
*               |                                  |
*                ================================== 
*
* FNX6809 hardware is documented here:
*   https://github.com/pweingar/C256jrManual/blob/main/tex/f256jr_ref.pdf
*
* $Id$
*
* Edt/Rev  YYYY/MM/DD  Modified by
* Comment
* ------------------------------------------------------------------
*          2023/08/23  Boisy G. Pitre
* Started

               ifne      FNX6809.D-1
FNX6809.D      set       1

               nam       FNX6809Defs
               ttl       Definitions for the Foenix FNX6809

********************************************************************
* Power Line Frequency Definitions
*
Hz50           equ       1                   Assemble clock for 50 hz power
Hz60           equ       2                   Assemble clock for 60 hz power
               ifndef                        PwrLnFrq
PwrLnFrq       set       Hz60                Set to Appropriate freq
               endc      


********************************************************************
* Ticks per second
*
               ifndef                        TkPerSec
               ifeq      PwrLnFrq-Hz60
TkPerSec       set       60
               else      
TkPerSec       set       70
               endc      
               endc      


********************************************************************
*
* Kernel Section
*
********************************************************************

********************************************************************
* Boot definitions for Kernel
*
* These definitions are not strictly for 'Boot', but are for booting the
* system.
*
Bt.Start       set       $8000
Bt.Size        equ       $1080               Maximum size of bootfile
Bt.Track       equ       $0000
Bt.Sec         equ       0
HW.Page        set       $FF                 Device descriptor hardware page


********************************************************************
* Screen Definitions for the FNX6809
*
G.Cols         equ       80
               ifeq      PwrLnFrq-Hz60
G.Rows         equ       60
               else      
G.Rows         equ       70
               endc      

* The screen start address is in the I/O area starting at $C000
G.ScrStart     equ       $C000
G.ScrEnd       equ       G.ScrStart+(G.Cols*G.Rows)

********************************************************************
* FNX6809 MMU Definitions
*
MMU_MEM_CTRL   equ       $0000
MMU_IO_CTRL    equ       $0001

* MMU_MEM_CTRL bits
EDIT_EN        equ       %10000000
EDIT_LUT       equ       %00110000
EDIT_LUT_0     equ       %00000000
EDIT_LUT_1     equ       %00010000
EDIT_LUT_2     equ       %00100000
EDIT_LUT_3     equ       %00110000
ACT_LUT        equ       %00000000
ACT_LUT_0      equ       %00000000
ACT_LUT_1      equ       %00000001
ACT_LUT_2      equ       %00000010
ACT_LUT_3      equ       %00000011

LUT_BANK_0     equ       $0008
LUT_BANK_1     equ       $0009
LUT_BANK_2     equ       $000A
LUT_BANK_3     equ       $000B
LUT_BANK_4     equ       $000C
LUT_BANK_5     equ       $000D
LUT_BANK_6     equ       $000E
LUT_BANK_7     equ       $000F

* MMU_IO_CTRL bits
IO_DISABLE     equ       %00000100
IO_PAGE        equ       %00000011

********************************************************************
* FNX6809 Interrupt Definitions
*
* Interrupt Addresses
INT_PENDING_0  equ       0xD660
INT_POLARITY_0 equ       0xD664
INT_EDGE_0     equ       0xD668
INT_MASK_0     equ       0xD66C

INT_PENDING_1  equ       0xD661
INT_POLARITY_1 equ       0xD665
INT_EDGE_1     equ       0xD669
INT_MASK_1     equ       0xD66D

INT_PENDING_2  equ       0xD662
INT_POLARITY_2 equ       0xD666
INT_EDGE_2     equ       0xD66A
INT_MASK_2     equ       0xD66E

* Interrupt Group 0 Flags
INT_VKY_SOF    equ       %00000001           TinyVicky Start Of Frame Interrupt
INT_VKY_SOL    equ       %00000010           TinyVicky Start Of Line Interrupt
INT_PS2_KBD    equ       %00000100           PS/2 keyboard event
INT_PS2_MOUSE  equ       %00001000           PS/2 mouse event
INT_TIMER_0    equ       %00010000           TIMER0 has reached its target value
INT_TIMER_1    equ       %00010000           TIMER1 has reached its target value
INT_CARTRIDGE  equ       %10000000           Interrupt asserted by the cartridge

* Interrupt Group 1 Flags
INT_UART       equ       %00000001           The UART is ready to receive or send data
INT_RTC        equ       %00010000           Event from the real time clock chip
INT_VIA0       equ       %00100000           Event from the 65C22 VIA chip
INT_VIA1       equ       %01000000           F256K Only: Local keyboard
INT_SDC_INS    equ       %01000000           User has inserted an SD card

* Interrupt Group 2 Flags
IEC_DATA_i     equ       %00000001           IEC Data In
IEC_CLK_i      equ       %00000010           IEC Clock In
IEC_ATN_i      equ       %00000100           IEC ATN In
IEC_SREQ_i     equ       %00001000           IEC SREQ In

********************************************************************
* FNX6809 Timer Definitions
*
* Timer Addresses
T0_CTR         equ       $D650               Timer 0 Counter (Write)
T0_STAT        equ       $D650               Timer 0 Status (Read)
T0_VAL         equ       $D651               Timer 0 Value (Read/Write)
T0_CMP_CTR     equ       $D654               Timer 0 Compare Counter (Read/Write)
T0_CMP         equ       $D655               Timer 0 Compare Value (Read/Write)
T1_CTR         equ       $D658               Timer 1 Counter (Write)
T1_STAT        equ       $D658               Timer 1 Status (Read)
T1_VAL         equ       $D659               Timer 1 Value (Read/Write)
T1_CMP_CTR     equ       $D65C               Timer 1 Compare Counter (Read/Write)
T1_CMP         equ       $D65D               Timer 1 Compare Value (Read/Write)

********************************************************************
* FNX6809 VIA Definitions
*
* VIA Addresses
IORB           equ       $DC00               Port B Data
IORA           equ       $DC01               Port A Data
DDRB           equ       $DC02               Port B Data Direction Register
DDRA           equ       $DC03               Port A Data Direction Register
T1C_L          equ       $DC04               Timer 1 Counter Low
T1C_H          equ       $DC05               Timer 1 Counter High
T1L_L          equ       $DC06               Timer 1 Latch Low
T1L_H          equ       $DC07               Timer 1 Latch High
T2C_L          equ       $DC08               Timer 2 Counter Low
T2C_H          equ       $DC09               Timer 2 Counter High
SDR            equ       $DC0A               Serial Data Register
ACR            equ       $DC0B               Auxiliary Control Register
PCR            equ       $DC0C               Peripheral Control Register
IFR            equ       $DC0D               Interrupt Flag Register
IER            equ       $DC0E               Interrupt Enable Register
IORA2          equ       $DC0F               Port A Data (no handshake)

* ACR Control Register Values
T1_CTRL        equ       %11000000
T2_CTRL        equ       %00100000
SR_CTRL        equ       %00011100
PBL_EN         equ       %00000010
PAL_EN         equ       %00000001

* PCR Control Register Values
CB2_CTRL       equ       %11100000
CB1_CTRL       equ       %00010000
CA2_CTRL       equ       %00001110
CA1_CTRL       equ       %00000001

* IFR Control Register Values
IRQF           equ       %10000000
T1F            equ       %01000000
T2F            equ       %00100000
CB1F           equ       %00010000
CB2F           equ       %00001000
SRF            equ       %00000100
CA1F           equ       %00000010
CA2F           equ       %00000001

* IER Control Register Values
IERSET         equ       %10000000
T1E            equ       %01000000
T2E            equ       %00100000
CB1E           equ       %00010000
CB2E           equ       %00001000
SRE            equ       %00000100
CA1E           equ       %00000010
CA2E           equ       %00000001

********************************************************************
* FNX6809 SD Card Interface Definitions
*
SDC_STAT       equ       $DD00
SDC_DATA       equ       $DD01

SPI_BUSY       equ       %10000000
SPI_CLK        equ       %00000010
CS_EN          equ       %00000001

MCTRL_REG_L    equ       $D000
MCTRL_REG_H    equ       $D001

* Control bit fields
MCTXM_ENABLE   equ       $01                 enables text mode
MCTXO_ENABLE   equ       $02                 enables overlay of the text mode on top of graphic mode (background color is ignored)
MCGXM_ENABLE   equ       $04                 enables the graphic mode
MCBM_ENABLE    equ       $08                 enables the bitmap module in Vicky
MCTM_ENABLE    equ       $10                 enables the tile module in Vicky
MCS_ENABLE     equ       $20                 enables the sprite module in Vicky
MCG_ENABLE     equ       $40                 enables the gamma correction - analog and DVI have different color values; gama corrects this
MCV_DISABLE    equ       $80                 disables the scanning of video and giving 100% bandwidth to the CPU

VKY_RESERVED_00 equ       $D002
VKY_RESERVED_01 equ       $D003
* 
BORDER_CTRL_REG equ       $D004               bit 0 - enable (1 by default)  bits 4-6: X scroll offset (will scroll Left) (acceptable values: 0-7)
BORDER_CTRL_ENABLE equ       $01
BORDER_COLOR_B equ       $D005
BORDER_COLOR_G equ       $D006
BORDER_COLOR_R equ       $D007
BORDER_X_SIZE  equ       $D008               X-  Values: 0 - 32 (Default: 32)
BORDER_Y_SIZE  equ       $D009               Y- Values 0 -32 (Default: 32)
* Reserved - TBD

VKY_TXT_CURSOR_CTRL_REG equ       $D010               enable text mode

TEXT_LUT_FG    equ       $D800
TEXT_LUT_BG    equ       $D840

               endc      

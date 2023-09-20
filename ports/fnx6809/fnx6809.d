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
MMU_MEM_CTRL   equ       $FFA0
MMU_IO_CTRL    equ       $FFA1
MMU_SLOT_0     equ       $FFA8               $0000-$1FFF
MMU_SLOT_1     equ       $FFA9               $2000-$3FFF
MMU_SLOT_2     equ       $FFAA               $4000-$5FFF
MMU_SLOT_3     equ       $FFAB               $6000-$7FFF
MMU_SLOT_4     equ       $FFAC               $8000-$9FFF
MMU_SLOT_5     equ       $FFAD               $A000-$BFFF
MMU_SLOT_6     equ       $FFAE               $C000-$DFFF
MMU_SLOT_7     equ       $FFAF               $E000-$FFFF

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
INT_PENDING_0  equ       $FE20
INT_POLARITY_0 equ       $FE24
INT_EDGE_0     equ       $FE28
INT_MASK_0     equ       $FE2C

INT_PENDING_1  equ       $FE21
INT_POLARITY_1 equ       $FE25
INT_EDGE_1     equ       $FE29
INT_MASK_1     equ       $FE2D

INT_PENDING_2  equ       $FE22               Not used
INT_POLARITY_2 equ       $FE26               Not used
INT_EDGE_2     equ       $FE2A               Not used
INT_MASK_2     equ       $FE2E               Not used

INT_PENDING_3  equ       $FE23               Not used
INT_POLARITY_3 equ       $FE27               Not used
INT_EDGE_3     equ       $FE2B               Not used
INT_MASK_3     equ       $FE2F               Not used

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
* FNX6809 Keyboard Definitions
*
PS2_CTRL       equ       $FE50
PS2_OUT        equ       $FE51
KBD_IN         equ       $FE52
MS_IN          equ       $FE53
PS2_STAT       equ       $FE54

MCLR           equ       %00100000
KCLR           equ       %00010000
M_WR           equ       %00001000
K_WR           equ       %00000010

K_AK           equ       %10000000
K_NK           equ       %01000000
M_AK           equ       %00100000
M_NK           equ       %00010000
MEMP           equ       %00000010
KEMP           equ       %00000001

********************************************************************
* FNX6809 Timer Definitions
*
* Timer Addresses
T0_CTR         equ       $FE30               Timer 0 Counter (Write)
T0_STAT        equ       $FE30               Timer 0 Status (Read)
T0_VAL         equ       $FE31               Timer 0 Value (Read/Write)
T0_CMP_CTR     equ       $FE34               Timer 0 Compare Counter (Read/Write)
T0_CMP         equ       $FE35               Timer 0 Compare Value (Read/Write)
T1_CTR         equ       $FE38               Timer 1 Counter (Write)
T1_STAT        equ       $FE38               Timer 1 Status (Read)
T1_VAL         equ       $FE39               Timer 1 Value (Read/Write)
T1_CMP_CTR     equ       $FE3C               Timer 1 Compare Counter (Read/Write)
T1_CMP         equ       $FE3D               Timer 1 Compare Value (Read/Write)

********************************************************************
* FNX6809 VIA Definitions
*
* VIA Addresses
IORB           equ       $FFB0               Port B Data
IORA           equ       $FFB1               Port A Data
DDRB           equ       $FFB2               Port B Data Direction Register
DDRA           equ       $FFB3               Port A Data Direction Register
T1C_L          equ       $FFB4               Timer 1 Counter Low
T1C_H          equ       $FFB5               Timer 1 Counter High
T1L_L          equ       $FFB6               Timer 1 Latch Low
T1L_H          equ       $FFB7               Timer 1 Latch High
T2C_L          equ       $FFB8               Timer 2 Counter Low
T2C_H          equ       $FFB9               Timer 2 Counter High
SDR            equ       $FFBA               Serial Data Register
ACR            equ       $FFBB               Auxiliary Control Register
PCR            equ       $FFBC               Peripheral Control Register
IFR            equ       $FFBD               Interrupt Flag Register
IER            equ       $FFBE               Interrupt Enable Register
IORA2          equ       $FFBF               Port A Data (no handshake)

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
* Text lookup definitions
*
TEXT_LUT_FG      equ $FF00
TEXT_LUT_BG      equ $FF40


********************************************************************
* FNX6809 SD Card Interface Definitions
*
SDC_STAT       equ       $FE90
SDC_DATA       equ       $FE91

SPI_BUSY       equ       %10000000
SPI_CLK        equ       %00000010
CS_EN          equ       %00000001

MASTER_CTRL_REG_L equ       $FFC0
;Control Bits Fields
Mstr_Ctrl_Text_Mode_En equ       $01                 ; Enable the Text Mode
Mstr_Ctrl_Text_Overlay equ       $02                 ; Enable the Overlay of the text mode on top of Graphic Mode (the Background Color is ignored)
Mstr_Ctrl_Graph_Mode_En equ       $04                 ; Enable the Graphic Mode
Mstr_Ctrl_Bitmap_En equ       $08                 ; Enable the Bitmap Module In Vicky
Mstr_Ctrl_TileMap_En equ       $10                 ; Enable the Tile Module in Vicky
Mstr_Ctrl_Sprite_En equ       $20                 ; Enable the Sprite Module in Vicky
Mstr_Ctrl_GAMMA_En equ       $40                 ; this Enable the GAMMA correction - The Analog and DVI have different color value, the GAMMA is great to correct the difference
Mstr_Ctrl_Disable_Vid equ       $80                 ; This will disable the Scanning of the Video hence giving 100% bandwith to the CPU
MASTER_CTRL_REG_H equ       $FFC1
; Reserved - TBD
VKY_RESERVED_00 equ       $FFC2
VKY_RESERVED_01 equ       $FFC3
;
BORDER_CTRL_REG equ       $FFC4               ; Bit[0] - Enable (1 by default)  Bit[4..6]: X Scroll Offset ( Will scroll Left) (Acceptable Value: 0..7)
Border_Ctrl_Enable equ       $01
BORDER_COLOR_B equ       $FFC5
BORDER_COLOR_G equ       $FFC6
BORDER_COLOR_R equ       $FFC7
BORDER_X_SIZE  equ       $FFC8               X-  Values: 0 - 32 (Default: 32)
BORDER_Y_SIZE  equ       $FFC9               Y- Values 0 -32 (Default: 32)
; Reserved - TBD
VKY_RESERVED_02 equ       $FFCA
VKY_RESERVED_03 equ       $FFCB
VKY_RESERVED_04 equ       $FFCC
; Valid in Graphics Mode Only
BACKGROUND_COLOR_B equ       $FFCD               ; When in Graphic Mode, if a pixel is "0" then the Background pixel is chosen
BACKGROUND_COLOR_G equ       $FFCE
BACKGROUND_COLOR_R equ       $FFCF               ;
; Cursor Registers
VKY_TXT_CURSOR_CTRL_REG equ       $FFD0               ;[0]  Enable Text Mode
Vky_Cursor_Enable equ       $01
Vky_Cursor_Flash_Rate0 equ       $02
Vky_Cursor_Flash_Rate1 equ       $04
Vky_Cursor_Flash_Disable equ       $08
VKY_TXT_START_ADD_PTR equ       $FFD1               ; This is an offset to change the Starting address of the Text Mode Buffer (in x)
VKY_TXT_CURSOR_CHAR_REG equ       $FFD2
VKY_TXT_CURSOR_COLR_REG equ       $FFD3
VKY_TXT_CURSOR_X_REG_L equ       $FFD4
VKY_TXT_CURSOR_X_REG_H equ       $FFD5
VKY_TXT_CURSOR_Y_REG_L equ       $FFD6
VKY_TXT_CURSOR_Y_REG_H equ       $FFD7
; Line Interrupt
VKY_LINE_IRQ_CTRL_REG equ       $FFD8               ;[0] - Enable Line 0 - WRITE ONLY
VKY_LINE_CMP_VALUE_LO equ       $FFD9               ;Write Only [7:0]
VKY_LINE_CMP_VALUE_HI equ       $FFDA               ;Write Only [3:0]

VKY_PIXEL_X_POS_LO equ       $FFD8               ; This is Where on the video line is the Pixel
VKY_PIXEL_X_POS_HI equ       $FFD9               ; Or what pixel is being displayed when the register is read
VKY_LINE_Y_POS_LO equ       $FFDA               ; This is the Line Value of the Raster
VKY_LINE_Y_POS_HI equ       $FFDB               ;

; Bitmap
; in the FNX6809 New Implementation, these Register are in the Page $C0
; So for now, I will bring page $C0 in Slot 7
;BM0
TyVKY_BM0_CTRL_REG equ       $F000
BM0_Ctrl       equ       $01                 ; Enable the BM0
BM0_LUT0       equ       $02                 ; LUT0
BM0_LUT1       equ       $04                 ; LUT1
TyVKY_BM0_START_ADDY_L equ       $F001
TyVKY_BM0_START_ADDY_M equ       $F002
TyVKY_BM0_START_ADDY_H equ       $F003
;BM1
TyVKY_BM1_CTRL_REG equ       $F008
BM1_Ctrl       equ       $01                 ; Enable the BM0
BM1_LUT0       equ       $02                 ; LUT0
BM1_LUT1       equ       $04                 ; LUT1
TyVKY_BM1_START_ADDY_L equ       $F009
TyVKY_BM1_START_ADDY_M equ       $F00A
TyVKY_BM1_START_ADDY_H equ       $F00B
;BM2
TyVKY_BM2_CTRL_REG equ       $F010
BM2_Ctrl       equ       $01                 ; Enable the BM0
BM2_LUT0       equ       $02                 ; LUT0
BM2_LUT1       equ       $04                 ; LUT1
BM2_LUT2       equ       $08                 ; LUT2
TyVKY_BM2_START_ADDY_L equ       $F011
TyVKY_BM2_START_ADDY_M equ       $F012
TyVKY_BM2_START_ADDY_H equ       $F013


; Tile Map
TyVKY_TL_CTRL0 equ       $F100
; Bit Field Definition for the Control Register
TILE_Enable    equ       $01
TILE_LUT0      equ       $02
TILE_LUT1      equ       $04
TILE_LUT2      equ       $08
TILE_SIZE      equ       $10                 ; 0 -> 16x16, 0 -> 8x8

;
;Tile MAP Layer 0 Registers
TL0_CONTROL_REG equ       $F100               ; Bit[0] - Enable, Bit[3:1] - LUT Select,
TL0_START_ADDY_L equ       $F101               ; Not USed right now - Starting Address to where is the MAP
TL0_START_ADDY_M equ       $F102
TL0_START_ADDY_H equ       $F103
TL0_MAP_X_SIZE_L equ       $F104               ; The Size X of the Map
TL0_MAP_X_SIZE_H equ       $F105
TL0_MAP_Y_SIZE_L equ       $F106               ; The Size Y of the Map
TL0_MAP_Y_SIZE_H equ       $F107
TL0_MAP_X_POS_L equ       $F108               ; The Position X of the Map
TL0_MAP_X_POS_H equ       $F109
TL0_MAP_Y_POS_L equ       $F10A               ; The Position Y of the Map
TL0_MAP_Y_POS_H equ       $F10B
;Tile MAP Layer 1 Registers
TL1_CONTROL_REG equ       $F10C               ; Bit[0] - Enable, Bit[3:1] - LUT Select,
TL1_START_ADDY_L equ       $F10D               ; Not USed right now - Starting Address to where is the MAP
TL1_START_ADDY_M equ       $F10E
TL1_START_ADDY_H equ       $F10F
TL1_MAP_X_SIZE_L equ       $F110               ; The Size X of the Map
TL1_MAP_X_SIZE_H equ       $F111
TL1_MAP_Y_SIZE_L equ       $F112               ; The Size Y of the Map
TL1_MAP_Y_SIZE_H equ       $F113
TL1_MAP_X_POS_L equ       $F114               ; The Position X of the Map
TL1_MAP_X_POS_H equ       $F115
TL1_MAP_Y_POS_L equ       $F116               ; The Position Y of the Map
TL1_MAP_Y_POS_H equ       $F117
;Tile MAP Layer 2 Registers
TL2_CONTROL_REG equ       $F118               ; Bit[0] - Enable, Bit[3:1] - LUT Select,
TL2_START_ADDY_L equ       $F119               ; Not USed right now - Starting Address to where is the MAP
TL2_START_ADDY_M equ       $F11A
TL2_START_ADDY_H equ       $F11B
TL2_MAP_X_SIZE_L equ       $F11C               ; The Size X of the Map
TL2_MAP_X_SIZE_H equ       $F11D
TL2_MAP_Y_SIZE_L equ       $F11E               ; The Size Y of the Map
TL2_MAP_Y_SIZE_H equ       $F11F
TL2_MAP_X_POS_L equ       $F120               ; The Position X of the Map
TL2_MAP_X_POS_H equ       $F121
TL2_MAP_Y_POS_L equ       $F122               ; The Position Y of the Map
TL2_MAP_Y_POS_H equ       $F123


TILE_MAP_ADDY0_L equ       $F180
TILE_MAP_ADDY0_M equ       $F181
TILE_MAP_ADDY0_H equ       $F182
TILE_MAP_ADDY0_CFG equ       $F183
TILE_MAP_ADDY1 equ       $F184
TILE_MAP_ADDY2 equ       $F188
TILE_MAP_ADDY3 equ       $F18C
TILE_MAP_ADDY4 equ       $F190
TILE_MAP_ADDY5 equ       $F194
TILE_MAP_ADDY6 equ       $F198
TILE_MAP_ADDY7 equ       $F19C


XYMATH_CTRL_REG equ       $D300               ; Reserved
XYMATH_ADDY_L  equ       $D301               ; W
XYMATH_ADDY_M  equ       $D302               ; W
XYMATH_ADDY_H  equ       $D303               ; W
XYMATH_ADDY_POSX_L equ       $D304               ; R/W
XYMATH_ADDY_POSX_H equ       $D305               ; R/W
XYMATH_ADDY_POSY_L equ       $D306               ; R/W
XYMATH_ADDY_POSY_H equ       $D307               ; R/W
XYMATH_BLOCK_OFF_L equ       $D308               ; R Only - Low Block Offset
XYMATH_BLOCK_OFF_H equ       $D309               ; R Only - Hi Block Offset
XYMATH_MMU_BLOCK equ       $D30A               ; R Only - Which MMU Block
XYMATH_ABS_ADDY_L equ       $D30B               ; Low Absolute Results
XYMATH_ABS_ADDY_M equ       $D30C               ; Mid Absolute Results
XYMATH_ABS_ADDY_H equ       $D30D               ; Hi Absolute Results

; Sprite Block0
SPRITE_Ctrl_Enable equ       $01
SPRITE_LUT0    equ       $02
SPRITE_LUT1    equ       $04
SPRITE_DEPTH0  equ       $08                 ; 00 = Total Front - 01 = In between L0 and L1, 10 = In between L1 and L2, 11 = Total Back
SPRITE_DEPTH1  equ       $10
SPRITE_SIZE0   equ       $20                 ; 00 = 32x32 - 01 = 24x24 - 10 = 16x16 - 11 = 8x8
SPRITE_SIZE1   equ       $40


SP0_Ctrl       equ       $F300
SP0_Addy_L     equ       $F301
SP0_Addy_M     equ       $F302
SP0_Addy_H     equ       $F303
SP0_X_L        equ       $F304
SP0_X_H        equ       $F305
SP0_Y_L        equ       $F306               ; In the Jr, only the L is used (200 & 240)
SP0_Y_H        equ       $F307               ; Always Keep @ Zero '0' because in Vicky the value is still considered a 16bits value

SP1_Ctrl       equ       $F308
SP1_Addy_L     equ       $F309
SP1_Addy_M     equ       $F30A
SP1_Addy_H     equ       $F30B
SP1_X_L        equ       $F30C
SP1_X_H        equ       $F30D
SP1_Y_L        equ       $F30E               ; In the Jr, only the L is used (200 & 240)
SP1_Y_H        equ       $F30F               ; Always Keep @ Zero '0' because in Vicky the value is still considered a 16bits value

SP2_Ctrl       equ       $F310
SP2_Addy_L     equ       $F311
SP2_Addy_M     equ       $F312
SP2_Addy_H     equ       $F313
SP2_X_L        equ       $F314
SP2_X_H        equ       $F315
SP2_Y_L        equ       $F316               ; In the Jr, only the L is used (200 & 240)
SP2_Y_H        equ       $F317               ; Always Keep @ Zero '0' because in Vicky the value is still considered a 16bits value

SP3_Ctrl       equ       $F318
SP3_Addy_L     equ       $F319
SP3_Addy_M     equ       $F31A
SP3_Addy_H     equ       $F31B
SP3_X_L        equ       $F31C
SP3_X_H        equ       $F31D
SP3_Y_L        equ       $F31E               ; In the Jr, only the L is used (200 & 240)
SP3_Y_H        equ       $F31F               ; Always Keep @ Zero '0' because in Vicky the value is still considered a 16bits value

SP4_Ctrl       equ       $F320
SP4_Addy_L     equ       $F321
SP4_Addy_M     equ       $F322
SP4_Addy_H     equ       $F323
SP4_X_L        equ       $F324
SP4_X_H        equ       $F325
SP4_Y_L        equ       $F326               ; In the Jr, only the L is used (200 & 240)
SP4_Y_H        equ       $F327               ; Always Keep @ Zero '0' because in Vicky the value is still considered a 16bits value




; PAGE $C1
TyVKY_LUT0     equ       $E800               ; -$D000 - $D3FF
TyVKY_LUT1     equ       $EC00               ; -$D400 - $D7FF
TyVKY_LUT2     equ       $F000               ; -$D800 - $DBFF
TyVKY_LUT3     equ       $F400               ; -$DC00 - $DFFF


;DMA
DMA_CTRL_REG   equ       $FEE0
DMA_CTRL_Enable equ       $01
DMA_CTRL_1D_2D equ       $02
DMA_CTRL_Fill  equ       $04
DMA_CTRL_Int_En equ       $08
DMA_CTRL_NotUsed0 equ       $10
DMA_CTRL_NotUsed1 equ       $20
DMA_CTRL_NotUsed2 equ       $40
DMA_CTRL_Start_Trf equ       $80

DMA_DATA_2_WRITE equ       $FEE1               ; Write Only
DMA_STATUS_REG equ       $FEE1               ; Read Only
DMA_STATUS_TRF_IP equ       $80                 ; Transfer in Progress
DMA_RESERVED_0 equ       $FEE2
DMA_RESERVED_1 equ       $FEE3

; Source Addy
DMA_SOURCE_ADDY_L equ       $FEE4
DMA_SOURCE_ADDY_M equ       $FEE5
DMA_SOURCE_ADDY_H equ       $FEE6
DMA_RESERVED_2 equ       $FEE7
; Destination Addy
DMA_DEST_ADDY_L equ       $FEE8
DMA_DEST_ADDY_M equ       $FEE9
DMA_DEST_ADDY_H equ       $FEEA
DMA_RESERVED_3 equ       $FEEB
; Size in 1D Mode
DMA_SIZE_1D_L  equ       $FEEC
DMA_SIZE_1D_M  equ       $FEED
DMA_SIZE_1D_H  equ       $FEEE
DMA_RESERVED_4 equ       $FEEF
; Size in 2D Mode
DMA_SIZE_X_L   equ       $FEEC
DMA_SIZE_X_H   equ       $FEED
DMA_SIZE_Y_L   equ       $FEEE
DMA_SIZE_Y_H   equ       $FEEF
; Stride in 2D Mode
DMA_SRC_STRIDE_X_L equ       $FEF0
DMA_SRC_STRIDE_X_H equ       $FEF1
DMA_DST_STRIDE_Y_L equ       $FEF2
DMA_DST_STRIDE_Y_H equ       $FEF3

DMA_RESERVED_5 equ       $FEF4
DMA_RESERVED_6 equ       $FEF5
DMA_RESERVED_7 equ       $FEF6
DMA_RESERVED_8 equ       $FEF7
               ENDC
*******************************************************************************
* TurbOS
*******************************************************************************
* See LICENSE.txt for licensing information.
********************************************************************
*
* $Id$
*
* Edt/Rev  YYYY/MM/DD  Modified by
* Comment
* ------------------------------------------------------------------
*   1      2023/08/29  BGP
* Created.

               nam       go
               ttl       Very simple initial program

               use       defsfile

tylg           set       Prgrm+Objct
atrv           set       ReEnt+rev
rev            set       $01
edition        set       1

               mod       eom,name,tylg,atrv,start,size

               org       0
stack          rmb       200
size           equ       .

name           fcs       /go/
               fcb       edition

* This is an F256 Jr. specific program that sets up the screen and puts a
* simple message on the screen.
start

* Initialize display
               pshs      cc
               orcc      #IntMasks
               clr       >MMU_IO_CTRL

               lda       #MCTXM_ENABLE
               ora       #MCG_ENABLE
               sta       MCTRL_REG_L
               clr       MCTRL_REG_H

               clr       BORDER_CTRL_REG
               clr       BORDER_COLOR_R
               clr       BORDER_COLOR_G
               clr       BORDER_COLOR_B

               clr       VKY_TXT_CURSOR_CTRL_REG

* Initialize gamma
               ldd       #0
x1@            tfr       d,x
               stb       $c000,x
               stb       $c400,x
               stb       $c800,x
               incb
               bne       x1@

* Initialize palette.
               leax      palette,pcr
               ldy       #TEXT_LUT_FG
               bsr       copypal

               leax      palette,pcr
               ldy       #TEXT_LUT_BG
               bsr       copypal

* Install font.
               lda       #1
               sta       >MMU_IO_CTRL
               leax      font,pcr
               ldy       #$C000+(8*20)
loop@          ldd       ,x++
               std       ,y++
               cmpy      #$C000+2048
               bne       loop@

* Setup foreground/background character LUT values.
               ldb       #3
               stb       >MMU_IO_CTRL
               ldd       #$10*256+$10
               bsr       clr
               ldb       #2
               stb       >MMU_IO_CTRL
               ldd       #$20*256+$20

               lda       #Prgrm+Objct
               ldb       #$01
               leax      go2,pcr
               ldy       #$0000
               os9       F$Fork

               os9       F$Wait
forever@
               bra       forever@

go2            fcs       /go2/

* Clear screen memory.
clr            ldx       #$C000
loop@          std       ,x++
               cmpx      #$C000+80*61
               bne       loop@
               rts

copypal        ldu       #64
loop@          ldd       ,x++
               std       ,y++
               ldd       ,x++
               std       ,y++
               leau      -4,u
               cmpu      #0000
               bne       loop@
               rts

palette        fcb       $00,$00,$00,$00
               fcb       $ff,$ff,$ff,$00
               fcb       $00,$00,$88,$00
               fcb       $ee,$ff,$aa,$00
               fcb       $cc,$4c,$cc,$00
               fcb       $55,$cc,$00,$00
               fcb       $aa,$00,$00,$00
               fcb       $77,$dd,$dd,$00
               fcb       $55,$88,$dd,$00
               fcb       $00,$44,$66,$00
               fcb       $77,$77,$ff,$00
               fcb       $33,$33,$33,$00
               fcb       $77,$77,$77,$00
               fcb       $66,$ff,$aa,$00
               fcb       $ff,$88,$00,$00
               fcb       $bb,$bb,$bb,$00

font
               use       "8x8.fcb"

               emod
eom            equ       *
               end


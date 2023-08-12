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

* Initialize palette
               leax      palette,pcr
               ldy       #TEXT_LUT_FG
               ldu       #64
loop@          ldd       ,x++
               std       ,y++
               ldd       ,x++
               std       ,y++
               leau      -4,u
               bne       loop@

               leax      palette+64,pcr
               ldy       #TEXT_LUT_BG
               ldu       #64
loop@          ldd       ,--x
               std       ,y++
               ldd       ,--x
               std       ,y++
               leau      -4,u
               bne       loop@

* Install font
               lda       #1
               sta       >MMU_IO_CTRL
               leax      font,pcr
               ldy       #$C000+(8*20)
loop@          ldd       ,x++
               std       ,y++
               cmpy      #$C000+2048
               bne       loop@

               ldb       #3
               stb       >MMU_IO_CTRL
               lda       #$10

               tfr       a,b
               ldx       #$c000
loop@          std       ,x++
               cmpx      #$c000+80*61
               bne       loop@

               ldb       #2                  ; text
               stb       >MMU_IO_CTRL


* Clear screen memory
               ldy       #G.ScrEnd
               pshs      y
               ldy       #G.ScrStart
               ldd       #C$SPACE*256+C$SPACE
loop@          std       ,y++
               cmpy      ,s
               bne       loop@
               puls      u

               lda       #Prgrm+Objct
               ldb       #$01
               leax      go2,pcr
               ldy       #$0000
               os9       F$Fork
               
               os9       F$Wait
forever@                 
               bra       forever@

go2            fcs       /go2/

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


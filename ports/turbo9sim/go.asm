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

               use       defs.d

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

start          equ       *

               lda       #'O
               sta       $FF00
               lda       #'K
               sta       $FF00
               leax      name,pcr
               ldy       #2
               lda       #1
               os9       I$Write
loop@          ldx       #10
               os9       F$Sleep
               bra       start

               emod
eom            equ       *
               end


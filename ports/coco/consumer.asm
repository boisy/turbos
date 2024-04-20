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

               nam       consumer
               ttl       consumption program

               use       defs.d

tylg           set       Prgrm+Objct
atrv           set       ReEnt+rev
rev            set       $01
edition        set       1

               mod       eom,name,tylg,atrv,start,size

               org       0
stack          rmb       200
size           equ       .

name           fcs       /consumer/
               fcb       edition

start                    

loop@
               ldx       #10                 we want to sleep for...
               os9       F$Sleep             10 ticks
*               inc       $401                increment the second VDG character
               ldx       #10                 we want to sleep for...
               os9       F$Sleep             10 ticks
               bra       loop@               and just keep doing it


               emod      
eom            equ       *
               end       


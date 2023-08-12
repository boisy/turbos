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

* This is a CoCo-specific program that prints a few characters onto the VDG
* screen area of the CoCo. This program assumes that TurbOS is loaded from
* Disk BASIC, which locates the VDG screen at $400. It's meant to demonstrate
* that the kernel is functioning and works.
*
* Note, that $400-$4FF is the kernel's stack area. We're safe in manipulating the
* first few characters at $400, but we don't really want to beyond a few bytes
* or else we'll run into live stack bytes.
start
loop           ldd       #'T*256+'U
               std       $400
               ldd       #'R*256+'B
               std       $402
               ldd       #'O*256+'S
               std       $404
               
_SLEEP_TIME    equ       TkPerSec

               ldx       #_SLEEP_TIME
               os9       F$Sleep

               ldd       #'R*256+'O
               std       $400
               ldd       #'C*256+'K
               std       $402
               ldd       #'S*256+'!
               std       $404
               
               ldx       #_SLEEP_TIME
               os9       F$Sleep
               bra       loop
               
               emod      
eom            equ       *
               end       


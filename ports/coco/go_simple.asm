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

* This is a CoCo-specific program that just tickles a few characters in the VDG
* screen area of the CoCo. This program assumes that TurbOS was loaded from
* Disk BASIC, which locates the VDG screen at $400. It's meant to demonstrate
* that the kernel is functioning and multitasking works.
*
* Note, that $400-$4FF is the kernel's stack area. We're safe in manipulating the
* first few characters at $400, but we don't really want to beyond a few bytes
* or else we'll run into live stack bytes.
start                    

loop@          inc       $400                increment the first VDG character
               ldx       #10                 we want to sleep for...
               os9       F$Sleep             10 ticks
               inc       $401                increment the second VDG character
               ldx       #10                 we want to sleep for...
               os9       F$Sleep             10 ticks
               bra       loop@               and just keep doing it


               emod      
eom            equ       *
               end       


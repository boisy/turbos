********************************************************************
* scvt.asm - Virtual terminal
*
* $Id$
*
* Edt/Rev  YYYY/MM/DD  Modified by
* Comment
* ------------------------------------------------------------------
*  1       2025/02/02  Boisy G. Pitre
* Started.

                    use       defs.d
                    use       scf.d

tylg                set       Drivr+Objct
atrv                set       ReEnt+Rev
rev                 set       $00
edition             set       1

                    mod       eom,name,tylg,atrv,Start,Size

                    fcb       READ.+WRITE.

name                fcs       /scvt/
                    fcb       edition             one more revision level than the stock printer

* Device memory area: offset from U
                    org       V.SCF               V.SCF: free memory for driver to use
V.BUFF              rmb       $80                 room for 128 blocked processes
size                equ       .

start               equ       *
                    lbra      Init
                    lbra      Read
                    lbra      Write
                    lbra      GetStt
                    lbra      SetStt

* Term
*
* Entry:
*    U  = address of device memory area
*
* Exit:
*    CC = carry set on error
*    B  = error code
*
Term                clrb
                    rts

* Init
*
* Entry:
*    Y  = address of device descriptor
*    U  = address of device memory area
*
* Exit:
*    CC = carry set on error
*    B  = error code
*
Init                clrb
                    rts


* Read
*
* Entry:
*    Y  = address of path descriptor
*    U  = address of device memory area
*
* Exit:
*    A  = character read
*    CC = carry set on error
*    B  = error code
*
Read                clrb
                    rts

* Write
*
* Entry:
*    A  = character to write
*    Y  = address of path descriptor
*    U  = address of device memory area
*
* Exit:
*    CC = carry set on error
*    B  = error code
*
Write               sta     $FF00
                    clrb
                    rts


* GetStat
*
* Entry:
*    A  = function code
*    Y  = address of path descriptor
*    U  = address of device memory area
*
* Exit:
*    CC = carry set on error
*    B  = error code
*
GetStt              clrb                          if so, exit with no error
                    rts

* SetStat
*
* Entry:
*    A  = function code
*    Y  = address of path descriptor
*    U  = address of device memory area
*
* Exit:
*    CC = carry set on error
*    B  = error code
*
SetStt              clrb
                    rts
                    
                    emod
eom                 equ       *
                    end

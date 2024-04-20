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
screenstart    rmb       2                   the address of the start of the 32x16 screen
screenend      rmb       2                   the address of the end of the 32x16 screen
nextcharpos    rmb       2                   the address of the next character location
stack          rmb       200
size           equ       .

name           fcs       /go/
               fcb       edition

* This is a CoCo-specific program that prints a few characters onto the VDG
* screen area of the CoCo. It's meant to demonstrate that the kernel is
* functioning and works.
*
* This program allocates 512 bytes for the 32x16 VDG screen and writes to that area.
start                    
               lbsr      VDGInit
               bcs       exit
               lbsr      ClearScreen
               lbsr      SetUpConsumer

_SLEEP_TIME    equ       TkPerSec/TkPerSec
*               leax      message,pcr   get pointer to message
*               bsr       VDGWrite       write it
*               ldx       screenstart,u
*               stx       nextcharpos,u
               leax      banner,pcr
               lbsr      VDGWrite
loop                     
               ldd       #(32*1)+16
               addd      screenstart,u
               std       nextcharpos,u
               ldd       >D.Ticks
               lbsr      PRINT_HEX_16
               ldd       >D.Ticks+2
               lbsr      PRINT_HEX_16
               leax      crt,pcr
               lbsr      VDGWrite
               ldd       #(32*2)+16
               addd      screenstart,u
               std       nextcharpos,u
               ldb       >D.SLICE
               lbsr      PRINT_HEX_8

               leax      crt,pcr
               lbsr      VDGWrite
               ldd       #(32*3)+16
               addd      screenstart,u
               std       nextcharpos,u
               ldd       >D.AProcQ
               lbsr      PRINT_HEX_16

               leax      crt,pcr
               lbsr      VDGWrite
               ldd       #(32*4)+16
               addd      screenstart,u
               std       nextcharpos,u
               ldd       >D.SProcQ
               lbsr      PRINT_HEX_16

               leax      crt,pcr
               lbsr      VDGWrite
               ldd       #(32*5)+16
               addd      screenstart,u
               std       nextcharpos,u
               ldd       >D.WProcQ
               lbsr      PRINT_HEX_16

               ldx       #_SLEEP_TIME        get sleep time
               os9       F$Sleep             and sleep for that amount   
               bra       loop

exit           os9       F$Exit

* Write to a VDG screen
* Entry: X = address of string to write
VDGWrite       ldy       nextcharpos,u
loop@          lda       ,x+
               beq       ex@
               cmpa      #$0D
               bne       fixchar@
               ldd       nextcharpos,u
               addd      #32
               andb      #%11100000
               cmpd      screenend,u
               bge       scroll@
               std       nextcharpos,u
               tfr       d,y
               bra       loop@
fixchar@       cmpa      #$40
               bcc       store@
               adda      #$40
store@         sta       ,y+
               cmpy      screenend,u         are we at last line?
               blt       loop@
truescroll     set       1
scroll@                  
               ifeq      truescroll
               ldy       screenstart,u
               sty       nextcharpos,u
               else      
               pshs      x,y
               ldy       #32*15
               ldx       screenstart,u
               leax      32,x
scrollloop@    ldd       ,x++
               std       -34,x
               leay      -2,y
               bne       scrollloop@
               stx       nextcharpos,u
               puls      x,y
               endc      
               bra       loop@
ex@            sty       nextcharpos,u
               rts       

* Initialize a 32x16 VDG screen.
VDGInit        pshs      u                   save the static memory pointer
               ldd       #512+256            allocate 32x16 VDG memory + 1 page to allow for 512 byte boundary
               os9       F$SRqMem            do it
               bcs       ex@                 we got the memory; figure out 512 byte boundary, return un-needed 256 bytes
good@          tfr       u,d                 copy the newly allocated memory pointer
               ldu       ,s                  restore the static memory pointer in U
               tfr       a,b                 move high 8 bits to lower
               bita      #$01                did we allocate on an odd page?
               beq       lastpage@           nope, so we will return last 256 byte page
               adda      #$01                else return even (SAM/VDG needs 512 byte boundaries for screens)
               bra       firstpage@          return the first 256 byte page to the mem pool
lastpage@      incb                          point to last 256 byte page (calwe will return to mem pool)
firstpage@     pshs      u,a                 save the static memory pointer and the screen high byte start memory pointer
               tfr       b,a                 move the high byte start memory pointer of 256 bytes we are returning
               clrb                          D = starting pointer of the page we are returning
               tfr       d,u                 setup the register for the system call
               ldd       #256                256 bytes to return
               os9       F$SRtMem            return the page
               puls      u,a                 restore regs
               bcs       exit                branch if error
               clrb                          clear lower 8 bits
               std       screenstart,u       save allocated screen memory
               std       nextcharpos,u       and set next character position to 0
               addd      #32*16              add 512 to set end of screen
               std       screenend,u         and set next character position to 0
               lda       screenstart,u       restore start of screen
* Set up VDG alpha mode screen for text
               ldx       #$FFC6              point to SAM to set up where to map
               stb       -6,x                $FFC0  Set up for 32x16 text screen
               stb       -4,x                $FFC2
               stb       -2,x                $FFC4
               ldb       #$07                7 SAM double-byte settings to do
               lsra                          put bit 0 into carry (ignore)
loop@          lsra                          put bit 0 into carry
               bcs       odd@                if bit set, store on odd byte
               sta       ,x++                bit clear, store on even byte (Faster (not important), smaller)
               bra       next@               do next bit
odd@           leax      1,x                 even byte, so increment X
               sta       ,x+                 tickle address
next@          decb                          done all 7 memory pairs?
               bne       loop@               no, keep going until done
               clrb      
ex@            puls      u,pc

ClearScreen              
               ldx       screenstart,u
               ldd       #(C$SPACE+$40)*256+(C$SPACE+$40)
loop@          std       ,x++
               cmpx      screenend,u
               bne       loop@
               rts       

SetUpConsumer  leax      consumer,pcr
               lda       #Prgrm+Objct
               clrb
               ldy       #1
               os9       F$Fork
               rts

consumer       fcs       "consumer"

*************************************
* Print 4 digit (16-bit) hex number.
*
* Entry:  D = value to print
*
* Exit:   B error code, if any
*        CC carry set if error
PRINT_HEX_16             
               pshs      b
               tfr       a,b
               bsr       PRINT_HEX_8
               ldb       ,s+
* bra PRINT_HEX_8

*************************************
 * Print 2 digit (8-bit) hex number.
 *
 * Entry:  B = value to print
 *
 * Exit:   B error code, if any
 *        CC carry set if error
PRINT_HEX_8              
               pshs      a,x
               leas      -3,s                buffer
               tfr       s,x
               lbsr      BIN_HEX_8           convert to hex
               lbsr      VDGWrite            print to standard out
               leas      3,s                 clean stack
               puls      a,x,pc              return with error in B

********************************************
*
* Binary to hexadecimal convertor
*
* This subroutine will convert the binary value in
* 'D' to a 4 digit hexadecimal ascii string.
*
* OTHER MODULES NEEDED: BIN2HEX
*
* ENTRY: D=value to convert
*        X=buffer for hex string-null terminated
*
* EXIT all registers (except CC) preserved.

bin_hex_16:
               pshs      d,x
               ldb       ,s
               lbsr      BIN2HEX             convert 1 byte
               std       ,x++
               ldb       1,s
               lbsr      BIN2HEX             convert 2nd byte
               std       ,x++
               clr       ,x                  term with null
               puls      d,x

bin_hex_8: 
               pshs      b,x
               ldb       ,s
               lbsr      BIN2HEX             convert 1 byte
               std       ,x++
               clr       ,x                  term with null
               puls      b,x

****************************************
* Convert hex byte to 2 hex digits
*
* OTHER MODULES REQUIRED: none
*
* ENTRY: B= value to convert
*
* EXIT: D=2 byte hex digits

BIN2HEX                  
               pshs      b
               lsrb                          get msn
               lsrb      
               lsrb      
               lsrb                          fall through to convert msn and return
               bsr       ToHex
               tfr       b,a                 1st digit in A
               puls      b                   get lsn
               andb      #%00001111          keep msn

ToHex                    
               addb      #'0                 convert to ascii
               cmpb      #'9
               bls       ToHex1
               addb      #7                  convert plus 9 to A..F
ToHex1                   
               rts       



banner         fcc       /TURBOS/
               fcb       $0D
               fcc       /D.TICKS/
               fcb       $0D
               fcc       /D.SLICE/
               fcb       $0D
               fcc       /D.APROCQ/
               fcb       $0D
               fcc       /D.SPROCQ/
               fcb       $0D
               fcc       /D.WPROCQ/
crt            fcb       $0D,$00

message                  
line1          fcc       /--------------------------------/
line2          fcc       /--------------------------------/
line3          fcc       /--------------------------------/
line4          fcc       /--------------------------------/
line5          fcc       /-------------TURBOS-------------/
line6          fcc       /--------------------------------/
line7          fcc       /--------------------------------/
line8          fcc       /--------------------------------/
line9          fcc       /--------------------------------/
line10         fcc       /--------------------------------/
line11         fcc       /--------------------------------/
line12         fcc       /--------------------------------/
line13         fcc       /--------------------------------/
line14         fcc       /--------------------------------/
line15         fcc       /--------------------------------/
line16         fcc       /--------------------------------/
               fcb       $00

               emod      
eom            equ       *
               end       


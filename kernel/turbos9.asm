*******************************************************************************
*                                  TurbOS9                                    *
*******************************************************************************
* Website: www.turbos9.org                                                    *
* Contact: team[at]turbos9[dot]org                                            *
*******************************************************************************
* BSD-1-Clause                                                                *
*                                                                             *
* Copyright (c) 2023                                                          *
* Boisy Pitre                                                                 *
* All rights reserved.                                                        *
*                                                                             *
* Redistribution and use in source and binary forms, with or without          *
* modification, are permitted provided that the following conditions are met: *
*                                                                             *
* 1. Redistributions of source code must retain the above copyright notice,   *
*    this list of conditions and the following disclaimer.                    *
*                                                                             *
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" *
* AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE   *
* IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE  *
* ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS AND CONTRIBUTORS BE *
* LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR         *
* CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF        *
* SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS    *
* INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN     *
* CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)     *
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE  *
* POSSIBILITY OF SUCH DAMAGE.                                                 *
*******************************************************************************
*                                                                             *
* Edt/Rev  YYYY/MM/DD  Modified by                                            *
* Comment                                                                     *
* ----------------------------------------------------------------------------*
*          2023/08/11  Boisy Pitre
* Initial creation.
*
* $Id$
*
* This is how the memory map looks after the kernel has initialized:
*
*     $0000----> ================================== 
*               |                                  |
*               |                                  |
*  $0020-$0111  |  System Globals (D.FMBM-D.XNMI)  |
*               |                                  |
*               |                                  |
*     $0200---->|==================================|
*               |        Free Memory Bitmap        |
*  $0200-$021F  |     (1 bit = 256 byte page)      |
*               |----------------------------------|
*  $0220-$0221  |      IOMan I/O Call Pointer      |
*               |----------------------------------|
*               |      System Dispatch Table       |
*  $0222-$0291  |     (Room for 56 addresses)      |
*               |----------------------------------|
*  $0292-$02FF  |       User Dispatch Table        |
*               |     (Room for 56 addresses)      |
*     $0300---->|==================================|
*               |                                  |
*               |                                  |
*  $0300-$03FF  |     Module Directory Entries     |
*               |      (Room for 64 entries)       |
*               |                                  |
*     $0400---->|==================================|
*               |                                  |
*  $0400-$04FF  |           System Stack           |
*               |                                  |
*     $0500---->|==================================|
*

               nam       TurbOS9
               ttl       TurbOS9 Kernel

               use       defsfile

tylg           set       Systm+Objct
atrv           set       ReEnt+rev
rev            set       $00
edition        set       16

ModTop         mod       eom,name,tylg,atrv,ColdStart,size

size           equ       .

name           fcs       /TurbOS9/
               fcb       edition

**************************
* Kernel entry point
*
ColdStart      equ       *
* Clear out system globals from $0000-$0400.
               ldx       #D.FMBM             get start of free memory bitmap in X
               ldy       #$400-D.FMBM        get top of area to clear in Y (counter)
               clra                          clear A
               clrb                          clear B (D now $0000)
clear@         std       ,x++                save off at X and increment
               leay      -2,y                decrement counter
               bne       clear@              continue if not zero

* Set up system globals
               inca                          D = $100
               inca                          D = $200
               std       <D.FMBM             $200 = start of free memory bitmap
               addb      #$20                D = $220
               std       <D.FMBM+2           $220 = end of free memory bitmap
               addb      #$02                D = $222
               std       <D.SysDis           $222 = addr of sys dispatch tbl
               addb      #$70                D = $292
               std       <D.UsrDis           $292 = addr of usr dispatch tbl
               clrb                          D = $200
               inca                          D = $300
               std       <D.ModDir           $300 = mod dir start
               stx       <D.ModDir+2         X = $400 = mod dir end
               leas      >$0100,x            S = $500 (system stack)

* This routine checks for RAM by writing a pattern at an address
* then reading it back for validation. It may not be needed, so it's
* conditionalized.
               ifne      CHECK_FOR_VALID_RAM
ChkRAM         leay      ,x                  point Y to X ($400)
               ldd       ,y                  store org contents in D
               ldx       #$00FF              set X to pattern to write
               stx       ,y                  write pattern to ,Y
               cmpx      ,y                  same as what we wrote?
               bne       EndOfRAM@           nope, not RAM here!
               ldx       #$FF00              try different pattern
               stx       ,y                  write it to ,Y
               cmpx      ,y                  same as what we wrote?
               bne       EndOfRAM@           nope, not RAM here!
               std       ,y                  else restore org contents
               leax      >$0100,y            check top of next 256 block
               cmpx      #Bt.Start           stop short of boot track mem
               bcs       ChkRAM              branch if not done
               leay      ,x                  point Y to X (end of RAM)
EndOfRAM@      leax      ,y                  X = end of RAM
               else      
               ldx       #Bt.Start           point X to end of RAM
               endc      
               stx       <D.MLIM             save off memory limit

* Copy vector code over to D.XSWI3 ($0100).
               pshs      x                   save off X
               leax      >VectCode,pcr       point X to vector code
               ldy       #D.XSWI3            point Y to vector base in low RAM
               ldb       #VectCSz            get size of vector code in B
copy@          lda       ,x+                 get source byte
               sta       ,y+                 save in destination
               decb                          decrement counter
               bne       copy@               branch if not done
               puls      x                   restore X
               ldy       #Bt.Start+Bt.Size   get area after boot in Y
               lbsr      ValMods             validate modules there

* Copy vectors to system globals.
               leay      >Vectors,pcr        point Y to vectors
               leax      >ModTop,pcr         point X to top of the kernel
               pshs      x                   save off
               ldx       #D.SWI3             point X to vectors in system globals
copy@          ldd       ,y++                get vector bytes
               addd      ,s                  add the kernel's module address
               std       ,x++                save off in system globals
               cmpx      #D.NMI              at the end?
               bls       copy@               branch if not
               leas      2,s                 restore stack

* Fill in more system globals.
               leax      >URtoSs,pcr         get address of user to system state routine
               stx       <D.URtoSs           store it in system globals
               leax      >UsrIRQ,pcr         get user state IRQ routine
               stx       <D.UsrIRQ           store it in system globals
               leax      >UsrSvc,pcr         get the user state service routine
               stx       <D.UsrSvc           store it in system globals
               leax      >SysIRQ,pcr         get the system state IRQ routine
               stx       <D.SysIRQ           store it in system globals
               stx       <D.SvcIRQ
               leax      >SysSvc,pcr         get the system state service routine      
               stx       <D.SysSvc           store it in system globals
               stx       <D.SWI2
               leax      >Poll,pcr           get the default polling routine
               stx       <D.Poll             store it in system globals
               leax      >Clock,pcr          get the default clock routine
               stx       <D.Clock            store it in system globals

* Install system calls.
               leay      >SysTbl,pcr         get the system call table address
               lbsr      InstSSvc            and install it

* Link to init module.
               lda       #Systm+0            we want a system module
               leax      >InitNam,pcr        point to the configuration module name
               os9       F$Link              link to it
               lbcs      ColdStart           if error, restart kernel
               stu       <D.Init             else store it in system globals
               lda       Feature1,u          get feature byte 1
               bita      #CRCOn              is CRC checking on?
               beq       SetupMap            branch if not (already cleared earlier)
               inc       <D.CRC              else turn on CRC checking

* Setup the free memory bitmap.
* This area of the kernel is highly platform-dependent.
*
* The free memory bitmap has the following structure:
*   bit 7 of 0,x corresponds to page 0, bit 6 to page 1 etc.
*   bit 7 of 1,x corresponds to page 8, bit 6 to page 9 etc.
SetupMap       ldx       <D.FMBM             get free memory bitmap in X
               ldb       #%11111000          reserve $0009-$04FF
               stb       ,x                  mark that area in the bitmap as allocated

* Exclude high memory as defined (earlier) by D.MLIM
               clra                          A = 0
               ldb       <D.MLIM             B = upper byte of 16 bit memory limit
               negb                          negate B
               tfr       d,y                 transfer D to Y
               negb                          negate B
               lbsr      L065A               in included fallbit.asm

* Jump into krnp2 here
               leax      >P2Nam,pcr          point X to name of kernel part 2 module
               lda       #Systm+Objct        it should be System+Object code type/language
               os9       F$Link              link to it
               lbcs      ColdStart           branch out if error (catastrophic)
               jmp       ,y                  else jump to code entry point in part 2 module

SWI3           pshs      pc,x,b              save off registers
               ldb       #P$SWI3             get P$SWI3
               bra       FixSWI              save it off in process descriptor
SWI2           pshs      pc,x,b              save off registers again
               ldb       #P$SWI2             get P$SWI2
               bra       FixSWI              save it off in process descriptor
SVCNMI         jmp       [>D.NMI]            jump to address in D.NMI       
DUMMY          rti                           return from interrupt
SVCIRQ         jmp       [>D.SvcIRQ]         jump to service IRQ address
SWI            pshs      pc,x,b              save off registers
               ldb       #P$SWI              get P$SWI
FixSWI         ldx       >D.Proc             get process descriptor
               ldx       b,x                 get SWI entry
               stx       3,s                 put in PC on stack
               puls      pc,x,b

UsrIRQ         leay      <DoIRQPoll,pcr
* Transition from user to system state.
URtoSs         clra      
               tfr       a,dp                clear direct page
               ldx       <D.Proc             get current process desc
* Note that we are putting the system state service routine address into
* the D.SWI2 vector. If a system call is made while we are in system state,
* D.SWI2 will be vectored to the system state service routine vector.
               ldd       <D.SysSvc           get system state system call vector
               std       <D.SWI2             store in D.SWI2
* The same comment above applies to the IRQ service vector.
               ldd       <D.SysIRQ           get system IRQ vector
               std       <D.SvcIRQ           store in D.SvcIRQ
               leau      ,s                  point U to S
               stu       P$SP,x              and save in process P$SP
               lda       P$State,x           get state field in proc desc
               ora       #SysState           mark process to be in system state
               sta       P$State,x           store it
               jmp       ,y                  jump to ,y

DoIRQPoll                               jsr       [>D.Poll]           call vectored polling routine
               bcc       go@                 branch if carry clear
               ldb       ,s                  get the CC on the stack
               orb       #IRQMask            mask IRQs
               stb       ,s                  and save it back
go@            lbra      ActivateProc

SysIRQ         clra                          A = 0
               tfr       a,dp                set DP to 0
               jsr       [>D.Poll]           call the vectored IRQ polling routine
               bcc       ex@                 branch if carry is clear
               ldb       ,s                  get the CC on the stack
               orb       #IRQMask            mask IRQs
               stb       ,s                  and save it back
ex@            rti                           return from interrupt

Poll           comb      
               rts       

* Default clock routine
Clock          ldx       <D.SProcQ           get pointer to sleeping proc queue
               beq       decslice@           branch if no process sleeping
               lda       P$State,x           get state of that process
               bita      #TimSleep           timed sleep?
               beq       decslice@           branch if clear
               ldu       P$SP,x              else get process stack pointer
               ldd       R$X,u               get the value of the process X reg
               subd      #$0001              subtract one from it
               std       R$X,u               and store it back
               bne       decslice@           branch if not zero (still will sleep)
nextqentry@    ldu       P$Queue,x           get process current queue pointer
               bsr       L021A
               leax      ,u
               beq       saveit@
               lda       P$State,x           get process state byte
               bita      #TimSleep           bit set?
               beq       saveit@             branch if not
               ldu       P$SP,x              get process stack pointer
               ldd       R$X,u               then get process X register
               beq       nextqentry@         branch if zero
saveit@        stx       <D.SProcQ
decslice@      dec       <D.Slice            decrement slice
               bne       ClockRTI            if not 0, exit ISR
               lda       <D.TSlice           else get default time slice
               sta       <D.Slice            and save it as slice
               ldx       <D.Proc             get proc desc of current proc
               beq       ClockRTI            if none, exit ISR
               lda       P$State,x           get process state
               ora       #TimOut             set timeout bit
               sta       P$State,x           and store back
               bpl       gosys@              branch if not system state
ClockRTI       rti       
gosys@         leay      >ActivateProc,pcr   point Y to activate process routine
               bra       URtoSs              go to system state

               use       faproc.asm

* User-state system call entry point.
*
* All system calls made from user-state will go through this code.
UsrSvc         leay      <MakeSysCall,pcr    point Y to make system call routine
               orcc      #IntMasks           mask interrupts
               lbra      URtoSs              go to system state

MakeSysCall    andcc     #^IntMasks          unmask interrupts
               ldy       <D.UsrDis           get pointer to user system call dispatch table
               bsr       DoSysCall           go do the system call
ActivateProc   ldx       <D.Proc             get current proc desc
               beq       FNProc              branch to FNProc if none
               orcc      #IntMasks           mask interrupts
               ldb       P$State,x           get state value in proc desc
               andb      #^SysState          turn off system state flag
               stb       P$State,x           save state value
               bitb      #TimOut             timeout bit set?
               beq       CheckState          branch if not
               andb      #^TimOut            else turn off bit
               stb       P$State,x           in state value
               bsr       L021A
               bra       FNProc              next process

* System-state system call entry point.
SysSvc         clra                          A = 0
               tfr       a,dp                set direct page to 0
               leau      ,s                  point U to SP
               ldy       <D.SysDis           get system state dispatch table ptr
               bsr       DoSysCall           perform the system call
               rti                           return

* This is the common system call entry point for user and system state.
*
* Entry: Y = Dispatch table (user or system)
*        U = Caller's register pointer
DoSysCall                
               pshs      u                   save off caller's register pointer
               ldx       R$PC,u              point X to PC
               ldb       ,x+                 get func code at X
               stx       R$PC,u              restore updated PC
               lslb                          high bit set?
               bcc       nonio@              branch if not (non I/O call)
               rorb                          else restore B (its an I/O call)
               ldx       -2,y                grab IOMan vector
* Note: should check if X is zero in case IOMan was not installed.
               bra       execcall@           make system call
nonio@         cmpb      #$37*2              non-IO call; are we in safe are?
               bcc       callerr@            branch if not (unknown service)
               ldx       b,y                 X = addr of system call
               beq       callerr@            if nil, unknown service
execcall@      jsr       ,x                  jsr into system call
callexit@      puls      u                   recover caller's registers
               tfr       cc,a                get CC into A
               bcc       FixCC               branch if no error
               stb       R$B,u               store error code
FixCC          ldb       R$CC,u              get caller's CC
               andb      #^(Negative+Zero+TwosOvfl+Carry) turn off these flags
               stb       R$CC,u              save to caller's CC
               anda      #Negative+Zero+TwosOvfl+Carry turn off these flags
               ora       R$CC,u              OR with caller's CC
               sta       R$CC,u              and saved to caller's CC
               rts                           return
callerr@       comb                          set carry for error state
               ldb       #E$UnkSvc           unknown service
               bra       callexit@           perform exit


* no signal handler, exit with signal value as exit code
NoSigHandler   ldb       P$State,x           get process state in process descriptor
               orb       #SysState           OR in system state flag
               stb       P$State,x           and save it back
               ldb       <P$Signal,x         get the signal sent to the process
               andcc     #^(IntMasks)        unmask interrupts
               os9       F$Exit              perform exit on this process

;;; F$NProc
;;;
;;; Execute the next process in the active process queue.
;;;
;;; Entry: None.
;;;
;;; Exit:  None. Control doesn't return to the caller.
;;;
;;; F$NProc takes the next process out of the active process queue and initiates its execution.
;;; If the queue doesn't contain a process, the kerenl waits for an interrupt and then checks the
;;; queue again. The process calling F$NProc must already be in one of the three process queues.
;;; If it isn't, it becomes unknown to the system even though the process descriptor still exists
;;; and can be displayed by `procs`.
FNProc         clra                          A = 0
               clrb                          D = $0000
               std       <D.Proc             clear out current process descriptor pointer
               bra       nextactive@         branch to get next active process
* execution goes here when there are no active processes
wait@          cwai      #^(IntMasks)        halt processor waiting for an interrupt
nextactive@    orcc      #IntMasks           mask interrupts
               ldx       <D.AProcQ           get next active process
               beq       wait@               CWAI if none
               ldd       P$Queue,x           get queue ptr
               std       <D.AProcQ           store in active queue
               stx       <D.Proc             store in current process
               lds       P$SP,x              get process' stack ptr
CheckState     ldb       P$State,x           get state
               bmi       exit@               branch if system state
               bitb      #Condem             process condemned?
               bne       NoSigHandler        branch if so...
               ldb       <P$Signal,x         get signal no
               beq       restorevec@         branch if none
               decb                          decrement
               beq       savesig@            branch if wake up
               ldu       <P$SigVec,x         get signal handler address
               beq       NoSigHandler        branch if none
               ldy       <P$SigDat,x         get data address
               ldd       R$Y,s               get caller's Y
* set up new return stack for RTI
               pshs      u,y,d               new PC (sigvec), new U (sigdat), same Y
               ldu       6+R$X,s             old X via U
               lda       <P$Signal,x         signal ...
               ldb       6+R$DP,s            and old DP ...
               tfr       d,y                 via Y
               ldd       6+R$CC,s            old CC and A via D
               pshs      u,y,d               same X, same DP / new B (signal), same A / CC
               clrb                          clear B
savesig@       stb       <P$Signal,x         clear process's signal
restorevec@    ldd       <P$SWI2,x           get SWI2 vector stored in process descriptor
               std       <D.SWI2             and restore it to system globals
               ldd       <D.UsrIRQ           get user state IRQ vector
               std       <D.SvcIRQ           and restore it to the main service vector
exit@          rti       

;;; F$Link
;;;
;;; Link to a memory module that has the specified name, language, and type.
;;;
;;; Entry: A = The desired type/language byte.
;;;        X = The address of the desired module name.
;;;
;;; Exit:  A = The module's type/language byte.
;;;        B = The module's attributes/revision byte.
;;;        X = The address of the last byte of the module name, plus 1.
;;;        Y = The address of the module’s execution entry point.
;;;        U = The address of the module header.
;;;       CC = Carry flag clear to indicate no error.
;;;
;;; Error:  B = A non-zero error code.
;;;        CC = Carry flag set to indicate error.
;;;
;;; A module's link count indicates how many processes are using it. F$Link increases the module’s
;;; link count count by one. If the module requested isn't shareable (not re-entrant), only one process
;;; can link to it at a time, and any additional link attempts return E$ModBsy.
;;;
;;; F$Link searches the module directory for a module that has the specified name, language, and type.
;;; If it finds the module, it returns the address of the module’s header in U, and the absolute address of the
;;; module’s execution entry point in Y. If F$Link can't find the desired module, it returns E$MNF.
FLink          pshs      u                   save caller regs
               ldd       R$A,u               get desired type/language byte
               ldx       R$X,u               get pointer to desired module name to link to
               lbsr      FindModule          go find the module
               bcc       FLinkOK             branch if found
               ldb       #E$MNF              ...else Module Not Found error
               bra       FLinkBye            and return to caller
FLinkOK        ldy       ,u                  get module directory ptr
               ldb       M$Revs,y            get revision byte
               bitb      #ReEnt              reentrant?
               bne       IncCount            branch if so
               tst       MD$Link,u           link count zero?
               beq       IncCount            yep, ok to link to non-reentrant
               comb                          ...else set carry
               ldb       #E$ModBsy           load B with Module Busy
               bra       FLinkBye            and return to caller
IncCount       inc       MD$Link,u           increment link count
               ldu       ,s                  get caller register pointer from stack
               stx       R$X,u               save off updated name pointer
               sty       R$U,u               save off address of found module
               ldd       M$Type,y            get type/language byte from found module
               std       R$D,u               and place it in caller's D register
               ldd       M$IDSize,y          get the module ID size in D
               leax      d,y                 advance X to the start of the body of the module
               stx       R$Y,u               store X in caller's Y register
FLinkBye       puls      pc,u                return to caller

;;; F$VModul
;;;
;;; Validate the module header parity and CRC bytes of a module.
;;;
;;; Entry: X = The address of the module to verify.
;;;
;;; Exit:  U = The absolute address of the module header.
;;;       CC = Carry flag clear to indicate no error.
;;;
;;; Error: B = A non-zero error code.
;;;       CC = Carry flag set to indicate error.
;;;
;;; Use F$VModul to validate the integrity of a module. If the module is valid, F$VModul searches the module directory
;;; for a module with the same name. If one exists, the module with the higher revision level remains in memory.
;;; If both modules have the same revision level, F$VModul retains the module in memory.
FVModul        pshs      u                   save caller's registers
               ldx       R$X,u               get caller's X (address of module name)
               bsr       ValMod              perform the validation
               puls      y                   pull the caller's registers
               stu       R$U,y               save the new (if any) module address
               rts                           return to caller

* X = address of module to validate
ValMod         bsr       ChkMHCRC            check the module header and CRC
               bcs       ValModEx            ... exit if error
               lda       M$Type,x            get the type byte
               pshs      x,a                 save off
               ldd       M$Name,x            get module name offset
               leax      d,x                 set X to address of name in module
               puls      a                   restore type byte
               lbsr      FindModule          find the module
               puls      x                   restore module address
               bcs       ValLea              branch if error
               ldb       #E$KwnMod           prepare possible error
               cmpx      ,u                  is the returned module the same?
               beq       ValErrEx            branch if so
               lda       M$Revs,x            else get revision byte of passed module
               anda      #RevsMask           mask out all but revision
               pshs      a                   save off
               ldy       ,u                  get pointer to found module (different)
               lda       M$Revs,y            get revision byte of found module
               anda      #RevsMask           mask out all but revision
               cmpa      ,s+                 compare revisions
               bcc       ValErrEx            if same or lower, return to caller
               pshs      y,x                 save off pointer to modules
               ldb       M$Size,u            get size of found module
               bne       ValPul              branch if not zero
               ldx       ,u                  get address of module into X
               cmpx      <D.BTLO             compare against Boot low memory pointer
               bcc       ValPul              branch if higher
               ldd       M$Size,x            else get module size from module header
               addd      #$00FF              round up to next page
               tfr       a,b                 divide by 256 (# of pages to clear)
               clra                          D = rounded up value of module's memory footprint (number of bits to clear)
               tfr       d,y                 transfer to Y
               ldb       ,u                  put high byte of module address into B (D = first bit in allocation table to clear)
               ldx       <D.FMBM             get pointer to free memory bitmap
               os9       F$DelBit            delete from alloction table (D = first bit to clear, X = bitmap address, Y = # of bits to clear)
               clr       M$Size,u            clear out size in deallocated module directory (invalidates the module)
ValPul         puls      y,x                 restore X and Y
ValSto         stx       ,u                  save X into U
               clrb                          clear carry and error code
ValModEx       rts                           return
ValLea         leay      ,u                  update Y to U
               bne       ValSto              branch if Y not 0
               ldb       #E$DirFul           module directory is full
ValErrEx       coma                          set carry
               rts                           return to caller

* Check module header and CRC
*
* Entry: X = Address of potential module.
ChkMHCRC       ldd       ,x                  get two bytes at start of potential module
               cmpd      #M$ID12             are these module sync bytes?
               bne       ex@                 nope, not a module here
               leay      M$Parity,x          else point Y to the parity byte in the module
               bsr       ChkMHPar            check header parity
               bcc       Chk4CRC             branch if ok
ex@            comb                          else set carry
               ldb       #E$BMID             and load B with error
               rts                           return to caller

* Check module CRC
*
* Entry: X = Address of module to check.
Chk4CRC                  
* Following 4 lines added to support no CRC checks - 2002/07/21
               lda       <D.CRC              is CRC checking on?
               bne       DoCRCCk             branch if so
               clrb                          else clear carry
               rts                           return to caller

* Check if module CRC checking is on
*
* Entry: X = Address of module to check.
DoCRCCk        pshs      x                   save off module address onto stack
               ldy       M$Size,x            get module size in module header
               bsr       ChkMCRC             check module CRC
               puls      pc,x

* Check module header parity
*
* Entry: X = Module header to check.
*        Y = Pointer to parity byte.
ChkMHPar       pshs      y,x                 save off X and Y
               clra                          A = 0
loop@          eora      ,x+                 XOR with 
               cmpx      M$Parity,s          compare to address of M$Parity
               bls       loop@               branch if not there yet
               cmpa      #$FF                parity check done... is it correct?
               puls      pc,y,x              restore regs and return

* Check module CRC
*
* Entry: X = Address of potential module.
*        Y = Size of module.
ChkMCRC        ldd       #$FFFF              initialize D to $FFFF
               pshs      b,a                 save off stack
               pshs      b,a                 32 bits
               leau      1,s                 advance one byte (24 byte CRC)
loop@          lda       ,x+                 get next byte of module
               bsr       CRCAlgo             perform algorithm
               leay      -1,y                decrement Y (size of module)
               bne       loop@               continue if not at end
               clr       -1,u                clear first 8 bits of 32 bits
               lda       ,u                  get first byte of CRC
               cmpa      #CRCCon1            is it what we expect?
               bne       err@                branch if not
               ldd       1,u                 get next two bytes of CRC
               cmpd      #CRCCon23           is it what we expect?
               beq       ex@                 branch if what we expect
err@           comb                          ...else set carry
               ldb       #E$BMCRC            load B with error
ex@            puls      pc,y,x              return to caller

               use       fcrc.asm

* Search the module directory for the module to link.
*
* Entry: A = Type of module to linkl
*        X = Pointer to name of module.
*
* Exit:  
FindModule               
               ldu       #$0000              initialize U with $000
               tfr       a,b                 copy A to B
               anda      #TypeMask           preserve type bits in A
               andb      #LangMask           preserve language bits in B
               pshs      u,y,x,b,a           save important registers
_stk1A@        set       0
_stk1B@        set       1
_stk1X@        set       2
_stk1Y@        set       4
_stk1U@        set       6
               bsr       EatSpace            move X past any spaces
               cmpa      #PDELIM             pathlist char?
               beq       LinkErr             branch if so
               lbsr      ParseNam            parse name
               bcs       LinkBye             branch if error
               ldu       <D.ModDir           get pointer to module directory
FindLoop       pshs      u,y,b               save important registers
_stk2B@        set       0                   B = pathname length
_stk2Y@        set       1                   Y = 
_stk2U@        set       3                   U = address of next module in module directory
_stk1A@        set       0+_stk2U@+2
_stk1B@        set       1+_stk2U@+2
_stk1X@        set       2+_stk2U@+2
_stk1Y@        set       4+_stk2U@+2
_stk1U@        set       6+_stk2U@+2
               ldu       ,u                  get pointer to next module to compare names with
               beq       CheckEnd            empty entry... continue to next module in list
               ldd       M$Name,u            get module name offset in module
               leay      d,u                 point Y to module name
               ldb       _stk2B@,s           get length of pathname on stack
               lbsr      L07AB               compare name of modules
               bcs       NextMod             branch if not same name
               lda       _stk1A@,s           get saved type byte on stack
               beq       ChkLang             same... now check language
               eora      M$Type,u            EOR with type in module
               anda      #TypeMask           preserve type bits
               bne       NextMod             branch if not same type
ChkLang        lda       _stk1B@,s           get saved language byte on stack
               beq       ModFound            branch if 0
               eora      M$Type,u            EOR with language in module
               anda      #LangMask           preserve language bits
               bne       NextMod             branch if not same language
ModFound       puls      u,x,b               module found... restore regs
_stk1A@        set       0
_stk1B@        set       1
_stk1X@        set       2
_stk1Y@        set       4
_stk1U@        set       6
               stu       _stk1U@,s           save off found module in caller's U
               bsr       EatSpace            move past any spaces
               stx       _stk1X@,s           save off module name in caller's X
               clra                          clear carry
               bra       LinkBye             branch to exit of routine
_stk2B@        set       0
_stk2Y@        set       1
_stk2U@        set       3
_stk1A@        set       0+_stk2U@+2
_stk1B@        set       1+_stk2U@+2
_stk1X@        set       2+_stk2U@+2
_stk1Y@        set       4+_stk2U@+2
_stk1U@        set       6+_stk2U@+2
CheckEnd       ldd       _stk1U@,s           get saved pointer in module directory
               bne       NextMod             branch to get next module in directory
               ldd       _stk2U@,s           get saved U
               std       _stk1U@,s           put in saved U in earlier stack
NextMod        puls      u,y,b               restore pushed regs
               leau      MD$ESize,u          advance to next module directory entry
               cmpu      <D.ModDir+2         at end of directory?
               bcs       FindLoop            no... continue searching
LinkErr        comb                          set carry
LinkBye        puls      pc,u,y,x,b,a        return to caller

* Advance past any leading spaces in a string.
*
* Entry: X = Pointer to string.
*
* Exit:  A = First non-space character.
*        X = Pointer to first non-space character.
EatSpace       lda       #C$SPACE            load A with space character
loop@          cmpa      ,x+                 compare with character at X and increment
               beq       loop@               if space, keep going
               lda       ,-x                 else get non-space character at X-1
               rts                           return

;;; F$Fork
;;;
;;; Links or loads a module and create a new process.
;;;
;;; Entry:  A = The type/language byte.
;;;         B = Size of the optional data area (in pages).
;;;         X = Address of the module name or filename.
;;;         Y = Size of the parameter area (in pages). The default is 0.
;;;         U = Starting address of the parameter area. This must be at least one page.
;;;
;;; Exit:   A = New process I/O number.
;;;         X = Address of the last byte of the name plus 1.
;;;       CC = Carry flag clear to indicate no error.
;;;         
;;; Error:  B = A non-zero error code.
;;;        CC = Carry flag set to indicate error.
;;;
;;; F$Fork creates a new child process of the calling process. It also sets up the child process’ memory,
;;; 6809 registers, and standard I/O paths.
;;;
;;; Upon success, X hold the address of the character past the name. For example, before the call:
;;;
;;;   X
;;;  _|__________________
;;; | T | E | S | T | \n |
;;;  --------------------
;;;
;;; And after the call:
;;;
;;;                    X
;;;  __________________|_
;;; | T | E | S | T | \n |
;;;  --------------------
;;;
;;; When the system call starts, it parses the passed name, then searches
;;; the module directory to see if the module is already in memory. If it is,
;;; then F$Fork calls F$Link and inserts it into the active process queue.
;;;
;;; If F$Link fails, then F$Fork calls F$Load to load the module from the current execution directory on the disk.
;;; It looks for a filename that matches the address of module name passed in X. If more than one module exists in the
;;; file, only the first one has its link count set. The first module in a file is the primary module.
;;;
;;; F$Fork then inspects the primary module to determine its data area, then allocates contiguous RAM for that amount.
;;; If the allocation succeeds, F$Fork copies the parameters at U into the data area, then sets the registers for the
;;; child process like this:
;;;
;;;   ------------------  <- Y (Highest address)
;;;  |  Parameter area  |
;;;  |------------------| <- X, SP 
;;;  |                  |
;;;  |     Data area    |
;;;  |                  |
;;;  |------------------| 
;;;  |                  |
;;;  |    Direct page   |
;;;  |                  |
;;;   ------------------  <- U, DP (Lowest address)
;;;
;;; D holds the size of the parameter area in bytes, the PC points to the primary module's execution entry point, and
;;; CC's FIRQ and IRQ mask flags are clear.
;;;
;;; Registers Y and U (the top-of-memory and bottom-of-memory pointers, respectively) always have values at page
;;; boundaries.
;;; If the parent process doesn't specify the size of the parameter area, the size defaults to zero.
;;; The minimum data area size is one page.
;;;
;;; When the shell processes a command line, it passes a string in the parameter area. The string is a copy of the parameter
;;; part of the command line. To simplify string-oriented processing, the shell also inserts an end-of-line character at the
;;; end of the parameter string.
;;;
;;; X points to the starting byte of the parameter string. If the command line includes the optional memory size specification
;;; (#n or #nK), the shell passes that size as the requested memory size when executing F$Fork.
;;;
;;; If any part of F$Fork is unsuccessful, it terminates and returns an error to the caller.
;;;
;;; The child and parent processes execute at the same time unless the parent calls F$Wait immediately after F$Fork.
;;; In this case, the parent waits until the child dies before it resumes execution.
;;;
;;; Be careful when recursively calling a program that uses F$Fork. Another new child process appears with each new execution
;;; and continues until the process table becomes full.
;;;
;;; Don't call F$Fork with a memory size of zero.
FFork          ldx       <D.PrcDBT           get the pointer to the process descriptor table               
               os9       F$All64             allocate a 64 byte page of RAM
               bcs       errex@              branch if error
               ldx       <D.Proc             get the parent (current) process descriptor
               pshs      x                   save it on the stack
               ldd       P$User,x            get the user ID of the parent process
               std       P$User,y            save it in the child process descriptor
               lda       P$Prior,x           get the priority of the parent process
               clrb                          B = 0
               std       P$Prior,y           store it in the child process descriptor
               ldb       #SysState           get system state flag into B
               stb       P$State,y           set the System State flag in the child process descriptor
               sty       <D.Proc             make the child process the current process
               ldd       <P$NIO,x            get the parent process' Net I/O pointer
               std       <P$NIO,y            save it in the child process descriptor
               ldd       <P$NIO+2,x          copy next two bytes
               std       <P$NIO+2,y          over to child process descriptor
               leax      <P$DIO,x            point X to the the parent process' Disk I/O section
               leay      <P$DIO,y            point Y to the child process' Disk I/O section
               ldb       #DefIOSiz           get the size of the section
loop@          lda       ,x+                 get byte at x and increment
               sta       ,y+                 save byte at y and increment
               decb                          decrement loop counter
               bne       loop@               branch if not done
* It so happens that X and Y are now pointing to P$PATH in the process descriptor, so
* there's no need to load them explicitly.
* Duplicate stdin/stdout/stderr.
               ldb       #$03                copy first three paths from parent to child
DupLoop@       lda       ,x+                 get next available path in parent process descriptor                 
               os9       I$Dup               duplicate it
               bcc       DupOK@              branch if ok
               clra                          else if error, just make it zero
DupOK@         sta       ,y+                 store it in the child process descriptor
               decb                          decrement the counter
               bne       DupLoop@            and branch back if not done
               bsr       SetupPrc            set up process
               bcs       ex@
               puls      y                   get the parent process desccriptor
               sty       <D.Proc
               lda       P$ID,x              get the process ID of child process descriptor
               sta       R$A,u               store it in caller's A
               ldb       P$CID,y             get child ID of parent process descriptor
               sta       P$CID,y             store child process ID in parent's child process ID
               lda       P$ID,y              get process ID of parent process
               std       P$PID,x             store it in child's process descriptor
               ldb       P$State,x           update state of the child process descriptor
               andb      #^SysState          turn off system state
               stb       P$State,x           save back to process descriptor
               os9       F$AProc             insert the child process into active queue
               rts                           return to the caller
ex@            pshs      b                   save off B to stack
               os9       F$Exit              and exit
               comb                          set carry
               puls      x,b                 restore X and B
               stx       <D.Proc             save X to process descriptor
               rts                           return
errex@         comb                          set carry
               ldb       #E$PrcFul           error is process table is full
               rts                           and return

;;; F$Chain
;;;
;;; Links or loads a module and replaces the calling process.
;;;
;;; Entry:  A = The type/language byte.
;;;         B = Size of the optional data area (in pages).
;;;         X = Address of the module name or filename.
;;;         Y = Size of the parameter area (in pages). The default is 0.
;;;         U = Starting address of the parameter area. This must be at least one page.
;;;
;;; Error:  B = A non-zero error code.
;;;        CC = Carry flag set to indicate error.
;;;
;;; F$Chain loads and executes a new primary module, but doesn't create a new process. F$Chain is similar to F$Fork followed
;;; by F$Exit, but has less processing overhead. F$Chain resets the calling process' program and data memory areas, then begins
;;;
;;; F$Chain unlinks the process’ old primary module, then parses the name of the new process’ primary module  It searches the system module 
;;; directory for module with the same name, type, and language already in memory.
;;; If the module is in memory, F$Chain links to it. If the module isn't in memory, F$Chain uses the name string as the pathlist
;;; of a file to load into memory. Then, it links to the first module in this file. (Several modules can be loaded from a single file.)
;;;
;;; F$Chain then reconfigures the data memory area to the size specified in the new primary module’s header. Finally, it intercepts
;;; and erases any pending signals.
* F$Chain user state
FChain         bsr       DoChain             do the F$Chain
               bcs       chainerr@               branch if error
               orcc      #IntMasks           mask interrupts
               ldb       P$State,x           get process state
               andb      #^SysState          turn off system state
               stb       P$State,x           save new state
actproc@       os9       F$AProc             activate process
               os9       F$NProc
* F$Chain system state
SFChain        bsr       DoChain             do the F$Chain
               bcc       actproc@               branch if OK
chainerr@          pshs      b                   save off B for now
               stb       <P$Signal,x         save off error code
               ldb       P$State,x           get process state
               orb       #Condem             set the condemn bit
               stb       P$State,x           save new state
               ldb       #255                get highest priority
               stb       P$Prior,x           set priority
               comb                          set carry
               puls      pc,b                return error
DoChain        pshs      u                   save off caller's SP
               ldx       <D.Proc             get current process descriptor
               ldu       <P$PModul,x         get pointer to module for current process
               os9       F$UnLink            unlink the module
               ldu       ,s                  get saved caller's SP
               bsr       SetupPrc            create new child process
               puls      pc,u                recover U and return

SetupPrc       ldx       <D.Proc             get current process descriptor
               pshs      u,x                 save off
               ldd       <D.UsrSvc           get user service table
               std       <P$SWI,x            save off as process' SWI vector
               std       <P$SWI2,x           ... and SWI2 vector
               std       <P$SWI3,x           ... and SWI3 vector
               clra                          A = 0
               clrb      D = 0
               sta       <P$Signal,x         clear the signal
               std       <P$SigVec,x         clear signal vector
               lda       R$A,u               get caller's A
               ldx       R$X,u               ... and X
               os9       F$Link              link the module to chain to
               bcc       ChkType@            branch if OK
               os9       F$Load              ... else load the module to chain to
               bcs       SetupPrcEx          ... and branch if error
ChkType@       ldy       <D.Proc             get current process
               stu       <P$PModul,y         save off module pointer
               cmpa      #Prgrm+Objct        is this a program module?
               beq       CmpMem@             branch if so
               cmpa      #Systm+Objct        is it a system module?
               beq       CmpMem@             branch if so
               comb                          else set carry
               ldb       #E$NEMod            set error in B
               bra       SetupPrcEx          and return
CmpMem@        leay      ,u                  Y = address of module
               ldu       2,s                 get U off stack (caller regs)
               stx       R$X,u               update X to point past name
               lda       R$B,u               get caller's requested memory size in 256 byte pages
               clrb      
               cmpd      M$Mem,y             compare passed memory to module's
               bcc       alloc@              branch if less than or equal to module's memory
               ldd       M$Mem,y             else load D with module's memory
alloc@         addd      #$0000              is this needed??
               bne       allcmem@            and this???
allcmem@       os9       F$Mem               allocate requested memory
               bcs       SetupPrcEx          branch if error
               subd      #R$Size             subtract registers
               subd      R$Y,u               subtract parameter area
               bcs       BadFork             branch if <= 0
               ldx       R$U,u               get parameter area
               ldd       R$Y,u               get parameter size
               pshs      b,a                 save onto the stack
               beq       setregs@            branch if parameter area is zero (nothing to copy)
               leax      d,x                 point to end of param area
loop@         lda       ,-x                 get parameter byte and decrement X
               sta       ,-y                 save byte in data area and decrement Y
               cmpx      R$U,u               at top of parameter area?
               bhi       loop@             branch if not
* Set up registers for return of F$Fork/F$Chain
setregs@       ldx       <D.Proc
               sty       -R$Size+R$X,y       put in X on caller stack
               leay      -R$Size,y           back up the size of the register file
               sty       P$SP,x              save Y as the stack pointer
               lda       P$ADDR,x            get the starting page number
               clrb      
               std       R$U,y               save it as the lowest address in the caller's U
               sta       R$DP,y              and set direct page in the caller's DP
               adda      P$PagCnt,x          add the memory page count
               std       R$Y,y               store it in the caller's Y
               puls      b,a                 recover the size of the parameter area
               std       R$D,y               and store it in the caller's D
               ldb       #Entire             set the entire flag
               stb       R$CC,y              in the caller's CC
               ldu       <P$PModul,x         get the address of the primary module
               ldd       M$Exec,u            get the execution offset
               leau      d,u                 point U to that
               stu       R$PC,y              put that offset in the caller's PC
               clrb      B = 0
BadFork        ldb       #E$IForkP           illegal fork parameter
SetupPrcEx                              puls      pc,u,x              return to caller

               use       fsrqmem.asm

               use       fallbit.asm

               use       fprsnam.asm

               use       fcmpnam.asm

               use       fssvc.asm

* Validate modules subroutine
* Entry: X = Address to start searching.
*        Y = Address to stop (actually stops at Y-1).
ValMods        pshs      y save off Y
loop@         lbsr      ValMod go validate module
               bcs       ValErr branch if error
               ldd       M$Size,x get size of module into D
               leax      d,x                 point X past module
               bra       valcheck go check if we're at end
ValErr         cmpb      #E$KwnMod did the validation check show a known module?
               beq       ex@ branch if so
               leax      1,x else advance X by one byte
valcheck       cmpx      ,s check if we're at end
               bcs       loop@ branch if not
ex@          puls      y,pc restore Y and return

* This vector code that the kernel copies to low RAM ($0100).
VectCode       bra       SWI3Jmp             $0100
               nop       
               bra       SWI2Jmp             $0103
               nop       
               bra       SWIJmp              $0106
               nop       
               bra       NMIJmp              $0109
               nop       
               bra       IRQJmp              $010C
               nop       
               bra       FIRQJmp             $010F
SWI3Jmp        jmp       [>D.SWI3]
SWI2Jmp        jmp       [>D.SWI2]
SWIJmp         jmp       [>D.SWI]
NMIJmp         jmp       [>D.NMI]
IRQJmp         jmp       [>D.IRQ]
FIRQJmp        jmp       [>D.FIRQ]
VectCSz        equ       *-VectCode

* The system call table.
SysTbl         fcb       F$Link
               fdb       FLink-*-2
               fcb       F$Fork
               fdb       FFork-*-2
               fcb       F$Chain
               fdb       FChain-*-2
               fcb       F$Chain+SysState
               fdb       SFChain-*-2
               fcb       F$PrsNam
               fdb       FPrsNam-*-2
               fcb       F$CmpNam
               fdb       FCmpNam-*-2
               fcb       F$SchBit
               fdb       FSchBit-*-2
               fcb       F$AllBit
               fdb       FAllBit-*-2
               fcb       F$DelBit
               fdb       FDelBit-*-2
               fcb       F$CRC
               fdb       FCRC-*-2
               fcb       F$SRqMem+SysState
               fdb       FSRqMem-*-2
               fcb       F$SRtMem+SysState
               fdb       FSRtMem-*-2
               fcb       F$AProc+SysState
               fdb       FAProc-*-2
               fcb       F$NProc+SysState
               fdb       FNProc-*-2
               fcb       F$VModul+SysState
               fdb       FVModul-*-2
               fcb       F$SSvc
               fdb       FSSvc-*-2
               fcb       $80

InitNam        fcs       /Init/

P2Nam          fcs       /krnp2/

EOMTop         equ       *

               emod      
eom            equ       *

Vectors        fdb       SWI3                SWI3
               fdb       SWI2                SWI2
               fdb       DUMMY               FIRQ
               fdb       SVCIRQ              IRQ
               fdb       SWI                 SWI
               fdb       SVCNMI              NMI

EOMSize        equ       *-EOMTop

               end       

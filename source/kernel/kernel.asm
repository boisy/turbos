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
*******************************************************************************
* NOTES:
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

               nam       Kernel
               ttl       TurbOS Kernel

               use       defsfile

tylg           set       Systm+Objct
atrv           set       ReEnt+rev
rev            set       $00
edition        set       1

ModTop         mod       eom,name,tylg,atrv,ColdStart,size

size           equ       .

name           fcs       /kernel/
               fcb       edition

**************************
* Kernel entry point
*
ColdStart      equ       *
**** FNX6809 PORT SPECIFIC CODE !! ****
* FNX6809-specific initialization to get the F256 to a sane state.
               ifne      fnx6809
               orcc      #IntMasks           mask interrupts
               clra                          clear A
               tfr       a,dp                transfer to DP
               clr       MMU_IO_CTRL         map I/O into bank 6
               lda       #$FF                set all bits in A
               sta       INT_MASK_0          mask all set 0 interrupts
               sta       INT_MASK_1          mask all set 1 interrupts
               sta       INT_PENDING_0       clear any pending set 0 interrupts
               sta       INT_PENDING_1       clear any pending set 0 interrupts
               endc      
**** FNX6809 PORT SPECIFIC CODE !! ****

* Clear out system globals from $D.FMBM-$0400.
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
               leax      ModTop,pcr          point X to start of kernel module
               pshs      x
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
               cmpx      ,s                  stop short kernel
               bcs       ChkRAM              branch if not done
               leay      ,x                  point Y to X (end of RAM)
EndOfRAM@      leax      ,y                  X = end of RAM
               leas      2,s
               else      
               leax      ModTop,pcr          point X to start of kernel module
               endc      
               stx       <D.MLIM             save off memory limit

**** FNX6809 PORT SPECIFIC CODE !! ****
               ifne      fnx6809
               ldx       #$8000              start searching for modules in low RAM
               endc      
**** FNX6809 PORT SPECIFIC CODE !! ****

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
               ldy       #MappedIOStart      stop short of IO address area
               lbsr      ValMods             validate modules there

* Some platforms don't have contiguous RAM in the 64K address space due to "holes"
* for areas such as I/O. For these platforms, we have to perform a separate
* module scan to look for modules after those holes.
*
**** FNX6809 PORT SPECIFIC CODE !! ****
               ifne      fnx6809
* FNX6809: look for more modules at $E000-$FFF0
               ldx       #$E000
               ldy       #$FFF0
               lbsr      ValMods
               endc      
**** FNX6809 PORT SPECIFIC CODE !! ****

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
               ifne      _FF_IRQ_POLL
               leax      >FIRQPoller,pcr     get the address of the IRQ polling routine
               else
               leax      >Poll,pcr           get the default polling routine
               endc
               stx       <D.Poll             store it in system globals
               leax      >Clock,pcr          get the default tick generator routine
               stx       <D.Clock            store it in system globals

* Install system calls.
               leay      >SysTbl,pcr         get the system call table address
               lbsr      InstallSvc          and install it

* Link to init module.
               lda       #Systm+0            we want a system module
               leax      >InitNam,pcr        point to the configuration module name
               os9       F$Link              link to it
               lbcs      FatalErr            if error, restart kernel
               stu       <D.Init             else store it in system globals
               ifne      _FF_MODCHECK
               lda       CM$Feature1,u       get feature byte 1
               bita      #CRCOn              is CRC checking on?
               beq       continue@           branch if not (already cleared earlier)
               inc       <D.CRC              else turn on CRC checking
               endc      
continue@                

* Link to tick generator module, if any and call its initialization routine
               ldd       CM$TickMod,u
               beq       continue@
               leax      d,u
               lda       #Systm+0
               os9       F$Link
               bcs       continue@
               jsr       ,y
continue@                

* Setup the free memory bitmap.
* This area of the kernel is highly platform-dependent.
*
* The free memory bitmap has the following structure:
*   bit 7 of 0,x corresponds to page 0, bit 6 to page 1 etc.
*   bit 7 of 1,x corresponds to page 8, bit 6 to page 9 etc.
SetupMap       ldx       <D.FMBM             get free memory bitmap in X
               ldb       #%11111000          reserve $0000-$04FF
               stb       ,x                  mark that area in the bitmap as allocated

**** FNX6809 PORT SPECIFIC CODE !! ****
               ifne      fnx6809
* FNX6809 needs $C000-$DFFF reserved since this is I/O space.
               ldb       #%11111111
               ldb       #%11111111
               stb       $18,x               mark $C000-$C7FF I/O area as allocated
               stb       $19,x               mark $C800-$CFFF I/O area as allocated
               stb       $1A,x               mark $D000-$D7FF I/O area as allocated
               stb       $1B,x               mark $D800-$DFFF I/O area as allocated
               endc      
**** FNX6809 PORT SPECIFIC CODE !! ****

* Exclude high memory as defined (earlier) by D.MLIM.
               clra                          A = 0
               ldb       <D.MLIM             B = upper byte of 16 bit memory limit
               negb                          negate B
               tfr       d,y                 transfer D to Y
               negb                          negate B
               lbsr      AllocBit            call into F$AllBit to allocate bits
* Allocate process descriptor for new process.
               ldx       <D.PrcDBT           get process descriptor table in X
               os9       F$All64             allocate a new 64 byte page
               bcs       FatalErr            failed to allocate
               stx       <D.PrcDBT           save off
               sty       <D.Proc             save off new process descriptor pointer
               tfr       s,d                 transfer the stack pointer to D
               deca                          set address to 1 minus stack's MSB
               ldb       #$01                set page count to 1 (256 bytes)
               std       P$ADDR,y            save off in P$ADDR and P$PagCnt
               lda       #SysState           get system state flag
               sta       P$State,y           set the state in the process descriptor
               ldu       <D.Init             get init module address in U

               ifne      _FF_UNIFIED_IO
* ChdDir should identify system device, result in a call to IOCall which links and
* initialises IOMan. This could fail if IOMan is not loaded.
               bsr       ChdDir              attempt to change directories
               ifne      _FF_BOOTING
               bcc       open@               branch if successful
               lbsr      LoadBoot            else attempt to load bootfile
               bsr       ChdDir              then try to change directories again
               endc      
open@          bsr       OpenCons            try to open the console
               ifne      _FF_BOOTING
               bcc       ChainProg           branch if successful
* Maybe we were able to get this far without needing anything from the boot file, but now
* we need it for the console device
               lbsr      LoadBoot            else attempt to load bootfile
               bsr       OpenCons            try to open the console again
               endc      
               endc      

ChainProg      ldd       CM$GoMod,u          get the offset to the 'GO' program from the Init module
               leax      d,u                 point X to the address of the name
               lda       #Objct              object code
               clrb                          no optional data area needed
               ldy       #$0000              no parameter area needed
               os9       F$Chain             chain to it

* If we get here, loop forever.
FatalErr                 
forever@       bra       forever@

               ifne      _FF_UNIFIED_IO
* Change the directory.
* Entry: U = address of the Init module
ChdDir         clrb                          clear carry
               ldd       <CM$StoreMod,u      get system device
               beq       ChdDir10            branch if none - carry still clear
               leax      d,u                 address of the path list
               lda       #READ.+EXEC.        access mode
               os9       I$ChgDir            change directory to it
ChdDir10       rts                           carry set -> error

* Open the console device.
* Entry: U = address of the Init module
OpenCons       clrb                          clear B
               ldd       <CM$ConsoleMod,u    get the offset to the console device in the Init module
               leax      d,u                 point X to the address of the name
               lda       #UPDAT.             open for update
               os9       I$Open              open it
               bcs       OpenCn10            branch if error
               ldx       <D.Proc             get process descriptor
               sta       P$Path+0,x          save path to console to stdin...
               os9       I$Dup               duplicate it
               sta       P$Path+1,x          ...stdout
               os9       I$Dup               duplicate it
               sta       P$Path+2,x          ...and stderr
OpenCn10       rts                           return to the caller
               endc      

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

DoIRQPoll      jsr       [>D.Poll]           call vectored polling routine
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

* This is the default interrupt polling routine -- it does nothing.
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
               bsr       SFAProc
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
               bsr       SFAProc
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
DoSysCall      pshs      u                   save off caller's register pointer
               ldx       R$PC,u              point X to PC
               ldb       ,x+                 get func code at X
               stx       R$PC,u              restore updated PC
               lslb                          high bit set?
               bcc       nonio@              branch if not (non I/O call)
               ifne      _FF_UNIFIED_IO
               rorb                          else restore B (its an I/O call)
               ldx       -2,y                grab IOMan vector
               beq       callexit@           just exit if IOMan vector is empty
               bra       execcall@           make system call
               else      
               bra       callexit@           for non IO support, just ignore any I$ calls
               endc      
nonio@         cmpb      #$37*2              non-IO call; are we in safe are?
               bcc       callerr@            branch if not (unknown service)
               ldx       b,y                 X = address of system call
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

               use       fnproc.asm
               use       flink.asm
               use       fvmodul.asm
               ifne      _FF_MODCHECK
               use       fcrc.asm
               endc      
               use       ffork.asm
               use       fchain.asm
               use       fsrqmem.asm
               use       fallbit.asm
               use       fprsnam.asm
               use       fcmpnam.asm
               use       fssvc.asm
               use       funlink.asm
               use       fwait.asm
               use       fexit.asm
               use       fmem.asm
               use       fsend.asm
               use       fsleep.asm
               use       ficpt.asm
               use       fsprior.asm
               use       fid.asm
               use       fsswi.asm
               use       ffind64.asm
               use       fall64.asm
               use       fret64.asm
               ifne      _FF_IRQ_POLL
               use       firq.asm
               endc
               ifne      _FF_UNIFIED_IO
               use       iocall.asm
               endc      

               ifne      _FF_BOOTING
* Attempt to load bootfile and validate the modules it contains
*
* Entry: U = Address of the Init module
*
* Exit:
*
* CC Carry set on Error
LoadBoot       pshs      u                   save off the init module address
               comb                          set the carry in anticipation of any errors
               tst       <D.Boot             already booted?
               bne       JmpBtEr             yep, return to caller...
               inc       <D.Boot             else set boot flag
               ldd       <CM$BootMod,u       get pointer to boot str
               beq       JmpBtEr             if none, return to caller
               leax      d,u                 X = ptr to boot mod name
               lda       #Systm+Objct        it's a system/object module
               os9       F$Link              link
               bcs       JmpBtEr             return if error
               jsr       ,y                  ...else jsr into boot module
* D = Size of the loaded bootfile.
* X = Address of the loaded bootfile.
               bcs       JmpBtEr             return if error
               stx       <D.MLIM             else save off to the memory low limit
               stx       <D.BTLO             and the bootfile low address
               leau      d,x                 advance 'D' bytes
               stu       <D.BTHI             and save the bootfile high address
* Search through bootfile and validate modules.
ValBoot        ldd       ,x                  grab the first two bytes
               cmpd      #M$ID12             are they the module sync bytes?
               bne       ValBoot1            branch if not
               os9       F$VModul            else validate the module
               bcs       ValBoot1            and branch if error
               ldd       M$Size,x            get module size
               leax      d,x                 move X to next module
               bra       ValBoot2            verify that we're not in the kernel area
ValBoot1       leax      1,x                 advance one byte
ValBoot2       cmpx      <D.BTHI             are we less that the high mark of the bootfile?
               bcs       ValBoot             branch if we are
JmpBtEr        puls      pc,u                retore register and return to caller
               endc      

* Validate modules subroutine
* Entry: X = Address to start searching.
*        Y = Address to stop (actually stops at Y-1).
ValMods        pshs      y                   save off Y
loop@          lbsr      ValMod              go validate module
               bcs       ValErr              branch if error
               ldd       M$Size,x            get size of module into D
               leax      d,x                 point X past module
               bra       valcheck            go check if we're at end
ValErr         cmpb      #E$KwnMod           did the validation check show a known module?
               beq       ex@                 branch if so
               leax      1,x                 else advance X by one byte
valcheck       cmpx      ,s                  check if we're at end
               bcs       loop@               branch if not
ex@            puls      y,pc                restore Y and return

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
               ifne      _FF_MODCHECK
               fcb       F$CRC
               fdb       FCRC-*-2
               endc      
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
               ifne      _FF_UNIFIED_IO
               fcb       $7F
               fdb       IOCall-*-2
               endc      
               fcb       F$Unlink
               fdb       FUnlink-*-2
               fcb       F$Wait
               fdb       FWait-*-2
               fcb       F$Exit
               fdb       FExit-*-2
               fcb       F$Mem
               fdb       FMem-*-2
               fcb       F$Send
               fdb       FSend-*-2
               fcb       F$Sleep
               fdb       FSleep-*-2
               fcb       F$Icpt
               fdb       FIcpt-*-2
               fcb       F$ID
               fdb       FID-*-2
               fcb       F$SPrior
               fdb       FSPrior-*-2
               fcb       F$SSWI
               fdb       F$SSWI-*-2
               fcb       F$Find64+SysState
               fdb       FFind64-*-2
               fcb       F$All64+SysState
               fdb       FAll64-*-2
               fcb       F$Ret64+SysState
               fdb       FRet64-*-2
               ifne      _FF_IRQ_POLL
               fcb       F$IRQ+$80
               fdb       FIRQ-*-2
               endc
               fcb       $80

InitNam        fcs       /Init/

EOMTop         equ       *

Vectors        fdb       SWI3                SWI3
               fdb       SWI2                SWI2
               fdb       DUMMY               FIRQ
               fdb       SVCIRQ              IRQ
               fdb       SWI                 SWI
               fdb       SVCNMI              NMI

EOMSize        equ       *-EOMTop

               emod      
eom            equ       *
               end       

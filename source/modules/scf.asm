********************************************************************
* scf - Sequential Character File Manager
*
* Edt/Rev  YYYY/MM/DD  Modified by
* Comment
* ------------------------------------------------------------------
*   1      2025/04/06  Boisy Pitre
* Migrated from the NitrOS-9 Project.

                    use       defs.d
                    use       scf.d

tylg                set       FlMgr+Objct
atrv                set       ReEnt+rev
rev                 set       0
edition             equ       1

                    mod       eom,SCFName,tylg,atrv,SCFEnt,0

SCFName             fcs       /scf/
                    fcb       edition

* Default input buffer setting for SCF devices when Opened/Created
*               123456789!123456789!1234567890
*msg      fcc   'by B.Nobel,C.Boyle,W.Gale-1993'
msg                 fcc       'www.nitros9.org'
msgsize             equ       *-msg               Size of default input buffer message
                    fcb       C$CR                2nd CR for buffer pad fill
blksize             equ       256-msgsize         Size of blank space after it

* Return bad pathname error
opbpnam             puls      y
bpnam               comb                          Set carry for error
                    ldb       #E$BPNam            Get error code
oerr                rts                           Return to caller

* I$Create/I$Open entry point
* Entry: Y= Path dsc. ptr
open                ldx       PD.DEV,y            Get device table pointer
                    stx       PD.TBL,y            Save it
                    ldu       PD.RGS,y            Get callers register stack pointer
                    pshs      y                   Save path descriptor pointer
                    ldx       R$X,u               Get pointer to device pathname
                    os9       F$PrsNam            Parse it
                    bcs       opbpnam             Error, exit
                    tsta                          End of pathname?
                    bmi       open1               Yes, go on
                    leax      ,y                  Point to actual device name
                    os9       F$PrsNam            Parse it again
                    bcc       opbpnam             Return to caller with bad path name if more
open1               sty       R$X,u               Save updated name pointer to caller
                    puls      y                   Restore path descriptor pointer
                    ldd       #256                Get size of input buffer in bytes
                    os9       F$SRqMem            Allocate it
                    bcs       oerr                Can't allocate it return with error
                    stu       PD.BUF,y            Save buffer address to path descriptor
                    leax      <msg,pc             Get ptr to init string
CopyMsg             lda       ,x+
                    sta       ,u+
                    decb
                    cmpa      #C$CR
                    bne       CopyMsg
CopyCR              sta       ,u+
                    decb
                    bne       CopyCR
                    ldu       PD.DEV,y            Get device table entry address
                    beq       bpnam               Doesn't exist, exit with bad pathname error
                    ldx       V$STAT,u            Get devices' static storage address
                    lda       PD.PAG,y            Get devices page length
                    sta       V.LINE,x            Save it to devices static storage
                    ldx       V$DESC,u            Get descriptor address
                    ldd       PD.D2P,y            Get offset to device name (duplicate from dev dsc)
                    beq       L00CF               None, skip ahead
                    leax      d,x
                    lda       PD.MOD,y            Get device mode (Read/Write/Update)
                    lsra
                    rorb
                    lsra
                    rolb
                    rola
                    rorb
                    rola
                    os9       I$Attach            Attempt to attach to device name in device desc.
                    bcs       OpenErr             Couldn't attach to device, detach & exit with error
                    stu       PD.DV2,y            Save new output (echo) device table pointer
*         ldu   PD.DEV,y     Get device table pointer
L00CF               ldu       V$STAT,u            Point to it's static storage
                    clra
                    clrb
                    std       PD.PLP,y            Clear out path descriptor list pointer
                    sta       PD.PST,y            Clear path status: Carrier not lost
                    pshs      d                   Save 0 on stack
                    ldx       V.PDLHd,u           Get path descriptor list header pointer
* 05/25/93 mod - Boisy Pitre's non-sharable device patches
* 01/15/10 mod - Boisy Pitre redoes his non-sharable device patch
                    beq       Yespath             No paths open, so we know we can open it
* IOMan has already vetted the mode byte of the driver and the descriptor
* and compared it to REGA of I$Open (now in PD.MOD of this current path).
* here we know there is at least one path open for this device.
* in order to properly support SHARE. (device exclusivity), we get the
* mode byte for the path we are opening and see if the SHARE. bit is set.
* if so, then we return error since we cannot have exclusivity to the device.
                    lda       PD.MOD,y
                    bita      #SHARE.
                    bne       NoShare
* we now know that the path's mode doesn't have the SHARE. bit set, so
* we need to look at the mode of the path in the list header pointer to
* see if ITS SHARE. bit is set (meaning it wants exclusive access to the
* port).  If so we bail out
                    lda       PD.MOD,x
                    bita      #SHARE.
                    beq       CkCar               Check carrier status
NoShare             leas      2,s                 Eat extra stack (including good path count)
                    comb
                    ldb       #E$DevBsy           Non-sharable device busy error
                    bra       OpenErr             Go detach device & exit with error

Yespath             sty       V.PDLHd,u           Save path descriptor ptr
                    bra       L00F8               Go open the path

L00E6               tfr       d,x                 Change to PD.PLP path descriptor
CkCar               ldb       PD.PST,x            Get Carrier status
                    bne       L00EF               Carrier was lost, don't update count
                    inc       1,s                 Carrier not lost, bump up count of good paths
L00EF               ldd       PD.PLP,x            Get path descriptor list pointer
                    bne       L00E6               There is one, go make it the current one
                    sty       PD.PLP,x            Save path descriptor ptr as path dsc. list ptr
L00F8               lda       #SS.Open            Internal open call
                    pshs      a                   Save it on the stack
                    inc       2,s                 Bump counter of good paths up by 1
                    lbsr      L025B               Do the SS.Open call to the driver
                    lda       2,s                 Get counter of good paths
                    leas      3,s                 Eat stack
* NEW: return with error if SS.Open return error
                    bcs       L010F               +++BGP+++
                    deca                          Bump down good path count
                    bne       L0129               If more still open, exit without error
                    blo       L010F               If negative, something went wrong
                    lbra      L0250               Set parity/baud & return

* we come here if there was an error in Open (after I$Attach and F$SRqMem!)
L010F               bsr       RemoveFromPDList    Error, go clear stuff out
OpenErr             pshs      b,cc                Preserve error status
                    bsr       L0136               Detach device
                    puls      pc,b,cc             Restore error status & return

* I$Close entry point
close               pshs      cc                  Preserve interrupt status
                    orcc      #IntMasks           Disable interrupts
                    ldx       PD.DEV,y            Get device table pointer
                    bsr       L0182               Check it
                    ldx       PD.DV2,y            Get output device table pointer
                    bsr       L0182               Check it
                    puls      cc                  Restore interrupts
                    lda       PD.CNT,y            Any open images?
                    beq       L012B               No, go on
L0129               clra                          Clear carry
L012A               rts                           Return

* Detach device & return buffer memory
L012B               bsr       RemoveFromPDList
                    lda       #SS.Close           Get setstat code for close
                    ldx       PD.DEV,y            get pointer to device table
                    ldx       V$STAT,x            get static mem ptr
                    ldb       V.TYPE,x            Get device type    \ WON'T THIS SCREW UP WITH
                    bmi       L0136               Window, skip ahead / MARK OR SPACE PARITY???
                    pshs      x,a                 Save close code & X for SS.Close calling routine
                    lbsr      L025B               Not window, go call driver's SS.Close routine
                    leas      3,s                 Purge stack
L0136               ldu       PD.DV2,y            Get output device pointer
                    beq       L013D               Nothing there, go on
                    os9       I$Detach            Detach it
L013D               ldu       PD.BUF,y            Get buffer pointer
                    beq       L0147               None defined go on
                    ldd       #256                Get buffer size
                    os9       F$SRtMem            Return buffer memory to system
L0147               clra                          Clear carry
                    rts                           Return

* Remove path descriptor from device path descriptor linked list
* Entry: Y = path descriptor
RemoveFromPDList
                    ldx       #1
                    pshs      cc,d,x,y,u
                    ldu       PD.DEV,y            Get device table pointer
                    beq       L017B               None, skip ahead
                    ldu       V$STAT,u            Get static storage pointer
                    beq       L017B               None, skip ahead
                    ldx       V.PDLHd,u           Get path descriptor list header
                    beq       L017B               None, skip ahead
                    ldd       PD.PLP,y            Get path descriptor list pointer
                    cmpy      V.PDLHd,u           is the passed path descriptor the same?
                    bne       L0172               branch if not
                    std       V.PDLHd,u
                    bne       L017B
                    clr       4,s                 Clear LSB of X on stack
                    bra       L017B               Return

* D = path descriptor to store
L016D               ldx       PD.PLP,x            advance to next path descriptor in list
                    beq       L0180               branch if at end of linked list
L0172               cmpy      PD.PLP,x            is the passed path descriptor the same?
                    bne       L016D               branch if not
                    std       PD.PLP,x            store
L017B               clra
                    clrb
                    std       PD.PLP,y
L0180               puls      cc,d,x,y,u,pc


* Check path number?
* Entry: X=Ptr to device table (just LDX'd)
*        Y=Path dsc. ptr
L0182               beq       L012A               No device table, return to caller
                    ldx       V$STAT,x            Get static storage pointer
                    ldb       PD.PD,y             Get system path number from path dsc.
                    lda       PD.CPR,y            Get ID # of process currently using path
                    pshs      d,x,y               Save everything
                    cmpa      V.LPRC,x            Current process same as last process using path?
                    bne       L01CA               No, return
                    ldx       >D.Proc             Get current process pointer
                    leax      P$Path,x            Point to local path table
                    clra                          Start path # = 0 (Std In)
L0198               cmpb      a,x                 Same path as one is process' local path list?
                    beq       L01CA               Yes, return
                    inca                          Move to next path
                    cmpa      #NumPaths           Done all paths?
                    blo       L0198               No, keep going
                    pshs      y                   Preserve path descriptor pointer
                    ldd       #SS.Relea*256+D$PSTA
                    bsr       L01FA               Execute driver setstat routine
                    puls      y                   Restore path pointer
                    ldx       >D.Proc             Get current process pointer
                    lda       P$PID,x             Get parent process ID
                    sta       ,s                  Save it
                    ldx       <D.PrcDBT
                    os9       F$Find64
                    leax      P$Path,y            Point to local path table
                    ldb       1,s                 Get path number
                    clra                          Get starting path number
L01B9               cmpb      a,x                 Same path?
                    beq       L01C4               Yes, go on
                    inca                          Move to next path
                    cmpa      #NumPaths           Done all paths?
                    blo       L01B9               No, keep checking
                    clr       ,s                  Clear process ID
L01C4               lda       ,s                  Get process ID
                    ldx       2,s                 Get static storage pointer
                    sta       V.LPRC,x            Store it as last process
L01CA               puls      d,x,y,pc            Restore & return

* I$GetStt entry point
getstt              lda       PD.PST,y            Path status ok?
                    lbne      L04C6               No, terminate process
                    ldx       PD.RGS,y            Get register stack pointer
                    lda       R$B,x               Get function code
                    bne       L01F8               If not SS.Opt, call driver with function code
* ($00) SS.Opt Getstat - All of PD.OPT is already set up, *except* parity/baud, so we need to grab that
                    pshs      a,x,y               Preserve registers (LCB: why X? SS.ComSt doesn't use X)
                    lda       #SS.ComSt           Get code for Comstat
                    sta       R$B,x               Save it in callers B
                    ldu       R$Y,x               Preserve callers Y
                    pshs      u
                    bsr       L01F8               Call SS.ComSt GetStat in driver (puts parity/baud into callers Y)
                    puls      u                   Restore callers Y
                    puls      a,x,y               Restore registers
                    sta       R$B,x               Save SS.Opt code back into caller's B
                    ldd       R$Y,x               Get com stat (baud/parity)
                    stu       R$Y,x               Put original callers Y back
                    bcs       L01F6               Return if error
                    std       PD.PAR,y            Update path descriptor with baud/parity
L01F6               clrb                          Clear carry
L01F7               rts                           Return

* Execute device driver Get/Set Status routine
* Entry: A=GetStat/SetStat code
*        Y=path descriptor ptr
L01F8               ldb       #D$GSTA
L01FA               ldx       PD.DEV,y
                    ldu       V$STAT,x
                    pshs      d
                    ldx       V$DRIV,x            get driver module
                    ldd       M$EXEC,x
                    leax      d,x
                    puls      d
                    pshs      u,y
LC486               jsr       b,x
                    puls      y,u,pc

* I$SetStt entry point
setstt              lbsr      L04A2
L0212               bsr       L021B               Check codes
                    pshs      cc,b                Preserve registers
                    lbsr      L0453               Wait for device
                    puls      cc,b,pc             Restore & return

putkey              cmpa      #SS.Fill            Buffer preload?
                    bne       L01FA               No, go execute driver setstat
                    pshs      u,y,x
                    ldx       >D.Proc             Get current process pointer
                    lda       R$Y,u               Get flag byte for CR/NO CR
                    pshs      a                   Save it
loop                lda       ,x+
                    sta       ,u+
                    leay      -1,y
                    bne       loop
                    lda       ,s                  Get CR flag
                    bmi       putkey1             Don't want CR appended, exit
                    lda       #C$CR               Get code for carriage return
                    sta       b,u                 Put it in buffer to terminate string
putkey1             puls      a,x,y,u,pc          Eat stack & return

L021B               ldb       #D$PSTA             Get driver entry offset for setstat
                    lda       R$B,u               Get function code from caller
                    bne       putkey              Not SS.OPT, go check buffer load
* SS.OPT SETSTAT
                    ldx       PD.PAU,y            Get current pause & page
                    pshs      x,y
                    ldx       R$X,u
                    leay      PD.OPT,y
                    ldb       #OPTCNT
optloop             lda       ,x+
                    sta       ,y+
                    decb
                    bne       optloop
                    puls      x,y
                    pshs      x
                    ldd       PD.PAU,y            Get new page/pause status
                    cmpd      ,s++
                    beq       L0250               Yes, go on
                    ldu       PD.DEV,y            Get device table pointer
                    ldu       V$STAT,u            Get static storage pointer
                    beq       L0250               Go on if none
                    stb       V.LINE,u            Update new line count
L0250               ldx       PD.PAR,y            Get parity/baud
                    lda       #SS.ComSt           Get code for ComSt
                    pshs      a,x                 Preserve them
                    bsr       L025B               Update parity & baud
                    puls      a,x,pc              Restore & return

* Update path Parity & baud
L025B               pshs      x,y,u               Preserve everything
                    ldx       PD.RGS,y            Get callers register pointer
                    ldu       R$Y,x               Get his Y
                    lda       R$B,x               Get his B
                    pshs      a,x,y,u             Preserve it all
                    ldd       $10,s               Get current parity/baud
                    std       R$Y,x               Put it in callers Y
                    lda       $0F,s               Get function code
                    sta       R$B,x               Put it in callers B
                    lbsr      L04A7               Wait for device to be ready
                    lbsr      L0212               Send it to driver
                    puls      a,x,y,u             Restore callers registers
                    stu       R$Y,x               Put back his Y
                    sta       R$B,x               Put back his B
                    bcc       L0282               Return if no error
                    cmpb      #E$UnkSvc           Unknown service request?
                    beq       L0282               Yes, return
                    coma                          Set carry
L0282               puls      x,y,u,pc            Restore & return

* I$Read entry point
read                lbsr      L04A2               Go wait for device to be ready for us
                    bcc       L028A               No error, go on
L0289               rts                           Return with error

L028A               inc       PD.RAW,y            Make sure we do Raw read
                    ldx       R$Y,u               Get number of characters to read
                    beq       L02DC               Return if zero
                    pshs      x                   Save character count
                    ldx       #0
                    ldu       PD.BUF,y            Get buffer address
                    bsr       L03E2               Read 1 character from device
                    bcs       L02A4               Return if error
                    tsta                          Character read zero?
                    beq       L02C4               Yes, go try again
                    cmpa      PD.EOF,y            End of file character?
                    bne       L02BC               No, keep checking
L02A2               ldb       #E$EOF              Get EOF error code
L02A4               leas      2,s                 Purge stack
                    pshs      b                   Save error code
                    bsr       L02D5               Return
                    comb                          Set carry
                    puls      b,pc                Restore & return

******************************
*
* SCF file manager entry point
*
* Entry: Y = Path descriptor pointer
*        U = Callers register stack pointer
*

SCFEnt              lbra      open                Create path
                    lbra      open                Open path
                    lbra      bpnam               Makdir
                    lbra      bpnam               Chgdir
                    lbra      L0129               Delete (return no error)
                    lbra      L0129               Seek (return no error)
                    bra       read                Read character
                    nop
                    lbra      write               Write character
                    lbra      readln              ReadLn
                    lbra      writln              WriteLn
                    lbra      getstt              Get Status
                    lbra      setstt              Set Status
                    lbra      close               Close path

* MAIN READ LOOP (no editing)
L02AD               tfr       x,d                 move character count to D
                    tstb                          past buffer end?
                    bne       L02B7               no, go get character from device
* Not often used: only when buffer is full
                    bsr       L042B               move buffer to caller's buffer
                    ldu       PD.BUF,y            reset buffer pointer back to start
* Main char by char read loop
L02B7               bsr       L03E2               get a character from device
                    bcs       L02A4               exit if error
L02BC               ldb       PD.EKO,y            echo turned on?
                    beq       L02C4               no, don't write it to device
                    lbsr      L0565               send it to device write
L02C4               ldb       #1                  Bump up char count
                    abx
                    sta       ,u+                 save character in local buffer
                    beq       L02CF               go try again if it was a null
                    cmpa      PD.EOR,y            end of record charcter?
                    beq       L02D3               yes, return
L02CF               cmpx      ,s                  done read?
                    blo       L02AD               no, keep going till we are

L02D3               leas      2,s                 purge stack
L02D5               bsr       L042B               move local buffer to caller
                    ldu       PD.RGS,y            get register stack pointer
                    stx       R$Y,u               save number of characters read
L02DC               bra       L0453               update path descriptor and return

* Read character from device
L03E2               pshs      u,y,x               Preserve regs
                    ldx       PD.DEV,y            Get device table pointer for input
                    beq       L0401               None, exit
                    ldu       PD.DV2,y            Get device table pointer for echoed output
                    beq       L03F1               No echoed output device, skip ahead
L03EA               ldu       V$STAT,u            Get device static storage ptr for echo device
                    ldb       PD.PAG,y            Get lines per page
                    stb       V.LINE,u            Store it in device static
L03F1               tfr       u,d                 Yes, move echo device' static storage to D
                    ldu       V$STAT,x            Get static storage ptr for input
                    std       V.DEV2,u            Save echo device's static storage into input device
                    clra
                    sta       V.WAKE,u            Flag input device to be awake
                    pshs      d
                    ldx       V$DRIV,x            get driver module
                    ldd       M$EXEC,x            Get driver execution pointer
                    leax      d,x
                    puls      d
                    jsr       D$READ,x            Execute READ routine in driver
L0401               puls      pc,u,y,x            Restore regs & return

* Move buffer to caller
* Entry: Y=Path dsc. ptr
*        X=# chars to move
L042B               pshs      y,x                 Preserve path dsc. ptr & char. count
                    ldd       ,s                  Get # bytes to move
                    beq       L0451               Exit if none
                    tstb                          Uneven # bytes (not even page of 256)?
                    bne       L0435               Yes, go on
                    deca                          >256, so bump MSB down
L0435               clrb                          Force to even page
                    ldu       PD.RGS,y            Get callers register stack pointer
                    ldu       R$X,u               Get ptr to caller's buffer
                    leau      d,u
                    clra
                    ldb       1,s
                    bne       L0442               No, go on
                    inca
L0442               pshs      d
                    ldx       PD.BUF,y            Get buffer pointer
                    puls      y
                    pshs      u
L0443               lda       ,x+
                    sta       ,u+
                    leay      -1,y
                    bne       L0443
                    puls      u
L0451               puls      pc,y,x              Restore & return

* I$ReadLn entry point
readln              bsr       L04A2               Go wait for device to be ready for us
                    bcc       L02E5               No error, continue
                    rts                           Error, exit with it

L02E5               ldd       R$Y,u               Get character count
                    beq       L0453               If none, mark device as un-busy
                    tsta                          Past 256 bytes?
                    beq       L02EF               No, go on
                    ldd       #$0100              Get new character count
L02EF               pshs      d                   Save character count
                    ldd       #$FFFF              Get maximum character count
                    std       PD.MAX,y            Store it in path descriptor
                    ldx       #0                  Set character count so far to 0
                    ldu       PD.BUF,y            Get buffer ptr
                    lbra      L05F8               Go process readln

* Wait for device - Clears out V.BUSY if either Default or output devices are
* no longer busy
* Modifies X and A
L0453
                    ldx       >D.Proc             Get current process
                    lda       P$ID,x              Get it's process ID
                    ldx       PD.DEV,y            Get device table pointer from our path dsc.
                    bsr       L045D               Check if it's busy
                    ldx       PD.DV2,y            Get output device table pointer
L045D               beq       L0467               Doesn't exist, exit
                    ldx       V$STAT,x            Get static storage pointer for our device
                    cmpa      V.BUSY,x            Same process as current process?
                    bne       L0467               No, device busy return
                    clra
                    sta       V.BUSY,x            Yes, mark device as free for use
L0467               rts                           Return

L0468               pshs      x,a                 Preserve device table entry pointer & process ID
L046A               ldx       V$STAT,x            Get device static storage address
                    ldb       V.BUSY,x            Get active process ID
                    beq       L048A               No active process, device not busy go reserve it
                    cmpb      ,s                  Is it our own process?
                    beq       L049F               Yes, return without error
                    bsr       L0453               Go wait for device to no longer be busy
                    tfr       b,a                 Get process # busy using device
                    os9       F$IOQu              Put our process into the IO Queue
                    inc       PD.MIN,y            Mark device as not mine
                    ldx       >D.Proc             Get current process
                    ldb       P$Signal,x          Get signal code
                    lda       ,s                  Get our process id # again for L046A
                    beq       L046A               No signal go try again
                    coma                          Set carry
                    puls      x,a,pc              Restore device table ptr (eat a) & return

* Mark device as busy;copy pause/interrupt/quit/xon/xoff chars into static mem
L048A               sta       V.BUSY,x            Make it as process # busy on this device
                    sta       V.LPRC,x            Save it as the last process to use device
                    lda       PD.PSC,y            Get pause character from path dsc.
                    sta       V.PCHR,x            Save copy in static storage (faster later)
                    ldd       PD.INT,y            Get keyboard interrupt & quit chars
                    std       V.INTR,x            Save copies in static mem
                    ldd       PD.XON,y            Get XON/XOFF chars
                    std       V.XON,x             Save them in static mem too
L049F               clra                          No error & return
                    puls      pc,x,a              Restore A=Process #,X=Dev table entry ptr

* Wait for device?
L04A2               lda       PD.PST,y            Get path status (carrier)
                    bne       L04C4               If carrier was lost, hang up process
L04A7
                    ldx       >D.Proc             Get current process ID
                    clra
                    sta       PD.MIN,y            Flag device is mine
                    lda       P$ID,x              Get process ID #
                    ldx       PD.DEV,y            Get device table pointer
                    bsr       L0468               Busy?
                    bcs       L04C1               No, return
                    ldx       PD.DV2,y            Get output device table pointer
                    beq       L04BB               Go on if it doesn't exist
                    bsr       L0468               Busy?
                    bcs       L04C1               No, return
L04BB               lda       PD.MIN,y            Device mine?
                    bne       L04A2               No, go wait for it
                    sta       PD.RAW,y            Mark device with editing
L04C1               ldu       PD.RGS,y            Get register stack pointer
                    rts                           Return

* Hangup process
L04C4               leas      2,s                 Purge return address
L04C6               ldb       #E$HangUp           Get hangup error code
                    cmpa      #S$Abort            Termination signal (or carrier lost)?
                    blo       L04D3               Yes, increment status flag & return
                    lda       PD.CPR,y            Get current process ID # using path
                    ldb       #S$Kill             Get kill signal
                    os9       F$Send              Send it to process
L04D3               inc       PD.PST,y            Set path status
                    orcc      #Carry              Set carry
                    rts                           Return

* I$WritLn entry point
writln              bsr       L04A2               Go wait for device to be ready for us
                    bra       L04E1               Go write

* I$Write entry point
write               bsr       L04A2               Go wait for device to be ready for us
                    inc       PD.RAW,y            Mark device for raw write
L04E1               ldx       R$Y,u               Get number of characters to write
                    lbeq      L055A               Zero so return
                    pshs      x                   Save character count
                    ldx       #$0000              Get write data offset
                    bra       L04F1               Go write data

L04EC               tfr       u,d                 Move current position in PD.BUF to D
                    tstb                          At 256 (end of PD.BUF)?
                    bne       L0523               No, keep writing from current PD.BUF

* Get new block of data to write into [PD.BUF]
* Only allows up to 32 bytes at a time, and puts them in the last 32 bytes of
* the 256 byte [PD.BUF] buffer. This way, can use TFR U,D/TSTB to see if fin-
* ished.
* NOTE: 32 bytes max for 6809, to keep "lockout" of grfdrv down to less CPU time
L04F1               pshs      y,x                 Save write offset & path descriptor pointer
                    tfr       x,d                 Move data offset to D
                    ldu       PD.RGS,y            Get register stack pointer
                    ldx       R$X,u               Get pointer to user's WRITE string
                    leax      d,x                 Point to where we are in it now
                    ldd       R$Y,u               Get # chars of original write
                    subd      ,s                  Calculate # chars we have left to write
                    cmpd      #32                 More than 32?
                    bls       L0508               No, go on
                    ldd       #32                 Max size per chunk 6809=32
L0508               pshs      d                   Save buffered chunk size on stack
                    ldd       PD.BUF,y            Get buffer ptr
                    inca                          Point to PD.BUF+256 (1 byte past end)
                    subd      ,s                  Subtract data size
                    tfr       d,u                 Move it to U
                    lda       #C$CR               Put a carriage return 1 byte before start
                    sta       -1,u                of write portion of buffer
                    puls      y                   Move data to buffer (level 1)
                    pshs      u
L0509               lda       ,x+
                    sta       ,u+
                    leay      -1,y
                    bne       L0509
                    puls      u
                    puls      y,x                 Restore path descriptor pointer and data offset

* at this point, we have
* 0,s = end address of characters to write
* X = number of characters written
* Y = PD pointer
* U = pointer to data buffer to write
* Level 2: Use callcode $06 to call grfdrv (old DWProtSW from previous versions,
*   now unused by GrfDrv
L0523
L0524               lda       ,u+                 Get character to write
                    ldb       PD.RAW,y            Raw mode?
                    bne       L053D               Yes, go write it
                    ldb       PD.UPC,y            Force uppercase?
                    beq       L052A               No, continue
                    bsr       L0403               Make it uppercase
L052A               cmpa      #C$LF               Is it a Line feed?
                    bne       L053D               No, go print it
                    lda       #C$CR               Get code for carriage return
                    ldb       PD.ALF,y            Auto Line feed?
                    bne       L053D               Yes, go print carriage return first
                    bsr       L0573               Print carriage return
                    bcs       L055D               If error, go wait for device
                    lda       #C$LF               Now, print the line feed

* Write character to device (call driver)
L053D               bsr       L0573               Go write it to device
                    bcs       L055D               If error, go wait for device
                    ldb       #1                  Bump up # chars we have written
                    abx
L0544               cmpx      ,s                  Done whole WRITE call?
                    bhs       L0554               Yes, go save # chars written & exit
                    ldb       PD.RAW,y            Raw mode?
                    lbne      L04EC               Yes, keep writing
                    lda       -1,u                Get the char we wrote
                    lbeq      L04EC               NUL, keep writing
                    cmpa      PD.EOR,y            End of record?
                    lbne      L04EC               No, keep writing
L0554               leas      2,s                 Eof record, stop & Eat end of buffer ptr???
L0556               ldu       PD.RGS,y            Get callers register pointer
                    stx       R$Y,u               Save character count to callers Y
L055A               lbra      L0453               Mark device write clear and return

* Check for forced uppercase
L0403               cmpa      #'a                 Less then 'a'?
                    blo       L0412               Yes, leave it
                    cmpa      #'z                 Higher than 'z'?
                    bhi       L0412               Yes, leave it
                    suba      #$20                Make it uppercase
L0412               rts                           Return

L055D               leas      2,s                 Purge stack
                    pshs      b,cc                Preserve registers
                    bsr       L0556               Wait for device
                    puls      pc,b,cc             Restore & return

* Check for end of page (part of send char to driver)
L0573               pshs      u,y,x,a             Preserve registers
                    ldx       PD.DEV,y            Get device table pointer
                    cmpa      #C$CR               Carriage return?
                    bne       L056F               No, go print it
                    ldu       V$STAT,x            Get pointer to device stactic storage
                    ldb       V.PAUS,u            Pause request?
                    bne       L0590               Yes, go pause device
                    ldb       PD.RAW,y            Raw output mode?
                    bne       L05A2               Yes, go on
                    ldb       PD.PAU,y            End of page pause enabled?
                    beq       L05A2               No, go on
                    dec       V.LINE,u            Subtract a line
                    bne       L05A2               Not done, go on
                    ldb       #$ff                do a immediate pause request
                    stb       V.PAUS,u
                    bra       L059A               Go read next character

L03DA               pshs      u,y,x               Preserve registers
                    ldx       PD.DV2,y            Get output device table pointer
                    beq       NoOut               None, exit
                    ldu       PD.DEV,y            Get device table pointer
                    lbra      L03EA               Process & return

NoOut               puls      pc,u,y,x            No output device so exit

* Wait for pause release
L0590               bsr       L03DA               Read next character
                    bcs       L059A               Error, try again
                    cmpa      PD.PSC,y            Pause char?
                    bne       L0590               No, try again
L059A               bsr       L03DA               Reset line count and read a character
                    cmpa      PD.PSC,y            Pause character?
                    beq       L059A               Yes, go read again
* Process Carriage return - do auto linefeed & Null's if necessary
* Entry: A=CHR$($0D)
L05A2               ldu       V$STAT,x            Get static storage pointer
                    clra
                    sta       V.PAUS,u            Clear pause request
                    lda       #C$CR               Carriage return (in cases from pause)
                    bsr       L05C9               Send it to driver
                    lda       PD.RAW,y            Raw mode?
                    bne       L05C7               Yes, return
                    ldb       PD.NUL,y            Get end of line null count
                    pshs      b                   Save it
                    lda       PD.ALF,y            Auto line feed enabled?
                    beq       L05BE               No, go on
                    lda       #C$LF               Get line feed code
L05BA               bsr       L05C9               Execute driver write routine
                    bcs       L05C5               Error, purge stack and return
L05BE               clra                          Get null character
                    dec       ,s                  Done null count?
                    bpl       L05BA               No, go send it to driver
                    clra                          Clear carry
L05C5               leas      1,s                 Purge stack
L05C7               puls      pc,u,y,x,a          Restore & return

* Execute device driver write routine
* Entry: A=Character to write
* Execute device driver
* Entry: W=Entry offset (for type of function, ex. Write, Read)
*        A=Code to send to driver
L05C9               ldu       V$STAT,x            Get device static storage pointer
                    pshs      y,x                 Preserve registers
                    clrb
                    stb       V.WAKE,u            Wake it up
                    pshs      d
                    ldx       V$DRIV,x            Get driver execution pointer
                    ldd       M$EXEC,x
                    leax      d,x
                    puls      d
                    jsr       D$WRIT,x            Execute driver
                    puls      pc,y,x              Restore & return

* Send character to driver
L0565               pshs      u,y,x,a             Preserve registers
                    ldx       PD.DV2,y            Get output device table pointer
                    beq       L0571               Return if none
                    cmpa      #C$CR               Carriage return?
                    beq       L05A2               Yes, go process it
L056F               ldu       V$STAT,x            Get device static storage pointer
                    clrb
                    stb       V.WAKE,u            Wake it up
                    pshs      d
                    ldx       V$DRIV,x            get driver module
                    ldd       M$EXEC,x
                    leax      d,x
                    puls      d
                    jsr       D$WRIT,x            Execute driver
L0571               puls      pc,u,y,x,a          Restore & return


* Check for printable character (Entry: A=char to echo)
L0413               ldb       PD.EKO,y            Echo turned on?
                    bne       L0418               Yes, go do
                    rts                           No, just return

L0418               cmpa      #C$SPAC             CHR$(32) or higher?
                    bhs       L0565               Yes, go send to driver
                    cmpa      #C$CR               Ctrl char; is it a Carriage return?
                    beq       L0565               Yes, send it to the driver
* Any ctrl char <> CR, replace with period when echoed to device
L0423               pshs      a                   Save code
                    lda       #'.                 Get code for period
                    bsr       L0565               Output it to device
                    puls      pc,a                Restore original ctrl char & return

L0624               bsr       L0418               check if it's printable and send it to driver
* Process ReadLn
L05F8               lbsr      L03E2               get a character from device
                    lbcs      L0370               return if error
                    tsta                          usable character?
                    lbeq      L02FE               no, check path descriptor special characters
                    ldb       PD.RPR,y            get reprint line code
                    cmpb      #C$RPRT             cntrl D?
                    lbeq      L02FE               yes, check path descriptor special characters
                    cmpa      PD.RPR,y            reprint line?
                    bne       L0629               no, Check line editor keys
                    cmpx      PD.MAX,y            character count at maximum?
                    beq       L05F8               yes, go read next character
                    ldb       #1                  Bump char count up by 1
                    abx
                    cmpx      ,s                  done?
                    bhs       L0620               yes, exit
                    lda       ,u+                 get character read
                    beq       L0624               null, go send it to driver
                    cmpa      PD.EOR,y            end of record character?
                    bne       L0624               no, go send it to driver
                    leau      -1,u                bump buffer pointer back 1
L0620               leax      -1,x                bump character count back 1
                    bra       L05F8               go read next character

L0629               cmpa      #C$PLINE            Print rest of line code?
                    bne       L0647               No, check insert
* Process print rest of line
L062D               pshs      u                   Save buffer pointer
                    lbsr      L038B               Go print rest of line
                    lda       PD.BSE,y            Get backspace echo character
L0634               cmpu      ,s                  Beginning of buffer?
                    beq       L0642               Yes, exit
                    leau      -1,u                Bump buffer pointer back 1
                    leax      -1,x                Bump character count back 1
                    bsr       L0565               Print it
                    bra       L0634               Keep going

L0642               leas      2,s                 Purge buffer pointer
                    bra       L05F8               Return

L0647               cmpa      #C$INSERT           Insert character code?
                    bne       L0664               No, check delete
* Process Insert character (NOTE:Currently destroys W)
                    pshs      u
                    tfr       u,d                 Move buffer ptr to D
                    ldb       #$FF                Point to end of buffer
                    tfr       d,u                 Move back to U
L06DE               lda       ,-u                 shift buffer later by 1 char
                    sta       1,u
                    cmpu      ,s
                    bne       L06DE
                    lda       #C$SPAC             Insert space at insert point in buffer
                    sta       ,u
                    leas      2,s
                    bra       L062D               Go print rest of line

L0664               cmpa      #C$DELETE           Delete character code?
                    bne       L068B               No, check end of line
* Process delete line
                    pshs      u                   Save buffer pointer
                    lda       ,u                  Get character there
                    cmpa      PD.EOR,y            End of record?
                    beq       L0687               Yes, don't bother to delete it
L0671               lda       1,u                 Get character beside it
                    cmpa      PD.EOR,y            This an end of record?
                    beq       L067C               Yes, delete it
                    sta       ,u+                 Bump character back
                    bra       L0671               Go do next character

L067C               lda       #C$SPAC             Get code for space
                    cmpa      ,u                  Already there?
                    bne       L0685               No, put it in
                    lda       PD.EOR,y            Get end of record code
L0685               sta       ,u                  Put it there
L0687               puls      u                   Restore buffer pointer
                    bra       L062D               Go print rest of line

* Delete rest of buffer
L068B               cmpa      PD.EOR,y            End of record code? (normally CR)
                    bne       L02FE               No, check for special path dsc. chars
* CR hit, replace rest of buffer with spaces?
                    pshs      u                   Yes, Save buffer pointer
                    bra       L069F               Go erase rest of buffer

L0696               pshs      a                   Save CR code
                    lda       #C$SPAC             Get code for space
                    lbsr      L0565               Print it
                    puls      a                   Restore CR code
L069F               cmpa      ,u+                 End of record?
                    bne       L0696               No, go print a space
                    puls      u                   Restore buffer pointer
* Check character read against path descriptor
L02FE               tsta                          Usable character?
                    beq       L030C               No, go on
                    ldb       #PD.BSP             Get start point in path descriptor
L0303               cmpa      b,y                 Match code in descriptor?
                    beq       L032C               Yes, go process it
                    incb                          Move to next one
                    cmpb      #PD.QUT             Done check?
                    bls       L0303               No, keep going
L030C               cmpx      PD.MAX,y            Past maximum character count?
                    bls       L0312               No, go on
                    stx       PD.MAX,y            Update maximum character count
L0312               ldb       #1                  Add 1 char
                    abx
                    cmpx      ,s                  Past requested amount?
                    blo       L0322               No, go on
                    lda       PD.OVF,y            Get overflow character
                    lbsr      L0565               Send it to driver
                    leax      -1,x                Subtract a character
                    lbra      L05F8               Go try again

L0322               ldb       PD.UPC,y            Force uppercase?
                    beq       L0328               No, put char in buffer
                    lbsr      L0403               Make character uppercase
L0328               sta       ,u+                 Put character in buffer
                    lbsr      L0413               Check for printable
                    lbra      L05F8               Go try again

* Process path option characters
L032C               pshs      x,pc                Preserve character count & PC
                    leax      <L033F,pc           Point to branch table
                    subb      #PD.BSP             Subtract off first code
                    lslb                          Account for 2 bytes a entry
                    abx                           Point to entry point
                    stx       2,s                 Save it in PC on stack
                    puls      x                   Restore X
C8E3                jsr       [,s++]              Execute routine
                    lbra      L05F8               Continue on

* Vector points for PD.BSP-PD.QUT
L033F               bra       L03BB               Process PD.BSP
                    bra       L03A5               Process PD.DEL
                    bra       L0351               Process PD.EOR
                    bra       L0366               Process PD.EOF
                    bra       L0381               Process PD.RPR
                    bra       L038B               Process PD.DUP
                    rts                           PD.PSC we don't worry about
                    nop
                    bra       L03A5               Process PD.INT
                    bra       L03A5               Process PD.QUT

* Process PD.EOR character
L0351               leas      2,s                 Purge return address
                    sta       ,u                  Save character in buffer
                    lbsr      L0413
                    ldu       PD.RGS,y            Get callers register stack pointer
                    ldb       #1                  Bump up char count by 1
                    abx
                    stx       R$Y,u               Store it in callers Y
                    lbsr      L042B
                    leas      2,s
                    lbra      L0453

* Process PD.EOF
L0366               leas      2,s                 Purge return address
                    leax      ,x                  read anything?
                    lbeq      L02A2
                    bra       L030C

L0370               pshs      b
                    lda       #C$CR
                    sta       ,u
                    lbsr      L0565               Send it to the driver
                    puls      b
                    lbra      L02A4

* Process PD.RPR
L0381               lda       PD.EOR,y            Get end of record character
                    sta       ,u                  Put it in buffer
                    ldx       #0
                    ldu       PD.BUF,y            Get buffer ptr
L0388               lbsr      L0418               Send it to driver
L038B               cmpx      PD.MAX,y            Character maximum?
                    beq       L03A2               Yes, return
                    ldb       #1                  Bump char count up by 1
                    abx
                    cmpx      2,s                 Done count?
                    bhs       L03A0               Yes, exit
                    lda       ,u+                 Get character from buffer
                    beq       L0388               Null, go send it
                    cmpa      PD.EOR,y            Done line?
                    bne       L0388               No go send it
                    leau      -1,u                Move back a character
L03A0               leax      -1,x                Move character count back
L03A2               rts                           Return

L03A3               bsr       L03BF
* PD.DEL/PD.QUT/PD.INT processing
L03A5               leax      ,x                  Any characters?
                    beq       L03B8               No, reset buffer ptr
                    ldb       PD.DLO,y            Backspace over line?
                    beq       L03A3               Yes, go do it
                    ldb       PD.EKO,y            Echo character?
                    beq       L03B5               No, zero out buffer pointers & return
                    lda       #C$CR               Send CR to the driver
                    lbsr      L0565               send it to driver
L03B5               ldx       #0                  zero out count
L03B8               ldu       PD.BUF,y            reset buffer pointer
L03BA               rts                           return

* Process PD.BSP
L03BB               leax      ,x                  Any characters?
                    beq       L03A2               No, return
L03BF               leau      -1,u                Mover buffer pointer back 1 character
                    leax      -1,x                Move character count back 1
                    ldb       PD.EKO,y            Echoing characters?
                    beq       L03BA               No, return
                    ldb       PD.BSO,y            Which backspace method?
                    beq       L03D4               Use BSE
                    bsr       L03D4               Do a BSE
                    lda       #C$SPAC             Get code for space
                    lbsr      L0565               Send it to driver
L03D4               lda       PD.BSE,y            Get BSE
                    lbra      L0565               Send it to driver

                    emod
eom                 equ       *
                    end


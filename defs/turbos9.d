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

               IFNE      TURBOS9.D-1

TURBOS9.D      SET       1

               NAM       turbos9.d
               TTL       TurbOS9 system definitions

* Common definitions
true           EQU       1
false          EQU       0

               PAG       
*****************************************
* System service request code definitions
*
               ORG       0
F$Link         RMB       1                   Link to module
F$Load         RMB       1                   Load module from file
F$UnLink       RMB       1                   Unlink module
F$Fork         RMB       1                   Start new process
F$Wait         RMB       1                   Wait for child process to die
F$Chain        RMB       1                   Chain process to new module
F$Exit         RMB       1                   Terminate process
F$Mem          RMB       1                   Set memory size
F$Send         RMB       1                   Send signal to process
F$Icpt         RMB       1                   Set signal intercept
F$Sleep        RMB       1                   Suspend process
F$SSpd         RMB       1                   Suspend process
F$ID           RMB       1                   Return process ID
F$SPrior       RMB       1                   Set process priority
F$SSWI         RMB       1                   Set software interrupt
F$PErr         RMB       1                   Print error
F$PrsNam       RMB       1                   Parse pathlist name
F$CmpNam       RMB       1                   Compare two names
F$SchBit       RMB       1                   Search bit map
F$AllBit       RMB       1                   Allocate in bit map
F$DelBit       RMB       1                   Deallocate in bit map
F$Time         RMB       1                   Get current time
F$STime        RMB       1                   Set current time
F$CRC          RMB       1                   Generate CRC
               RMB       11
F$Debug        RMB       1                   Drop the system into the debugger

               ORG       $27                 Beginning of System Reserved Calls
* Common system calls
F$VIRQ         RMB       1                   Install/delete Virtual IRQ
F$SRqMem       RMB       1                   System memory request
F$SRtMem       RMB       1                   System memory return
F$IRQ          RMB       1                   Enter IRQ polling table
F$IOQu         RMB       1                   Enter I/O queue
F$AProc        RMB       1                   Enter active process queue
F$NProc        RMB       1                   Start next process
F$VModul       RMB       1                   Validate module
F$Find64       RMB       1                   Find process/path Descriptor
F$All64        RMB       1                   Allocate process/path descriptor
F$Ret64        RMB       1                   Return process/path descriptor
F$SSvc         RMB       1                   Service request table initialization
F$IODel        RMB       1                   Delete I/O module

*
* System calls $70 through $7F are reserved for user definitions
*
               ORG       $70
               RMB       16                  Reserved for user definition

               PAG       
**************************************
* I/O service request code definitions
*
               ORG       $80
I$Attach       RMB       1                   Attach I/O device
I$Detach       RMB       1                   Detach I/O device
I$Dup          RMB       1                   Duplicate path
I$Create       RMB       1                   Create new file
I$Open         RMB       1                   Open existing file
I$MakDir       RMB       1                   Make directory file
I$ChgDir       RMB       1                   Change default directory
I$Delete       RMB       1                   Delete file
I$Seek         RMB       1                   Change current position
I$Read         RMB       1                   Read data
I$Write        RMB       1                   Write data
I$ReadLn       RMB       1                   Read line of ASCII data
I$WritLn       RMB       1                   Write line of ASCII data
I$GetStt       RMB       1                   Get path status
I$SetStt       RMB       1                   Set path status
I$Close        RMB       1                   Close path
I$DeletX       RMB       1                   Delete from current exec dir

*******************
* File access modes
*
READ.          EQU       %00000001
WRITE.         EQU       %00000010
UPDAT.         EQU       READ.+WRITE.
EXEC.          EQU       %00000100
PREAD.         EQU       %00001000
PWRIT.         EQU       %00010000
PEXEC.         EQU       %00100000
SHARE.         EQU       %01000000
DIR.           EQU       %10000000
ISIZ.          EQU       %00100000

**************
* Signal codes
*
               ORG       0
S$Kill         RMB       1                   Non-interceptable abort
S$Wake         RMB       1                   Wake-up sleeping process
S$Abort        RMB       1                   Keyboard abort
S$Intrpt       RMB       1                   Keyboard interrupt

               PAG       
**********************************
* Status codes for GetStat/SetStat
*
               ORG       0
SS.Opt         RMB       1                   Read/Write path descriptor options
SS.Ready       RMB       1                   Check for device ready
SS.Size        RMB       1                   Read/write file size
SS.Reset       RMB       1                   Device restore
               RMB       1
SS.Pos         RMB       1                   Get file's current position
SS.EOF         RMB       1                   Test for end of file
SS.Link        RMB       1                   Link to status routines
SS.ULink       RMB       1                   Unlink status routines
               RMB       1
SS.Frz         RMB       1                   Freeze DD. information
SS.SPT         RMB       1                   Set DD.TKS to given value
               RMB       1
SS.DCmd        RMB       1                   Send direct command to disk
SS.DevNm       RMB       1                   Return device name (32-bytes at [X])
SS.FD          RMB       1                   Return file descriptor (Y-bytes at [X])
SS.Ticks       RMB       1                   Set lockout honor duration
SS.Lock        RMB       1                   Lock/release record
               RMB       1
               RMB       1
SS.BlkRd       RMB       1                   Block read
SS.BlkWr       RMB       1                   Block write
SS.Reten       RMB       1                   Retension cycle
SS.WFM         RMB       1                   Write file mark
SS.RFM         RMB       1                   Read past file mark
SS.ELog        RMB       1                   Read error log
SS.SSig        RMB       1                   Send signal on data ready
SS.Relea       RMB       1                   Release device
               RMB       1
               RMB       1
SS.RsBit       RMB       1                   Reserve bitmap sector (do not allocate in) LSB(X)=sct#
               RMB       1                   Reserved
               RMB       1
               RMB       3
               RMB       1
               RMB       1
               RMB       1
               RMB       1
SS.ComSt       RMB       1                   Getstat/SetStat for Baud/Parity
SS.Open        RMB       1                   SetStat to tell driver a path was opened
SS.Close       RMB       1                   SetStat to tell driver a path was closed
SS.HngUp       RMB       1                   SetStat to tell driver to hangup phone
SS.FSig        RMB       1                   New signal for temp locked files
               RMB       19

               TTL       Direct Page Definitions
               PAG       

**********************************
* Direct page variable definitions
*
               ORG       $00
               ORG       $20
D.FMBM         RMB       4                   Free memory bit map pointers
D.MLIM         RMB       2                   Memory limit
D.ModDir       RMB       4                   Module directory
D.Init         RMB       2                   ROM base address
D.SWI3         RMB       2                   SWI3 vector
D.SWI2         RMB       2                   Swi2 vector
D.FIRQ         RMB       2                   FIRQ vector
D.IRQ          RMB       2                   IRQ vector
D.SWI          RMB       2                   SWI vector
D.NMI          RMB       2                   NMI vector
D.SvcIRQ       RMB       2                   Interrupt service entry
D.Poll         RMB       2                   Interrupt polling routine
D.UsrIRQ       RMB       2                   User interrupt routine
D.SysIRQ       RMB       2                   System interrupt routine
D.UsrSvc       RMB       2                   User service request routine
D.SysSvc       RMB       2                   System service request routine
D.UsrDis       RMB       2                   User service request dispatch table
D.SysDis       RMB       2                   System service reuest dispatch table
D.Slice        RMB       1                   Process time slice count
D.PrcDBT       RMB       2                   Process descriptor block address
D.Proc         RMB       2                   Process descriptor address
D.AProcQ       RMB       2                   Active process queue
D.WProcQ       RMB       2                   Waiting process queue
D.SProcQ       RMB       2                   Sleeping process queue
D.Time         EQU       .                   Time
D.Year         RMB       1                   $53
D.Month        RMB       1                   $54
D.Day          RMB       1                   $55
D.Hour         RMB       1                   $56
D.Min          RMB       1                   $57
D.Sec          RMB       1                   $58
D.Tick         RMB       1                   $59
D.TSec         RMB       1                   Ticks / second
D.TSlice       RMB       1                   Ticks / time-slice
D.IOML         RMB       2                   I/O mgr free memory low bound
D.IOMH         RMB       2                   I/O mgr free memory hi  bound
D.DevTbl       RMB       2                   Device driver table addr
D.PolTbl       RMB       2                   Interrupt polling table addr
D.PthDBT       RMB       2                   Path descriptor block table addrress
D.BTLO         RMB       2                   Bootstrap low address
D.BTHI         RMB       2                   Bootstrap hi address
D.DMAReq       RMB       1                   DMA in use flag
               RMB       2
               RMB       2
               RMB       2
               RMB       16
D.Clock        RMB       2                   Address of clock tick routine
D.Boot         RMB       1                   Bootstrap attempted flag
D.URtoSs       RMB       2                   Address of user to system routine (VIRQ)
D.CLTb         RMB       2                   Pointer to clock interrupt table (VIRQ)
               RMB       1
D.CRC          RMB       1                   CRC checking mode flag
               RMB       2

               ORG       $100
D.XSWI3        RMB       3
D.XSWI2        RMB       3
D.XSWI         RMB       3
D.XNMI         RMB       3
D.XIRQ         RMB       3
D.XFIRQ        RMB       3

* Table Sizes
BMAPSZ         EQU       32                  Bitmap table size
SVCTNM         EQU       2                   Number of service request tables
SVCTSZ         EQU       (256-BMAPSZ)/SVCTNM-2 Service request table size

               TTL       Structure Formats
               PAG       
************************************
* Module directory entry definitions
*
               ORG       0
MD$MPtr        RMB       2                   Module pointer
MD$Link        RMB       2                   Module link count
MD$ESize       EQU       .                   Module directory entry size

************************************
* Module definitions
*
* Universal module offsets
*
               ORG       0
M$ID           RMB       2                   ID code
M$Size         RMB       2                   Module size
M$Name         RMB       2                   Module name
M$Type         RMB       1                   Type / language
M$Revs         RMB       1                   Attributes / revision level
M$Parity       RMB       1                   Header parity
M$IDSize       EQU       .                   Module ID size

*
* Type-dependent module offsets
*
* System, file manager, device driver, program module
*
M$Exec         RMB       2                   Execution entry offset
*
* Device driver, program module
*
M$Mem          RMB       2                   Stack requirement
*
* Device driver, device descriptor module
*
M$Mode         RMB       1                   Device driver mode capabilities
*
* Device descriptor module
*
               ORG       M$IDSize
M$FMgr         RMB       2                   File manager name offset
M$PDev         RMB       2                   Device driver name offset
               RMB       1                   M$Mode (defined above)
M$Port         RMB       3                   Port address
M$Opt          RMB       1                   Device default options
M$DTyp         RMB       1                   Device type
IT.DTP         EQU       M$DTyp              Descriptor type offset

*
* Configuration module entry offsets
*
               ORG       M$IDSize
MaxMem         RMB       3                   Maximum free memory
PollCnt        RMB       1                   Entries in interrupt polling table
DevCnt         RMB       1                   Entries in device table
InitStr        RMB       2                   Initial module name
SysStr         RMB       2                   System device name
StdStr         RMB       2                   Standard I/O pathlist
BootStr        RMB       2                   Bootstrap module name
ProtFlag       RMB       1                   Write protect enable flag

OSLevel        RMB       1                   OS level
OSVer          RMB       1                   OS version
OSMajor        RMB       1                   OS major
OSMinor        RMB       1                   OS minor
Feature1       RMB       1                   Feature byte 1
Feature2       RMB       1                   Feature byte 2
OSName         RMB       2                   OS revision name string (nul terminated)
InstallName    RMB       2                   Installation name string (nul terminated)
               RMB       4                   Reserved for future use

* Feature1 byte definitions
CRCOn          EQU       %00000001           CRC checking on
CRCOff         EQU       %00000000           CRC checking off

               PAG       
**************************
* Module field definitions
*
* ID field - first two bytes of a module
*
M$ID1          EQU       $87                 Module ID code byte one
M$ID2          EQU       $CD                 Module ID code byte two
M$ID12         EQU       M$ID1*256+M$ID2

*
* Module type/language field masks
*
TypeMask       EQU       %11110000           Type field
LangMask       EQU       %00001111           Language field

*
* Module type values
*
Devic          EQU       $F0                 Device descriptor module
Drivr          EQU       $E0                 Physical device driver
FlMgr          EQU       $D0                 File manager
Systm          EQU       $C0                 System module
Data           EQU       $40                 Data module
Sbrtn          EQU       $20                 Subroutine module
Prgrm          EQU       $10                 Program module

*
* Module language values
*
Objct          EQU       1                   Object code module

*
* Module attributes / revision byte
*
* Field masks
*
AttrMask       EQU       %11110000           Attributes field
RevsMask       EQU       %00001111           Revision level field

*
* Attribute flags
*
ReEnt          EQU       %10000000           Re-entrant module

********************
* Device type values
*
* These values define various classes of devices, which are
* managed by a file manager module.  The device type is embedded
* in a device descriptor.
*
DT.SCF         EQU       0                   Sequential Character File Manager
DT.RBF         EQU       1                   Random Block File Manager
DT.Pipe        EQU       2                   Pipe File Manager

*********************
* CRC result constant
*
CRCCon1        EQU       $80
CRCCon23       EQU       $0FE3

               TTL       Process Information
               PAG       
********************************
* Process descriptor definitions
*
DefIOSiz       EQU       12
NumPaths       EQU       16                  Number of Local Paths

               ORG       0
P$ID           RMB       1                   Process ID
P$PID          RMB       1                   Parent's ID
P$SID          RMB       1                   Sibling's ID
P$CID          RMB       1                   Child's ID
P$SP           RMB       2                   Stack pointer
P$CHAP         RMB       1                   Process chapter number
P$ADDR         RMB       1                   User address beginning page number
P$PagCnt       RMB       1                   Memory page count
P$User         RMB       2                   User index
P$Prior        RMB       1                   Priority
P$Age          RMB       1                   Age
P$State        RMB       1                   Status
P$Queue        RMB       2                   Queue link (process pointer)
P$IOQP         RMB       1                   Previous I/O queue link (process ID)
P$IOQN         RMB       1                   Next I/O queue link (process ID)
P$PModul       RMB       2                   Primary module
P$SWI          RMB       2                   SWI entry point
P$SWI2         RMB       2                   SWI2 entry point
P$SWI3         RMB       2                   SWI3 entry point
P$DIO          RMB       DefIOSiz            Default I/O pointers
P$PATH         RMB       NumPaths            I/O path table
P$Signal       RMB       1                   Signal code
P$SigVec       RMB       2                   Signal intercept vector
P$SigDat       RMB       2                   Signal intercept data address
P$NIO          RMB       4
               RMB       $40-.               unused
P$Size         EQU       .                   Size of process descriptor

*
* Process state flags
*
SysState       EQU       %10000000
TimSleep       EQU       %01000000
TimOut         EQU       %00100000
ImgChg         EQU       %00010000
Condem         EQU       %00000010
Dead           EQU       %00000001

               TTL       I/O Definitions
               PAG       
*************************
* Path descriptor offsets
*
               ORG       0
PD.PD          RMB       1                   Path number
PD.MOD         RMB       1                   Mode (read/write/update)
PD.CNT         RMB       1                   Number of open images
PD.DEV         RMB       2                   Device table entry address
PD.CPR         RMB       1                   Current process
PD.RGS         RMB       2                   Caller's register stack
PD.BUF         RMB       2                   Buffer address
PD.FST         RMB       32-.                File manager's storage
PD.OPT         EQU       .                   PD GetSts(0) options
PD.DTP         RMB       1                   Device type
               RMB       64-.                Path options
PDSIZE         EQU       .

*
* Pathlist special symbols
*
PDELIM         EQU       '/                  Pathlist name separator
PDIR           EQU       '.                  Directory
PENTIR         EQU       '@                  Entire device

               PAG       
****************************
* File manager entry offsets
*
               ORG       0
FMCREA         RMB       3                   Create (open new) file
FMOPEN         RMB       3                   Open file
FMMDIR         RMB       3                   Make directory
FMCDIR         RMB       3                   Change directory
FMDLET         RMB       3                   Delete file
FMSEEK         RMB       3                   Position file
FMREAD         RMB       3                   Read from file
FMWRIT         RMB       3                   Write to file
FMRDLN         RMB       3                   Read line
FMWRLN         RMB       3                   Write line
FMGSTA         RMB       3                   Get file status
FMSSTA         RMB       3                   Set file status
FMCLOS         RMB       3                   Close file

*****************************
* Device driver entry offsets
*
               ORG       0
D$INIT         RMB       3                   Device Initialization
D$READ         RMB       3                   Read from Device
D$WRIT         RMB       3                   Write to Device
D$GSTA         RMB       3                   Get Device Status
D$PSTA         RMB       3                   Put Device Status
D$TERM         RMB       3                   Device Termination

*********************
* Device table format
*
               ORG       0
V$DRIV         RMB       2                   Device driver module
V$STAT         RMB       2                   Device driver static storage
V$DESC         RMB       2                   Device descriptor module
V$FMGR         RMB       2                   File manager module
V$USRS         RMB       1                   Use count
DEVSIZ         EQU       .

*******************************
* Device static storage offsets
*
               ORG       0
V.PAGE         RMB       1                   Port extended address
V.PORT         RMB       2                   Device 'base' port address
V.LPRC         RMB       1                   Last active process ID
V.BUSY         RMB       1                   Active process ID (0=UnBusy)
V.WAKE         RMB       1                   Active process descriptor if driver MUST wake-up
V.USER         EQU       .                   Driver allocation origin

********************************
* Interrupt polling table format
*
               ORG       0
Q$POLL         RMB       2                   Absolute polling address
Q$FLIP         RMB       1                   Flip (EOR) byte; normally zero
Q$MASK         RMB       1                   Polling mask (after flip)
Q$SERV         RMB       2                   Absolute service routine Address
Q$STAT         RMB       2                   Static storage address
Q$PRTY         RMB       1                   Priority (low numbers=top priority)
POLSIZ         EQU       .

********************
* VIRQ packet format
*
               ORG       0
Vi.Cnt         RMB       2                   Count down counter
Vi.Rst         RMB       2                   Reset value for counter
Vi.Stat        RMB       1                   Status byte
Vi.PkSz        EQU       .

Vi.IFlag       EQU       %00000001           status byte virq flag

               PAG       
*************************************
* Machine characteristics definitions
*
R$CC           EQU       0                   Condition codes register
R$A            EQU       1                   A accumulator
R$B            EQU       2                   B accumulator
R$D            EQU       R$A                 Combined A:B accumulator
R$DP           EQU       3                   Direct page register
R$X            EQU       4                   X index register
R$Y            EQU       6                   Y index register
R$U            EQU       8                   User stack register
R$PC           EQU       10                  Program counter register
R$Size         EQU       12                  Total register package size

Entire         EQU       %10000000           Full register stack flag
FIRQMask       EQU       %01000000           Fast-interrupt mask bit
HalfCrry       EQU       %00100000           Half carry flag
IRQMask        EQU       %00010000           Interrupt mask bit
Negative       EQU       %00001000           Negative flag
Zero           EQU       %00000100           Zero flag
TwosOvfl       EQU       %00000010           Two's complement overflow flag
Carry          EQU       %00000001           Carry bit
IntMasks       EQU       IRQMask+FIRQMask
Sign           EQU       %10000000           Sign bit

               TTL       Error code definitions
               PAG       
************************
* Error code definitions
*
               ORG       200
E$PthFul       RMB       1                   Path table full
E$BPNum        RMB       1                   Bad path Number
E$Poll         RMB       1                   Polling table Full
E$BMode        RMB       1                   Bad Mode
E$DevOvf       RMB       1                   Device table overflow
E$BMID         RMB       1                   Bad module ID
E$DirFul       RMB       1                   Module directory full
E$MemFul       RMB       1                   Process memory full
E$UnkSvc       RMB       1                   Unknown service code
E$ModBsy       RMB       1                   Module busy
E$BPAddr       RMB       1                   Bad page address
E$EOF          RMB       1                   End of file
               RMB       1
E$NES          RMB       1                   Non-existing segment
E$FNA          RMB       1                   File not accesible
E$BPNam        RMB       1                   Bad path name
E$PNNF         RMB       1                   Path name Not Found
E$SLF          RMB       1                   Segment list full
E$CEF          RMB       1                   Creating existing file
E$IBA          RMB       1                   Illegal block address
               RMB       1
E$MNF          RMB       1                   Module not found
               RMB       1
E$DelSP        RMB       1                   Deleting stack pointer memory
E$IPrcID       RMB       1                   Illegal process ID
E$BPrcID       EQU       E$IPrcID            Bad process ID
               RMB       1
E$NoChld       RMB       1                   No children
E$ISWI         RMB       1                   Illegal SWI code
E$PrcAbt       RMB       1                   Process aborted
E$PrcFul       RMB       1                   Process table full
E$IForkP       RMB       1                   Illegal fork parameter
E$KwnMod       RMB       1                   Known module
E$BMCRC        RMB       1                   Bad module CRC
E$USigP        RMB       1                   Unprocessed signal pending
E$NEMod        RMB       1                   Non existing module
E$BNam         RMB       1                   Bad name
E$BMHP         RMB       1                   Bad module header parity
E$NoRAM        RMB       1                   No system RAM available
E$DNE          RMB       1                   Directory not empty
E$NoTask       RMB       1                   No available task number
               RMB       $F0-.               Reserved
E$Unit         RMB       1                   Illegal media unit
E$Sect         RMB       1                   Bad sector number
E$WP           RMB       1                   Write protect
E$CRC          RMB       1                   Bad checksum
E$Read         RMB       1                   Read error
E$Write        RMB       1                   Write error
E$NotRdy       RMB       1                   Device not ready
E$Seek         RMB       1                   Seek error
E$Full         RMB       1                   Media full
E$BTyp         RMB       1                   Bad type (incompatable) media
E$DevBsy       RMB       1                   Device busy
E$DIDC         RMB       1                   Media ID change
E$Lock         RMB       1                   Record is busy (locked out)
E$Share        RMB       1                   Non-sharable file busy
E$DeadLk       RMB       1                   I/O deadlock error

* Character definitions
C$SPACE        SET       $20
C$PERIOD       SET       '.
C$COMMA        SET       ',

               ENDC      

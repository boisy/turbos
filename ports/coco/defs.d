* Assemble-time capability flags
*
* Feature Flags - eliminating one or more of these capabilities saves code space.
*
* Manage your own interrupts or install interrupt service routines using F$IRQ.
_FF_IRQ_POLL   equ       1                   Set to 1 for interrupt service routine polling

* Use virtual interrupt service routines using F$VIRQ.
_FF_VIRQ_POLL  equ       1                   Set to 1 for virtual interrupt service routine polling

* Wall time gives year/month/date/hour/minute/second support.
_FF_WALLTIME   equ       1                   Set to 1 for a software wall time clock

* Module CRC and header parity checks are useful for integrity, but slows down loading.
_FF_MODCHECK   equ       1                   Set to 1 for module header and CRC checking

* Unified I/O adds a standard device interface at the expense of more memory.
_FF_UNIFIED_IO equ       1                   Set to 1 for unified I/O

* Booting from an external storage device can bring in additional functionality.
_FF_BOOTING    equ       1                   Set to 1 for bootfile loading

* User IDs are useful for multi-user configurations.
_FF_ID         equ       1                   Set to 1 to support user IDs

* Without this system call, all processes run at priority 128.
_FF_SPRIOR      equ      1                   Set to 1 to support setting process priority

* Setting the software interrupt vector is not typically needed.
_FF_SSWI        equ       1                   Set to 1 to support setting software interrupt vector

* TurbOS system definitions
               use       turbos.d

* CoCo specific definitions

* CoCo mapped I/O boundaries
MappedIOStart  equ       $FF00
MappedIOEnd    equ       $FFEF

* CoCo ticks per second support
TkPerSec       set       60

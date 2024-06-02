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

;;; F$AProc
;;;
;;; Insert process into active process queue.
;;;
;;; Entry:  X = The address of the process descriptor to insert.
;;;
;;; Exit:   None.
;;;
;;; Error:  B = A non-zero error code.
;;;        CC = Carry flag set to indicate error.
;;;
;;; F$AProc inserts a process into the active process queue so that the kernel can schedule the process for execution.
;;; The kernel sorts all processes in the queue by process age (the count of how many process switches have occurred 
;;; since the process’s last time slice). When a process moves to the active process queue, the kernel sets its age
;;; according to its priority. The higher the priority, the higher the age.
;;;
;;; An exception is a newly active process that was deactivated while in the system state. The kernel gives such a process
;;; higher priority because it's typically executing critical routines that affect shared system resources.

FAProc         ldx       R$X,u               get the pointer to process to insert
SFAProc        pshs      u,y                 save U/Y on stack
               ldu       #(D.AProcQ-P$Queue) load U with D.AProcQ-P$Queue so we're at the first process in the queue later
               bra       getqueue@           start processing the active queue
* This loop increases the age of all active processes by 1.
ageloop@       ldb       P$Age,u             get the process age
               incb                          update it
               beq       getqueue@           branch if wrap
               stb       P$Age,u             save it back to the process descriptor
getqueue@      ldu       P$Queue,u           get the pointer to the next process in the queue
               bne       ageloop@            branch if the process is in the active queue
               ldu       #(D.AProcQ-P$Queue) load U with D.AProcQ-P$Queue so we're at the first process in the queue later
               lda       P$Prior,x           get process priority of process to insert
               sta       P$Age,x             save it as its age
               orcc      #IntMasks           mask interrupts
* This loop finds the process with the age lower than our age in the queue and inserts us
* in front of them.
loop2@         leay      ,u                  point Y to the process descriptor
               ldu       P$Queue,u           get the pointer to the next process in active queue
               beq       ex@                 branch if empty
               cmpa      P$Age,u             compare the passed process' age to the current one in the queue
               bls       loop2@              if it's lower or same, keep going
ex@            stu       P$Queue,x           insert the process with lower age as the next one into the P$Queue of the passed process
               stx       P$Queue,y           and put the passed process descriptor pointer in the current location
               clrb                          clear carry
               puls      pc,u,y              restore U/Y and return


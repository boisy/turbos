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

;;; F$Mem
;;;
;;; Change the process' data area size.
;;;
;;; Entry: D = The size to expand or contract the memory area to (0 = return the current size).
;;;
;;; Exit: Y = The address of the new memory area's upper bound.
;;; D = The size of the new memory area, in bytes.
;;; CC = Carry flag clear to indicate success.
;;;
;;; Error: B = A non-zero error code.
;;; CC = Carry flag set to indicate error.
;;;
;;; F$Mem expands or contracts the process’ data memory area to the specified size. If you specify zero as the new size,
;;; the current size and upper boundaries of data memory are returned.
;;;
;;; F$Mem rounds the size up to the next page boundary. Allocating additional memory continues upward from the previous
;;; highest address. Deallocating unneeded memory continues downward from that address.

FMem ldx <D.Proc get the current process descriptor
 ldd R$A,u get the size of the requested memory area
 beq returnsize@ branch if 0; caller is requesting size
 bsr RoundUpD round up requested memory area to the next page; clear A
 subb P$PagCnt,x subtract the current page count from B; now holds amount to add/shrink
 beq returnsize@ branch if 0; nothing more to allocate
 bcs memshrink@ branch if less than 0; we're shrinking memory
 tfr d,y else we're adding memory; transfer the additional request to Y
 ldx P$ADDR,x get the process' base data address page and page count in X
 pshs u,y,x save off registers
_stkPageAddr@ set 0 bits 15-8 of X (P$ADDR)
_stkPageCnt@ set 1 bits 7-0 of X (P$PagCnt)
_stkStrtPg@ set 2 bits 15-8 of Y (initially $00; used as starting page of memory to allocate)
_stkReqPg@ set 3 bits 7-0 of Y (additional pages needed to fulfill request)
 ldb _stkPageAddr@,s get the page address from the stack
 beq L01E1 branch if it's 0
 addb _stkPageCnt@,s add it to the page count from the stack
L01E1 ldx <D.FMBM get the address of the start of the free memory bitmap
 ldu <D.FMBM+2 and the address of the end of the free memory bitmap
 os9 F$SchBit search for the location
 bcs ex@ branch if there was an error
 stb _stkStrtPg@,s B = starting page of potentially allocated memory; save it to the stack
 ldb _stkPageAddr@,s get the page address from the stack
 beq L01F6 branch if 0
 addb _stkPageCnt@,s add it to the page count from the stack (points to last page of memory + 1)
 cmpb _stkStrtPg@,s compare it to the starting page of the potentially allocated memory
 bne ex@ should be the same; if not, we're out of memory so branch
L01F6 ldb _stkStrtPg@,s get the starting page of the potentially allocated memory
 os9 F$AllBit allocate the bits in the memory map
 ldd _stkStrtPg@,s get the starting page of the now-allocated memory in A and the requested additional amount in B
 suba _stkPageCnt@,s subtract the page count on the stack from the starting page of the now-allocated memory
 addb _stkPageCnt@,s add the page count to the requested additional amount... this is the total amount
 puls u,y,x restore the registers
 ldx <D.Proc get the current process descriptor
 bra L0225 jump around shrink code
* If we get here, the caller is asking for LESS memory, so shrinking the process' amount.
memshrink@ negb negate the number of pages
 tfr d,y put D in Y
 negb restore the negated number of pages
 addb P$PagCnt,x add the page count to B
 addb P$ADDR,x and the base data address page to B
 cmpb P$SP,x compare it to the caller's stack pointer
 bhi L0217 branch if we're higher
 comb else set the carry flag
 ldb #E$DelSP return an error indicating the requested size would overrun the stack
 rts return to the caller
L0217 ldx <D.FMBM get the free memory bitmap pointer
 os9 F$DelBit delete the bits
 tfr y,d transfer # of bits to clear into D
 negb negate B
 ldx <D.Proc get the current process descriptor
 addb P$PagCnt,x add the page count
 lda P$ADDR,x get the process' base data address page
L0225 std P$ADDR,x store the process' base data address page and page count
returnsize@ lda P$PagCnt,x get the page count
 clrb clear B
 std R$D,u save off the current memory area in the caller's D
 adda P$ADDR,x add the address to A
 std R$Y,u and store it to the caller's Y
 rts return to the caller
ex@ comb set the carry flag
 ldb #E$MemFul indicate memory is full
 puls pc,u,y,x restore registers and return to the caller

* Round up to the next page, then swap A and B
* Example: A=$10, B=$33; result is A=$00, B=$11
RoundUpD addd #$00FF add 255 to D
 clrb clear B
 exg a,b swap the registers
 rts return to the caller

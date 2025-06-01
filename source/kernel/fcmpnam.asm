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

;;; F$CmpNam
;;;
;;; Compare two names for a match.
;;;
;;; Entry: B = The length of the first name.
;;; X = The address of the first name.
;;; Y = The address of the second name.
;;;
;;; Exit: CC = Carry flag clear if names match; set if names don't match.
;;;
;;; F$CmpNam compares two names and indicates whether they match. Use this call with F$PrsNam. The second name
;;; must have the most significant bit of the last character set.

FCmpNam ldb R$B,u get length of the first name
 leau R$X,u point U to the caller's R$X
 pulu y,x load caller's R$X and R$Y into X and Y in one call
CmpNam pshs y,x,b,a save registers
loop@ lda ,y+ get character of second name and increment pointer
 bmi hibitset@ branch if hi-bit set
 decb decrement length
 beq nomatch@ if counter is zero, length is different, so not a match
 eora ,x+ XOR with character in same position from first name and increment pointer
 anda #$DF make result case insensitive
 beq loop@ if zero, characters match, so continue to next character
nomatch@ orcc #Carry set carry to indicate no match
 puls pc,y,x,b,a restore registers and return to caller
hibitset@ decb more?
 bne nomatch@ branch if so, length is different so not a match.
 eora ,x XOR with character in same position from first name
 anda #$5F make result case insensitive
 bne nomatch@ if not zero, not a match
 puls y,x,b,a restore registers
Match andcc #^Carry clear carry to indicate a match
 rts return to caller

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

;;; F$PrsNam
;;;
;;; Parse a pathlist.
;;;
;;; Entry:  X = The address of the pathlist to parse.
;;;         U = Starting address of the routine’s memory area.
;;;
;;; Exit:   X = The address of the character past the optional "/".
;;;         Y = The address of the last character plus one.
;;;         A = The trailing delimiter character.
;;;         B = The length of the pathlist.
;;;        CC = Carry flag clear to indicate success.
;;;
;;; Error:  B = A non-zero error code.
;;;         Y = The address of the first non-delimiter character.
;;;        CC = Carry flag set to indicate error.
;;;
;;; F$PrsNam scans the input text string for a legal name. It terminates the name with any character that is not a legal name character.
;;; It's useful for processing pathlist arguments passed to a new process.
;;; Because it processes only one name, you need several calls to process a pathlist that has more than one name. 
;;; F$PrsNam completes with Y in position for the next element in the pathlist to parse.
;;; If  Y is at the end of a pathlist, a bad path error returns.
;;; It then moves the pointer in Y past any space characters so that it can parse the next pathlist in a command line.
;;;
;;; Before the Parse Name call:
;;;
;;; |  /  |  D  |  0  |  /  |  P  |  A  |  Y  |  R  |  O  |  L  |  L  |
;;;    X	 	 	 	 	 	 	 	 	 	 
;;;
;;; After the Parse Name call:
;;;
;;; |  /  |  D  |  0  |  /  |  P  |  A  |  Y  |  R  |  O  |  L  |  L  |
;;;          X	     Y              B = 2 	 	 	 	 	 	 	 	 	 

FPrsNam        ldx       R$X,u               get pathlist pointer from caller
               bsr       ParseNam            do the parsing of the name
               std       R$D,u               save the length
               bcs       ex@                 branch if the carry is set
               stx       R$X,u               save the updated pathlist pointer
ex@            sty       R$Y,u               and the Y
               rts                           return to the caller

ParseNam       lda       ,x                  get the first character
               cmpa      #PDELIM             is it the pathlist character?
               bne       next@               branch if not
               leax      1,x                 else go past it
next@          leay      ,x                  point Y to X
               clrb                          clear B
               lda       ,y+                 get the next character
               anda      #$7F                mask out the high bit
               bsr       chkrest@            go check the rest
               bcs       comma@              branch if the carry is set
loop@          incb                          increment B
               lda       -1,y                get the previous character
               bmi       ex@                 if high bit is set on this character, we're done
               lda       ,y+                 else get the next character
               anda      #$7F                clear the high bit
               bsr       chkfirst@           and check first
               bcc       loop@               branch if the carry is clear
               lda       ,-y                 else get the previous character
ex@            andcc     #^Carry             clear the carry
               rts                           return to the caller
comma@         cmpa      #C$COMMA            is it a comma?
               bne       space@              branch if not
skip@          lda       ,y+                 else get the next character
space@         cmpa      #C$SPACE            is it a space?
               beq       skip@               branch if so
               lda       ,-y                 else get the previous character
               comb                          set the carry
               ldb       #E$BNam             indicate a bad pathname error
               rts                           and return to the caller
* Check for legal characters in a pathlist
chkfirst@      cmpa      #C$PERIOD           is the character a period?
               beq       Match               branch if so
chkrest@       cmpa      #'0                 is it zero?
               bcs       errex@              branch if less than
               cmpa      #'9                 is it a number?
               bls       Match               branch if it is between 0-9
               cmpa      #'_                 is it an underscore?
               beq       Match               branch if so
               cmpa      #'A                 is it A?
               bcs       errex@              branch if less than
               cmpa      #'Z                 is it Z?
               bls       Match               branch if less than or equal (A-Z)
               cmpa      #'a                 is it a?
               bcs       errex@              branch if less than
               cmpa      #'z                 is it z?
               bls       Match               branch if less than or equal (a-z)
errex@         orcc      #Carry              set the carry
               rts                           return to the caller

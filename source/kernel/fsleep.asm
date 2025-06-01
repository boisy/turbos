* F$Sleep
FSleep ldx <D.Proc get pdesc
 orcc #FIRQMask+IRQMask mask ints
 lda P$Signal,x get proc signal
 beq L02EE branch if none
 deca dec signal
 bne L02E9 branch if not S$Wake
 sta P$Signal,x clear signal
L02E9 os9 F$AProc insert into activeq
 bra L034D
L02EE ldd R$X,u get timeout
 beq L033A branch if forever
 subd #$0001 subtract 1
 std R$X,u save back to caller
 beq L02E9 branch if give up tslice
 pshs u,x
 ldx #(D.SProcQ-P$Queue)
L02FE leay ,x
 ldx P$Queue,x
 beq L0316
 pshs b,a
 lda P$State,x
 bita #TimSleep
 puls b,a
 beq L0316
 ldu P$SP,x
 subd R$X,u
 bcc L02FE
 addd R$X,u
L0316 puls u,x
 std R$X,u
 ldd P$Queue,y
 stx P$Queue,y
 std P$Queue,x
 lda P$State,x
 ora #TimSleep
 sta P$State,x
 ldx P$Queue,x
 beq L034D
 lda P$State,x
 bita #TimSleep
 beq L034D
 ldx P$SP,x
 ldd P$SP,x
 subd R$X,u
 std P$SP,x
 bra L034D
L033A lda P$State,x
 anda #^TimSleep
 sta P$State,x
 ldd #(D.SProcQ-P$Queue)
L0343 tfr d,y
 ldd P$Queue,y
 bne L0343
 stx P$Queue,y
 std P$Queue,x
L034D leay <L0361,pcr
 pshs y
 ldy <D.Proc
 ldd P$SP,y
 ldx R$X,u
 ifne H6309
 pshs u,y,x,dp
 pshsw 
 pshs b,a,cc
 else 
 pshs u,y,x,dp,b,a,cc
 endc 
 sts P$SP,y
 os9 F$NProc
L0361 std P$SP,y
 stx R$X,u
 clrb 
 rts 

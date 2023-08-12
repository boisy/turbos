* CoCoLoader - Loads the TurbOS kernel into a CoCo running Disk Extended Color BASIC
*
* This program move the kernel into high RAM then jumps to the kernel.
Start          equ       $4000

               org       Start

* Get CoCo ready
               orcc      #$50                mask interrupts
               clr       $FFDF               put CoCo in All-RAM mode

* Compute load address for kernel blob
               clra      
               clrb      
               subd      #KernelSize+$100    compensate for $FF00 (don't want to write there)
               clrb      
               pshs      d

* Copy blob of code over to upper RAM
               leax      Kernel,pcr
               ldu       ,s
               ldy       #KernelSize
loop@          lda       ,x+
               sta       ,u+
               leay      -1,y
               bne       loop@

* Jump into the kernel
               puls      x
               ldd       9,x                 M$Exec offset into kernel module
               leax      d,x
               jmp       ,x

Kernel         equ       *

* Include the assembly dump of the kernel here
               use       kernel.dump

KernelSize     equ       *-Kernel

               end       Start

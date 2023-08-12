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

IOCall                   
               ifne      _FF_UNIFIED_IO
               pshs      u,y,x,b,a           save off registers
               ldu       <D.Init             get pointer to the init module
               bsr       link@               link to IOMan
               ifne      _FF_BOOTING
               bcc       callit@             jump into IOMan if it exists
               bsr       LoadBoot            else attempt to load the bootfile
               bcs       ex@                 problem booting... return w/ error
               bsr       link@               ok, NOW link to IOMan
               endc      
               bcs       ex@                 still a problem...
callit@        jsr       ,y                  call into IOMan
               puls      u,y,x,b,a           restore registers
               ldx       -2,y                get the location to jump
               jmp       ,x                  and jump
ex@            puls      pc,u,y,x,b,a        else restore registers and return
link@          leax      IOMgr,pcr           point to the IO manager module name
               lda       #Systm+Objct        it should be a system/object module
               os9       F$Link              link to it
               rts                           return if there was an error
IOMgr          fcs       /IOMAN/
               else      
               rts                           return to caller (do nothing)      
               endc      

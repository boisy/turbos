PORTNAME	= coco

ifndef TURBOSDIR
	TURBOSDIR=$(HOME)/Projects/turbos
endif

include $(TURBOSDIR)/ports/rules.mak

VPATH=$(TURBOSDIR)/source/modules $(TURBOSDIR)/source/commands $(TURBOSDIR)/source/kernel $(TURBOSDIR)/tests 

AFLAGS += -DPORTNAME="$(PORTNAME)" -D$(PORTNAME)

COMMANDS	= go
MODULES	= kernel init tkcc
OBJS	= $(MODULES) $(COMMANDS)

all:	dsk

KERNEL_SOURCES = kernel.asm fallbit.asm faproc.asm fchain.asm fcmpnam.asm fcrc.asm \
	ffork.asm flink.asm fnproc.asm fprsnam.asm fsrqmem.asm fssvc.asm \
	fvmodul.asm firq.asm \
	iocall.asm funlink.asm fwait.asm fexit.asm fmem.asm fsend.asm fsleep.asm \
	ficpt.asm fsprior.asm fid.asm fsswi.asm \
	ffind64.asm fall64.asm fret64.asm

MODULE_SOURCES	= init.asm tkcc.asm

kernel: $(KERNEL_SOURCES)

lint: *.asm $(KERNEL_SOURCES) $(MODULE_SOURCES)
	$(foreach file,$^,mamou -ls -p $(file) > /tmp/lint.out; mv /tmp/lint.out $(file) ;)

dsk: $(OBJS)
	cat $(OBJS) > kernel.rom
	os9 dump -a kernel.rom > kernel.dump
	$(ASBIN) $(AFLAGS) cocoloader.asm $(ASOUT)cocoloader
	decb dskini turbos.dsk
	echo "10 LOADM\"KERNEL.BIN\":EXEC" > /tmp/loader.bas
	decb copy -b -0 -t /tmp/loader.bas turbos.dsk,\*.BAS
	decb copy -b -2 cocoloader turbos.dsk,KERNEL.BIN

clean:
	-$(RM) $(OBJS) kernel.rom kernel.dump cocoloader *.dsk

gh:
	open "http://www.github.com/boisy/turbos"

PORTNAME	= turbo9sim

ifndef TURBOSDIR
	TURBOSDIR=$(HOME)/Projects/turbos
endif

include $(TURBOSDIR)/ports/rules.mak

VPATH=$(TURBOSDIR)/source/modules $(TURBOSDIR)/source/commands $(TURBOSDIR)/source/kernel $(TURBOSDIR)/tests

AFLAGS += -DPORTNAME="$(PORTNAME)" -D$(PORTNAME)

COMMANDS	= go
KERNEL	= kernel init tkt9sim
UIO	= kernel init tkt9sim ioman scf scvt term
OBJS	= $(KERNEL) $(COMMANDS)
OBJS_UIO = $(KERNEL) $(UIO) $(COMMANDS)

all:	turbos.img turbos_uio.img

KERNEL_SOURCES = kernel.asm fallbit.asm faproc.asm fchain.asm fcmpnam.asm fcrc.asm \
	ffork.asm flink.asm fnproc.asm fprsnam.asm fsrqmem.asm fssvc.asm \
	fvmodul.asm \
	iocall.asm funlink.asm fwait.asm fexit.asm fmem.asm fsend.asm fsleep.asm \
	ficpt.asm fsprior.asm fid.asm fsswi.asm \
	ffind64.asm fall64.asm fret64.asm

MODULE_SOURCES	= init.asm tkt9sim.asm

kernel: $(KERNEL_SOURCES)

lint: *.asm $(KERNEL_SOURCES) $(MODULE_SOURCES)
	$(foreach file,$^,mamou -ls -p $(file) > /tmp/lint.out; mv /tmp/lint.out $(file) ;)

turbos.img: $(OBJS)
	cat $(OBJS) > $@.rom
	ls -l $@.rom
	os9 padrom 3840 $@.rom
	cat $@.rom > $@.tmp
	os9 padrom -b -c=0 65280 $@.tmp
	dd if=/dev/zero of=lastpage.tmp bs=1 count=240
	printf "\x00\x00\x01\x00\x01\x03\x01\x0F\x01\x0C\x01\x06\x01\x09\xF0\x14" > vectors.tmp
	cat $@.tmp lastpage.tmp vectors.tmp > $@

turbos_uio.img: $(OBJS_UIO)
	cat $(OBJS_UIO) > $@.rom
	ls -l $@.rom
	os9 padrom 3840 $@.rom
	cat $@.rom > $@.tmp
	os9 padrom -b -c=0 65280 $@.tmp
	dd if=/dev/zero of=lastpage.tmp bs=1 count=240
	printf "\x00\x00\x01\x00\x01\x03\x01\x0F\x01\x0C\x01\x06\x01\x09\xF0\x14" > vectors.tmp
	cat $@.tmp lastpage.tmp vectors.tmp > $@

clean:
	-$(RM) $(OBJS) $(OBJS_UIO) *.rom *.img *.tmp *.list *.map lastpage

gh:
	open "http://www.github.com/boisy/turbos"


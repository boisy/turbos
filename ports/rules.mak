# Project-Wide Rules

# Environment variables are used to specify any directories other
# than the defaults below:
#
#   TURBOSDIR   - base directory of the project on your system
#
# If the defaults below are fine, then there is no need to set any
# environment variables.

# TurbOS version, major and minor release numbers are here
TURBOS_MAJOR       = 0
TURBOS_MINOR       = 1
TURBOS_MININUM     = 0

#################### DO NOT CHANGE ANYTHING BELOW THIS LINE ####################

OS9                 = os9

TURBOS_VERSION     = v$(TURBOS_MAJOR).$(TURBOS_MINOR)

DEFSDIR             = $(TURBOSDIR)/source/definitions
DSKDIR              = $(TURBOSDIR)/disk_images

# Assembler definitions
AS                  = lwasm --6309 --format=os9 --pragma=pcaspcr,nosymbolcase,condundefzero,undefextern,dollarnotlocal,noforwardrefmax --includedir=. --includedir=$(DEFSDIR)
ASROM               = lwasm --6309 --format=raw --pragma=pcaspcr,nosymbolcase,condundefzero,undefextern,dollarnotlocal,noforwardrefmax --includedir=. --includedir=$(DEFSDIR)
ASBIN               = lwasm --6309 --format=decb --pragma=pcaspcr,nosymbolcase,condundefzero,undefextern,dollarnotlocal,noforwardrefmax --includedir=. --includedir=$(DEFSDIR)
ASOUT               = -o
ifdef LISTDIR
ASOUT               = --list=$(LISTDIR)/$@.lst --symbols -o
endif
AFLAGS              = -DTURBOS_MAJOR=$(TURBOS_MAJOR) -DTURBOS_MINOR=$(TURBOS_MINOR) -DTURBOS_MININUM=$(TURBOS_MININUM)
# RMA/RLINK
ASM                 = lwasm --6309 --format=obj --pragma=pcaspcr,condundefzero,undefextern,dollarnotlocal,noforwardrefmax,export --includedir=. --includedir=$(DEFSDIR)
LINKER              = lwlink --format=os9
LWAR                = lwar -c

# Commands
MAKDIR              = $(OS9) makdir
RM                  = rm -f
MERGE               = cat
MOVE                = mv
ECHO                = echo
CD                  = cd
CP                  = cp
OS9COPY             = $(OS9) copy -o=0
CPL                 = $(OS9COPY) -l
TAR                 = tar
CHMOD               = chmod
IDENT               = $(OS9) ident
IDENT_SHORT         = $(IDENT) -s
OS9FORMAT           = $(OS9) format -e
OS9RENAME           = $(OS9) rename
OS9ATTR             = $(OS9) attr -q
OS9ATTR_TEXT        = $(OS9ATTR) -npe -npw -pr -ne -w -r
OS9ATTR_EXEC        = $(OS9ATTR) -pe -npw -pr -e -w -r
PADROM              = $(OS9) padrom
MOUNT               = sudo mount
UMOUNT              = sudo umount
LOREMOVE            = sudo losetup -d
LOSETUP             = sudo losetup
LINK                = ln
SOFTLINK            = $(LINK) -s
ARCHIVE             = zip -D -9 -j
MKDSKINDEX          = perl $(TURBOSDIR)/scripts/mkdskindex

# C Rules
%.o: %.c
	$(CC) $(CFLAGS) $< -r

%.a: %.o
	lwar -c $@ $?

%: %.o
	$(LINKER) $(LFLAGS) $^ -o$@

%: %.a
	$(LINKER) $(LFLAGS) $^ -o$@

%.o: %.as
	$(ASM) $(AFLAGS) $< $(ASOUT)$@

# File managers
%.mn: %.asm
	$(AS) $(AFLAGS) $< $(ASOUT)$@

# Device drivers
%.dr: %.asm
	$(AS) $(AFLAGS) $< $(ASOUT)$@

# Device descriptors
%.dd: %.asm
	$(AS) $(AFLAGS) $< $(ASOUT)$@

# Subroutine modules
%.sb: %.asm
	$(AS) $(AFLAGS) $< $(ASOUT)$@

# Terminal device descriptors
%.dt: %.asm
	$(AS) $(AFLAGS) $< $(ASOUT)$@

# I/O subroutines
%.io: %.asm
	$(AS) $(AFLAGS) $< $(ASOUT)$@

# All other modules
%: %.asm
	$(AS) $(AFLAGS) $< $(ASOUT)$@

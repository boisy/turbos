ifndef TURBOS9DIR
          TURBOS9DIR = $(PWD)
endif

export TURBOS9DIR
include $(TURBOS9DIR)/rules.mak
VPATH=../../kernel

turbos9: turbos9.asm
          lwasm --6309 --format=os9 --pragma=pcaspcr,nosymbolcase,condundefzero,undefextern,dollarnotlocal,noforwardrefmax --includedir=. --includedir=/Users/boisy/Projects/turbos9/defs $@< -o$@

lint: turbos9.asm
	mamou -ls -p $< > /tmp/lint.out

clean:
	rm turbos9

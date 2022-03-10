_TOP_DIR_ =
include $(_TOP_DIR_)config.mk

## Config ##
_Racket := $(firstword $(filter racket,$(IDRIS2_CG) $(MAKECMDGOALS)))
_Chez := $(if $(_Racket),,chez)

export IDRIS2_CG := $(or $(_Racket),$(IDRIS2_CG),chez)


## Setup ##
ifneq (, $(_Chez))
_SCHEMES = "$(SCHEME)" "$(CHEZ)" scheme chez chez-scheme chezscheme chezscheme9.5
SCHEME := $(shell $(foreach X,$(_SCHEMES),command -v $X >/dev/null && printf %s $X && exit;))
$(info SCHEME=$(SCHEME))
endif

SRC := idris2.$(if $(_Chez),ss,rkt)
BIN := $(if $(_Chez),idris2.so,compiled/idris2_rkt.zo)
LIB := libidris2_support$(_DYLIB_EXT)

# Shorthand
P0 := build/bootstrap/stage0
A0 := $(P0)/idris2_app
P1 := build/bootstrap
A1 := $(P1)/exec/idris2_app

# Prevent missing package errors.
export IDRIS2_PACKAGE_PATH = $(call _cygpath,libs)
$(info IDRIS2_PACKAGE_PATH=$(IDRIS2_PACKAGE_PATH))

# Remove bytecode file if truncated.
$(shell [ -s $(A0)/$(BIN) ] || $(RM) $(A0)/$(BIN))


## Aliases ##
all: stage1

stage0: $(A0)/$(BIN)
$(P0)/idris2: $(A0)/$(BIN)

libs: libs/network

stage1: $(P1)/exec/idris2

# Allow `make -f Bootstrap.mk <real-goal> racket`.
racket: $(or $(filter-out racket,$(MAKECMDGOALS)),all)

# Redirect bootstrap-* targets.
bootstrap-%: %

.PHONY: all $(A0)/$(BIN) libs libs/* racket
.PRECIOUS: $(A0)/$(BIN) $(A0)/$(SRC) # Hey, makefile, leave those files alone!
.SUFFIXES:


# rules #
$(A0)/$(LIB): support/c/$(LIB)
	mkdir -p $(@D)
	install $< $@

$(A0)/$(SRC): bootstrap/idris2_app/$(SRC)
	mkdir -p $(@D)
	sed 's/libidris2_support\.so/$(LIB)/' $< > $@

$(A0)/$(BIN): $(A0)/$(SRC) $(A0)/$(LIB)
ifneq (, $(_Chez))
	if { cksum $@ $< | cmp -s - $(P0)/sum; } 2>/dev/null; then touch -m $@; fi # else clean?
	cd $(<D) && echo '(maybe-compile-program "$(<F)")' | \
		"$(SCHEME)" --quiet --optimize-level 3
	cksum $@ $< > $(P0)/sum
else
	"$(or $(RACKET_RACO),raco)" make $<
endif
	printf %s\\n '#!/bin/sh' '' \
	  'export IDRIS2_PREFIX="$(call _cygpath,$(P0))"' \
	  'export LD_LIBRARY_PATH="$(abspath $(<D))$${LD_LIBRARY_PATH:+:}$$LD_LIBRARY_PATH"' \
	  '$(if $(_Darwin),export DYLD_LIBRARY_PATH="$(abspath $(<D))")' \
	  '$(if $(_Windows),PATH="$(abspath $(<D))$${PATH:+:}$$PATH")' \
	  '$(if $(_Chez),"$(SCHEME)" --program,"$(or $(RACKET),racket)" -u) "$(abspath $@)" "$$@"' \
	  > $(P0)/idris2
	chmod u+x $(P0)/idris2

## Libs ##
libs/prelude: stage0
libs/base: libs/prelude
libs/network: libs/base

libs/prelude libs/base libs/network:
	./$(P0)/idris2 $(IDRIS2FLAGS) --build bootstrap/$(@F).ipkg

$(P1)/exec/idris2: export IDRIS2_DATA = $(call _cygpath,support)
$(P1)/exec/idris2: export IDRIS2_LIBS = $(call _cygpath,support/c)
$(P1)/exec/idris2: export IDRIS2_PATH = $(call _cygpath,$(P0)/ttc)
$(P1)/exec/idris2: $(P0)/idris2 libs
	./$< $(IDRIS2FLAGS) --output-dir build/exec --build-dir $(P1) --build idris2.ipkg

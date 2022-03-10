_TOP_DIR_ =
include $(_TOP_DIR_)config.mk

## Setup ##
_YPREFIX := $(call _cygpath,$(PREFIX))

# Git prints <tag>-<num-commits-since>-g<hash>[-dirty], or <hash>[-dirty] (no match).
_GIT_CMD = git describe --always --dirty --long --match=v$(VERSION) --tags
# Sed removes <tag>-0-g<hash>[-], or <tag>-<n>-g, or nothing.
_SED_CMD = sed 's/v[^-]*-0*-*[^-]*-*g*//'
VERSION_TAG := $(or $(shell $(_GIT_CMD) | $(_SED_CMD)),$(VERSION_TAG))

$(info YPREFIX=$(_YPREFIX))
$(info VERSION=$(VERSION))
$(info VERSION_TAG=$(VERSION_TAG))

_VERSION_TUPLE = ($(subst .,$(strip ,),$(VERSION)))

_LIBS := $(wildcard libs/*)
_LIBS_PATH := $(call _MK_PATH,$(PWD)/,$(_LIBS),/build/ttc)

define _USE_BUILD
$1: export IDRIS2_PREFIX := $(PWD)/build/prefix
$1: export IDRIS2_PACKAGE_PATH := $(PWD)/libs
$1: export IDRIS2_PATH := $(_LIBS_PATH)
$1: export IDRIS2_DATA := $(PWD)/support
$1: export IDRIS2_LIBS := $(PWD)/support/c
endef

_IPKG_CMDS = --build --clean --install --install-with-src --mkdoc --typecheck
_FLAGS = $(filter-out $(_IPKG_CMDS),$(IDRIS2FLAGS)) \
         $(lastword $(filter $(_IPKG_CMDS),--build $(IDRIS2FLAGS)))


## Aliases ##
all: support idris2.ipkg libs

support: support/c support/chez support/refc

src/IdrisPaths.idr: IdrisPaths
idris2: idris2.ipkg
idris2-exec: idris2.ipkg
idris2-api: idris2api.ipkg

libs: $(_LIBS)

# Forward bootstrap targets.
bootstrap-%: ; $(MAKE) -f Bootstrap.mk $*

# Forward install targets.
install: install-all
install-%: ; $(MAKE) -f Install.mk $*

.PHONY: all bootstrap idris2-api idris2-exec IdrisPaths \
        install libs $(_LIBS) support support/* test
.SUFFIXES: # Disable built-in suffix recipes.
.NOTPARALLEL: # Most targets in this file cannot be run in parallel.


## Support ##
support/*: ; make -C $@


## Idris / API ##
IdrisPaths:
	set -e; sum=$$(cksum src/$@.idr 2>/dev/null || :); \
	printf %s\\n \
	  'module $@' '' '-- @''generated' \
	  '' 'public export' 'idrisVersion : ((Nat,Nat,Nat), String)' \
	  'idrisVersion = ($(_VERSION_TUPLE), "$(VERSION_TAG)")' \
	  '' 'public export' 'yprefix : String' \
	  "yprefix = \"$(_YPREFIX)\"" \
	  > src/$@.idr; \
	  if [ "$$sum" = "$$(cksum src/$@.idr)" ]; then touch -mr src src/$@.idr; fi

idris%.ipkg: IdrisPaths
	"$(IDRIS2_BOOT)" $(_FLAGS) $@

install-api: IdrisPaths


## Libs ##
# These prereqs are used for IDRIS2_PATH. Packages with missing dependencies will fail.
# TODO: Get these from ipkg depends field?
libs/base: libs/prelude
libs/contrib: libs/prelude libs/base
libs/linear: libs/prelude libs/base
libs/network: libs/prelude libs/base libs/contrib
libs/test: libs/prelude libs/base libs/contrib
libs/papers: libs/prelude libs/base libs/contrib libs/linear

$(eval $(call _USE_BUILD,$(_LIBS)))
$(_LIBS): export IDRIS2_PATH = $(call _MK_PATH,$(PWD)/,$^,/build/ttc)
$(_LIBS): export IDRIS2_INC_CGS = $(or $(IDRIS2_CG),chez)
$(_LIBS):
	./build/exec/idris2 $(_FLAGS) $@/$(@F).ipkg

libdocs: IDRIS2FLAGS += --mkdoc
libdocs: libs


## Bootstrap ##
_bootstrap: support/c IdrisPaths
	$(MAKE) -f Bootstrap.mk

bootstrap: _bootstrap libs

bootstrap-racket: export IDRIS2_CG = racket
bootstrap-racket: bootstrap


## Tests ##
$(eval $(call _USE_BUILD,test))
test: IDRIS2 := $(abspath build/exec/idris2)
test: _runtests

test-installed: IDRIS2 := $(or $(IDRIS2),idris2)
test-installed: _runtests

retest: only-file = --only-file failures
retest: test

ifneq (, $(_Windows))
_runtests: export OS = windows
endif
_runtests: threads ?= $(shell { nproc || sysctl -n hw.ncpu; } 2>/dev/null)
_runtests:
	./build/exec/idris2 --build tests/tests.ipkg
	cd tests && ./build/exec/runtests "$(IDRIS2)" --threads $(threads) \
	  --timing --failure-file failures $(only-file) --only $(only)


## Clean ##
clean-bootstrap:
	$(RM) -r build/bootstrap

clean-idris2:
	$(RM) -r build/exec/idris2 build/exec/idris2_app build/ttc

clean-libs:
	find libs -depth -type d -name 'build' -exec $(RM) -r '{}' +

clean-support:
	find support -type f \( -name '*.[ado]' -o -name '*.dll' -o -name '*.dylib' \
	  -o -name '*.so' -o -name support-sep.ss \) -exec $(RM) '{}' +

clean-test:
	$(RM) tests/failures
	find tests -depth -path '*/build*' -exec $(RM) -r {} \;
	find tests -type f \( -name '*output*' -o -name '*.d' \) -exec $(RM) {} \;
	find tests -name gen_expected.sh | sed 's/[^/]*$$/expected/' | xargs $(RM)

distclean: clean-support clean-test
	$(RM) -r build src/IdrisPaths.idr

mostlyclean:
	$(RM) -r build/ttc libs/*/build/ttc

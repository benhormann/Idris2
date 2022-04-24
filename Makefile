all: libs
bootstrap: all
clean: clean-stage2
install: install-idris2 install-support install-libs

.PHONY: all bootstrap clean install libs
.SUFFIXES:

include config.mk


#############
### BUILD ###
#############

## STAGE 2 ##
libs: build/stage2/idris2
	./$^ --build-dir ../../$(^D) --build libs/prelude/prelude.ipkg
	./$^ --build-dir ../../$(^D) --build libs/base/base.ipkg
	./$^ --build-dir ../../$(^D) --build libs/contrib/contrib.ipkg
	./$^ --build-dir ../../$(^D) --build libs/network/network.ipkg
	./$^ --build-dir ../../$(^D) --build libs/test/test.ipkg
	./$^ --build-dir ../../$(^D) --build libs/linear/linear.ipkg
	./$^ --build-dir ../../$(^D) --build libs/papers/papers.ipkg

build/stage2/idris2: build/stage1/idris2
	./$^ --build-dir $(@D) --build idris2.ipkg
	./Launcher.sh "stage2" > $@
	chmod u+x $@

## STAGE 1 ##
_BOOTSTRAPING := $(filter bootstrap,$(MAKECMDGOALS))

build/stage1/idris2: IdrisPaths $(if $(_BOOTSTRAPING),_bootstrap-libs)
ifeq (bootstrap, $(_BOOTSTRAPING))
	./build/bootstrap/idris2 --build-dir $(@D)/bootstrap --output-dir $(@D)/exec --build idris2.ipkg
else
	$(IDRIS2_BOOT) --build-dir $(@D)/stage0 --output-dir $(@D)/exec --build idris2.ipkg
endif
	./Launcher.sh "stage1" > $@
	chmod u+x $@
	./$@ --build-dir ../../$(@D) --build libs/prelude/prelude.ipkg
	./$@ --build-dir ../../$(@D) --build libs/base/base.ipkg
	./$@ --build-dir $(@D) --source-dir libs/network --verbose --check libs/network/Network/Socket.idr

## BOOTSTRAP ##
_RACKET = $(filter racket,$(IDRIS2_CG))
_BOOT_SRC = idris2_app/$(if $(_RACKET),idris2.rkt,idris2.ss)
_BOOT_BIN = idris2_app/$(if $(_RACKET),compiled/idris2_rkt.zo,idris2.so)

_bootstrap-libs: build/bootstrap/idris2
	./$^ --build-dir ../../$(^D) --build libs/prelude/prelude.ipkg
	./$^ --build-dir ../../$(^D) --build libs/base/base.ipkg
	./$^ --build-dir $(^D) --source-dir libs/network --verbose --check libs/network/Network/Socket.idr

build/bootstrap/idris2: build/bootstrap/exec/$(_BOOT_BIN)
ifeq (,$(_RACKET))
	./Launcher.sh "bootstrap" "$(SCHEME)" --program $^ > $@
else
	./Launcher.sh "bootstrap" "$(RACKET)" -u $^ > $@
endif
	chmod u+x $@

# Cleanup truncated build artifacts, E.g. when Chez was unsuccessful.
$(shell F=build/bootstrap/exec/$(_BOOT_BIN); [ -s $$F ] || $(RM) $$F)
$(shell for X in stage2 stage1 bootstrap; do \
  F=build/$$X/idris2; grep -q '"\$$@"' $$F 2>/dev/null || $(RM) $$F; \
done)

build/bootstrap/exec/$(_BOOT_BIN): build/bootstrap/exec/$(_BOOT_SRC)
ifeq (,$(_RACKET))
	cd $(@D) && echo '(maybe-compile-program "$(^F)")' | "$(SCHEME)" -q --optimize-level 3
else
	cd $(@D) && "$(RACKET_RACO)" make $(^F)
endif

build/bootstrap/exec/$(_BOOT_SRC): bootstrap/$(_BOOT_SRC)
	[ -f libidris2_support$(_LIB_EXT) ] || $(MAKE) -C support/c
	mkdir -p $(@D)
	install support/c/libidris2_support$(_LIB_EXT) $(@D)
	sed 's/\(libidris2_support\)\.so/\1$(_LIB_EXT)/' $^ > $@

## PREFIX and VERSION ##
_VERSION_TUPLE = ($(subst .,$(strip ,),$(VERSION)))
_YPREFIX = $(if $(_WIN),$(shell cygpath -m "$PREFIX"),$(PREFIX))

# Git prints <tag>-<num-commits-since>-g<hash>[-dirty], or <hash>[-dirty] (no match).
_GIT_CMD = git describe --always --dirty --long --match=v$(VERSION) --tags
# Sed removes <tag>-0-g<hash>[-], or <tag>-<n>-g, or nothing.
_SED_CMD = sed 's/v[^-]*-0*-*[^-]*-*g*//'
VERSION_TAG := $(or $(shell $(_GIT_CMD) | $(_SED_CMD)),$(VERSION_TAG))

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


###############
### INSTALL ###
###############

install-api install-libs: export IDRIS2_PREFIX := $(call _CYGMIX,$(DESTDIR))

install-api:
	./build/stage2/idris2 --install idris2api.ipkg

install-idris2:
	mkdir -p "$(DESTDIR)/bin"
	cd build/stage2/exec && cp -r idris2 idris2_app "$(DESTDIR)/bin"

install-libs: $(if $(wildcard build/stage2/idris2),,build/stage2/idris2)
	echo IDRIS2_PREFIX=$$IDRIS2_PREFIX
	./build/stage2/idris2 --build-dir ../../build/stage2 --install libs/prelude/prelude.ipkg
	./build/stage2/idris2 --build-dir ../../build/stage2 --install libs/base/base.ipkg
	./build/stage2/idris2 --build-dir ../../build/stage2 --install libs/contrib/contrib.ipkg
	./build/stage2/idris2 --build-dir ../../build/stage2 --install libs/network/network.ipkg
	./build/stage2/idris2 --build-dir ../../build/stage2 --install libs/test/test.ipkg
	./build/stage2/idris2 --build-dir ../../build/stage2 --install libs/linear/linear.ipkg
	./build/stage2/idris2 --build-dir ../../build/stage2 --install libs/papers/papers.ipkg

install-support:
	$(MAKE) -C support/c install
	$(MAKE) -C support/chez install
	$(MAKE) -C support/refc install
	cd support && cp -r gambit js racket "$(DESTDIR)/idris2-$(VERSION)/support"


#############
### TESTS ###
#############

test:
	$(MAKE) -C tests testbin test IDRIS2="$(_CWD)/build/stage2/idris2"

retest:
	$(MAKE) -C tests testbin retest IDRIS2="$(_CWD)/build/stage2/idris2"


#############
### CLEAN ###
#############

clean-test:
	$(MAKE) -C tests clean

clean-support:
	$(MAKE) -C support/c clean
	$(MAKE) -C support/chez clean
	$(MAKE) -C support/refc clean

clean-stage2:
	$(RM) -r build/stage2

clean-stage1:
	$(RM) -r build/stage1

clean-bootstrap:
	$(RM) -r build/bootstrap

distclean: clean-test clean-support clean-stage2 clean-stage1 clean-bootstrap
	$(RM) -r build

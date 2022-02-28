include config.mk

## Setup ##
#export PREFIX := $(shell sed -n 's/"$$//;s/yprefix *=.*"//p' src/IdrisPaths.idr)
#export VERSION := $(shell sed -n 's/,/./g;s/.*(\([0-9.]*\)).*/\1/p' src/IdrisPaths.idr)
#export PREFIX := $(shell unset IDRIS2_PREFIX; ./build/exec/idris2 --prefix)
#export VERSION := $(shell ./build/exec/idris2 --version | sed 's/.* //;s/-.*//')
$(shell unset IDRIS2_PREFIX IDRIS2_DATA; ./build/exec/idris2 --paths > build/.paths)
export PREFIX := $(shell sed -En 's|.*Prefix *:: "(.*)"|\1|p' build/.paths)
export VERSION := $(shell sed -En 's|.*\[".*-([0-9.]*)/support"\]|\1|p' build/.paths)

export DESTDIR := $(or $(DESTDIR),$(PREFIX))
export IDRIS2_PREFIX := $(DESTDIR)

$(info DESTDIR=$(DESTDIR))
$(info PREFIX=$(PREFIX))
$(info VERSION=$(VERSION))

# Install order matters.
_LIBS := $(addprefix libs/,prelude base contrib linear test network papers)

_SUPPORT := $(patsubst %/Makefile,%,$(wildcard support/*/Makefile))
_COPY_FILES := $(filter-out $(_SUPPORT),$(wildcard support/*))


## Aliases ##
all: support idris2 libs
api: idris2api.ipkg
idris2.ipkg: idris2
libs: $(_LIBS)
support: $(_SUPPORT) $(_COPY_FILES)

# Redirect 'install-' prefix, e.g. install-api -> api.
install-%: ; $(MAKE) -f Install.mk $*

.PHONY: all api idris2 *.ipkg libs $(_LIBS) support $(_SUPPORT) $(_COPY_FILES)
.SUFFIXES: # Disable built-in suffix recipes.
.NOTPARALLEL: # Some targets in this file cannot be run in parallel.


## Idris / API ##
idris2:
	mkdir -p "$(DESTDIR)/bin"
	cp -r build/exec/idris2 build/exec/idris2_app "$(DESTDIR)/bin"

idris2api.ipkg:
	unset IDRIS2_PREFIX; "$(IDRIS2_BOOT)" $(IDRIS2FLAGS) --install $@


## Support ##
$(_SUPPORT):
	$(MAKE) -C $@ install

$(_COPY_FILES):
	mkdir -p "$(DESTDIR)/idris2-$(VERSION)/$@"
	find $@ -type f -exec install -m 644 '{}' "$(DESTDIR)/idris2-$(VERSION)/$@" \;


## Libs ##
$(_LIBS):
	./build/exec/idris2 $(IDRIS2FLAGS) --install $@/$(@F).ipkg

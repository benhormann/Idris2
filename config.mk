PREFIX ?= $(HOME)/.idris2
DESTDIR ?= $(PREFIX)

IDRIS2_BOOT ?= idris2

VERSION ?= $(shell sed -n 's/^version[^0-9]*//p' $(_TOP_DIR)idris2api.ipkg)
VERSION_TAG ?= tarball

SCHEME ?= $(or $(CHEZ),$(shell \
  echo "Finding SCHEME" >&2; \
  for X in chez chezscheme chez-scheme chezscheme9.5; do \
    if command -v $$X >/dev/null; then echo $$X && break; fi; \
  done),scheme)
RACKET ?= racket
RACKET_RACO ?= raco

OLD_WIN ?= $(if $(findstring _NT-6.1,$(_OS)),1)

_OS := $(shell uname)
_WIN := $(findstring _NT,$(_OS))
_MAC := $(filter Darwin,$(_OS))
_LIB_EXT := $(if $(_WIN),.dll,$(if $(_MAC),.dylib,.so))
_CYGMIX = $(if $(_WIN),$(shell cygpath --mixed "$1"),$1)
_CWD := $(call _CYGMIX,$(PWD))

-include $(_TOP_DIR)custom.mk

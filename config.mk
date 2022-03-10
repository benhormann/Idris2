##### Options which a user might set before building go here #####

# Where to install idris2 binaries and libraries (must be an absolute path).
PREFIX ?= $(HOME)/.idris2

# Command to run for installed version.
IDRIS2_BOOT ?= idris2

# Uncomment for Windows targets pre Windows 8. Should auto-detect Windows 7.
#OLD_WIN := 1

##################################################################


VERSION ?= $(shell sed -n 's/^version[^0-9]*//p' $(_TOP_DIR)idris2api.ipkg)
VERSION_TAG ?= tarball

RANLIB ?= ranlib

CFLAGS := -Wall $(CFLAGS)

MAKE_HOST ?= $(shell $(CC) -dumpmachine)
_MACHINE := $(subst -, ,$(MAKE_HOST))
_Darwin := $(filter darwin%,$(_MACHINE))
_Windows := $(filter cygwin% mingw% msys% windows%,$(_MACHINE))

_DYLIB_EXT := $(or $(if $(_Darwin),.dylib),$(if $(_Windows),.dll),.so)

ifeq (, $(_Windows))
	CFLAGS += -fPIC
else ifneq (, $(findstring NT-6.1,$(shell uname)))
	OLD_WIN ?= 1
endif

_cygpath = $(if $(_Windows),$(shell cygpath -ma -- "$1"),$(abspath $1))
_cygPATH = $(if $(_Windows),$(shell cygpath -mp -- "$1"),$1)
# Usage: $(call _MK_PATH,<prefix>,<paths...>[,<suffix>])
_MK_PATH = $(call _cygPATH,$(if $2,$1$(subst $() ,$3:$1,$2)$3))



# Add a custom.mk file to override any of the configurations
define _example-custom.mk_
PREFIX := $(HOME)/.idris2-dev
DESTDIR := /tmp/idris2-staging
IDRIS2_BOOT := $(HOME)/.idris2-stable/bin/idris2
export IDRIS2_CG := racket
export CHEZ := my-chez # Note: common names in PATH are auto-detected
endef

-include $(_TOP_DIR)custom.mk

_TOP_DIR_ = ../../../
include $(_TOP_DIR_)config.mk

IDRIS := idris2
INSTALLDIR = `${IDRIS} --libdir`/readline/lib

TARGET = libidrisreadline

LDFLAGS += -lreadline

SRCS = $(wildcard *.c)
OBJS = $(SRCS:.c=.o)
DEPS = $(OBJS:.o=.d)


all: $(TARGET)$(_DYLIB_EXT)

$(TARGET)$(_DYLIB_EXT): $(OBJS)
	$(CC) -shared $(LDFLAGS) -o $@ $^


-include $(DEPS)

%.d: %.c
	@$(CPP) $(CFLAGS) $< -MM -MT $(@:.d=.o) >$@


.PHONY: clean

clean :
	rm -f $(OBJS) $(TARGET)$(_DYLIB_EXT)

cleandep: clean
	rm -f $(DEPS)


.PHONY: install

install:
	@if ! [ -d $(INSTALLDIR) ]; then mkdir -p $(INSTALLDIR); fi
	install $(TARGET)$(_DYLIB_EXT) $(wildcard *.h) $(INSTALLDIR)

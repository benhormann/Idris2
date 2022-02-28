include ../../../config.mk

TARGET = libcb

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
	$(RM) $(OBJS) $(TARGET)$(_DYLIB_EXT)

cleandep: clean
	$(RM) $(DEPS)

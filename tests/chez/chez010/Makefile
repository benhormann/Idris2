_TOP_DIR = ../../../
include ../../../config.mk

TARGET = libcb

SRCS = $(wildcard *.c)
OBJS = $(SRCS:.c=.o)
DEPS = $(OBJS:.o=.d)


all: $(TARGET)$(_LIB_EXT)

$(TARGET)$(_LIB_EXT): $(OBJS)
	$(CC) -shared $(LDFLAGS) -o $@ $^


-include $(DEPS)

%.d: %.c
	@$(CPP) $(CFLAGS) $< -MM -MT $(@:.d=.o) >$@


.PHONY: clean

clean :
	$(RM) $(OBJS) $(TARGET)$(_LIB_EXT)

cleandep: clean
	$(RM) $(DEPS)

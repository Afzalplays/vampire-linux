PKG_CONFIG ?= pkg-config
CFLAGS ?= -O2
LDFLAGS ?=
CFLAGS += $(shell $(PKG_CONFIG) --cflags sdl2 SDL2_ttf)
LDLIBS += $(shell $(PKG_CONFIG) --libs sdl2 SDL2_ttf)

all: vampire-mobile-shell

vampire-mobile-shell: vampire-mobile-shell.c
	$(CC) $(CFLAGS) -Wall -Wextra -Wno-unused-parameter -o $@ $< $(LDFLAGS) $(LDLIBS)

clean:
	rm -f vampire-mobile-shell

.PHONY: all clean

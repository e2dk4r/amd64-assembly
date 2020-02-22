#===============================================================================
# MAKE DEFAULTS
TZ        := UTC
LC_ALL    := C.UTF-8
SHELL     := bash
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
.RECIPEPREFIX = >

#===============================================================================
# PROJECT VARIABLES
PROJECT := eatterm
BINARY  := $(PROJECT)

SRC_DIR := src
OBJ_DIR := obj

SOURCES := $(sort $(wildcard $(SRC_DIR)/*.asm))
OBJECTS := $(patsubst $(SRC_DIR)/%.asm,$(OBJ_DIR)/%.o,$(SOURCES))

#===============================================================================
# BUILD VARIABLES
ASM       = nasm
ASMFLAGS  = -f elf64 
ASMFLAGS += -gdwarf
ASMFLAGS += -i$(SRC_DIR)

LD        = ld
LDFLAGS   = 

#===============================================================================
# INSTALL VARIABLES
DESTDIR ?=
PREFIX  ?= /usr/local
BINDIR  := $(PREFIX)/bin
INSTALL := install -m 755

MKDIR = mkdir -p
RM    = rm -f
STRIP = strip

#===============================================================================
# RULES
all: dirs $(BINARY)

dirs:
> $(MKDIR) $(OBJ_DIR)

$(BINARY): $(OBJECTS)
> $(LD) -o $@ $^

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.asm
> $(ASM) $(ASMFLAGS) -o $@ $<

strip: $(BINARY)
> $(STRIP) $(BINARY)

clean:
> $(RM) $(BINARY) $(OBJECTS)

install:
> $(INSTALL) $(BINARY) $(DESTDIR)$(BINDIR)

uninstall:
> $(RM) $(DESTDIR)$(BINDIR)/$(BINARY)

.PHONY: all install uninstall strip clean

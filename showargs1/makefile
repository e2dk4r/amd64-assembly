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
PROJECT := showargs1
BINARY  := $(PROJECT)

SRC_DIR := src
OBJ_DIR := obj
OUT_DIR := out

SOURCES := $(sort $(wildcard $(SRC_DIR)/*.asm))
OBJECTS := $(patsubst $(SRC_DIR)/%.asm,$(OBJ_DIR)/%.o,$(SOURCES))

#===============================================================================
# BUILD VARIABLES
ASM       = nasm
ASMFLAGS  = -f elf64 
ASMFLAGS += -gdwarf -O0
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
all: dirs $(OUT_DIR)/$(BINARY)

dirs:
> $(MKDIR) $(OBJ_DIR) $(OUT_DIR)

$(OUT_DIR)/$(BINARY): $(OBJECTS)
> $(LD) -o $@ $^

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.asm
> $(ASM) $(ASMFLAGS) -o $@ $<

strip: $(OUT_DIR)/$(BINARY)
> $(STRIP) $^

clean:
> $(RM) $(OUT_DIR)/$(BINARY) $(OBJECTS)

install:
> $(INSTALL) $(OUT_DIR)/$(BINARY) $(DESTDIR)$(BINDIR)

uninstall:
> $(RM) $(DESTDIR)$(BINDIR)/$(BINARY)

.PHONY: all install uninstall strip clean

#===============================================================================
# MAKE DEFAULTS
TZ 		  := UTC
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
PROJECT := demo
BINARY  := $(PROJECT)

SRC_DIR := src
OBJ_DIR := obj

SOURCES := $(sort $(wildcard $(SRC_DIR)/*.asm))
OBJECTS := $(patsubst $(SRC_DIR)/%.asm,$(OBJ_DIR)/%.o,$(SOURCES))

#===============================================================================
# LIBRARIES
LIB_TEXTLIB = textlib
#LIBS += -L/usr/local/lib
LIBS += -Llib/textlib
LIBS += -l$(LIB_TEXTLIB)

#===============================================================================
# BUILD VARIABLES
ASM		  = nasm
ASMFLAGS  = -f elf64
ASMFLAGS += -gdwarf
ASMFLAGS += -i$(SRC_DIR)

LD		  = ld
LDFLAGS	  = 

#===============================================================================
# INSTALL VARIABLES
DESTDIR ?=
PREFIX  ?= /usr/local
BINDIR  := $(PREFIX)/bin
INSTALL := install -m 755

MKDIR := mkdir -p
RM 	  := rm -f
STRIP := strip

#===============================================================================
# RULES
all: dirs lib $(BINARY)

lib:
> $(MAKE) -C lib/$(LIB_TEXTLIB)

dirs:
> $(MKDIR) $(OBJ_DIR)

$(BINARY): $(OBJECTS)
> $(LD) $(LDFLAGS) -o $@ $^ $(LIBS)

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

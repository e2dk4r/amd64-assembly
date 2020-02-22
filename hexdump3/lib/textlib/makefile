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
LIB_NAME := textlib
LIB_OUT  := lib$(LIB_NAME).a

SRC_DIR := src
OBJ_DIR := obj

SOURCES := $(sort $(wildcard $(SRC_DIR)/*.asm))
OBJECTS := $(patsubst $(SRC_DIR)/%.asm,$(OBJ_DIR)/%.o,$(SOURCES))

#===============================================================================
# BUILD VARIABLES
ASM		 := nasm
ASMFLAGS  = -f elf64
ASMFLAGS += -gdwarf
ASMFLAGS += -i$(SRC_DIR)

AR		  = ar
ARFLAGS	  = rcs

#===============================================================================

#===============================================================================
# INSTALL VARIABLES
DESTDIR ?=
PREFIX  ?= /usr/local
LIBDIR  ?= $(PREFIX)/lib
INSTALL := install -m 755

MKDIR 	= mkdir -p
RM	  	= rm -f

#===============================================================================
# RULES
all: dirs $(LIB_OUT)

dirs:
> $(MKDIR) $(OBJ_DIR)

$(LIB_OUT): $(OBJECTS)
> $(AR) $(ARFLAGS) $@ $^

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.asm
> $(ASM) $(ASMFLAGS) -o $@ $<

clean:
> $(RM) $(LIB_OUT) $(OBJECTS)

install:
> $(INSTALL) $(LIB_OUT) $(DESTDIR)$(LIBDIR)

uninstall:
> $(RM) $(DESTDIR)$(LIBDIR)/$(LIB_OUT)

.PHONY: all clean

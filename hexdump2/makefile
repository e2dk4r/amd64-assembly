TZ 		  := UTC
LC_ALL    := C.UTF-8
SHELL     := bash
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
.RECIPEPREFIX = >

PROJECT := demo
BINARY  := $(PROJECT)

SRC_DIR := src
OBJ_DIR := obj

SOURCES := $(sort $(wildcard $(SRC_DIR)/*.asm))
OBJECTS := $(patsubst $(SRC_DIR)/%.asm,$(OBJ_DIR)/%.o,$(SOURCES))

ASMFLAGS  = -f elf64
ASMFLAGS += -gdwarf
ASMFLAGS += -i$(SRC_DIR)

all: dirs $(BINARY)

dirs:
> mkdir -p $(OBJ_DIR)

$(BINARY): $(OBJECTS)
> ld -o $@ $^

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.asm
> nasm $(ASMFLAGS) -o $@ $<

strip: $(BINARY)
> strip $(BINARY)

clean:
> rm -f $(BINARY) $(OBJECTS)

.PHONY: all clean

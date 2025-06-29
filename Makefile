###############################################################################
# "THE BEER-WARE LICENSE" (Revision 42):
# <msmith@FreeBSD.ORG> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return
###############################################################################
#
# Makefile for building the blackbox data decoder.
#
# Invoke this with 'make help' to see the list of supported targets.
# 

###############################################################################
# Things that the user might override on the commandline
#

# Compile-time options
OPTIONS		?=
BLACKBOX_VERSION     ?= 

# Debugger optons, must be empty or GDB
DEBUG = GDB

###############################################################################
# Things that need to be maintained as the source changes
#

# Working directories
ROOT		 = $(dir $(lastword $(MAKEFILE_LIST)))
SRC_DIR		 = $(ROOT)/src
OBJECT_DIR	 = $(ROOT)/obj
BIN_DIR		 = $(ROOT)/obj

# Source files common to all targets
COMMON_SRC	 = parser.c tools.c platform.c stream.c decoders.c units.c blackbox_fielddefs.c
DECODER_SRC	 = $(COMMON_SRC) blackbox_decode.c gpxwriter.c imu.c battery.c stats.c

# In some cases, %.s regarded as intermediate file, which is actually not.
# This will prevent accidental deletion of startup code.
.PRECIOUS: %.s

# Search path for baseflight sources
VPATH		:= $(SRC_DIR)

###############################################################################
# Things that might need changing to use different tools
#

#
# Tool options.
#
INCLUDE_DIRS	 = $(SRC_DIR)

ifeq ($(DEBUG),GDB)
OPTIMIZE	 = -O0
LTO_FLAGS	 = $(OPTIMIZE)
else
OPTIMIZE	 = -O3
LTO_FLAGS	 = -flto $(OPTIMIZE)
endif

DEBUG_FLAGS	 = -g3 -ggdb

CFLAGS		= $(ARCH_FLAGS) \
		$(LTO_FLAGS) \
		$(addprefix -D,$(OPTIONS)) \
		$(addprefix -I,$(INCLUDE_DIRS)) \
		$(if $(strip $(BLACKBOX_VERSION)), -DBLACKBOX_VERSION=$(BLACKBOX_VERSION)) \
		$(DEBUG_FLAGS) \
		-std=gnu99 \
		-pthread \
		-Wall -pedantic -Wextra -Wshadow

LDFLAGS += -lm

# Required with GCC. Clang warns when using flag while linking, so you can comment this line out if you're using clang:
LDFLAGS += -pthread


###############################################################################
# No user-serviceable parts below
###############################################################################

#
# Things we will build
#

DECODER_ELF	 = $(BIN_DIR)/blackbox_decode

DECODER_OBJS	 = $(addsuffix .o,$(addprefix $(OBJECT_DIR)/,$(basename $(DECODER_SRC))))

TARGET_MAP   = $(OBJECT_DIR)/blackbox_decode.map

all : $(DECODER_ELF)

$(DECODER_ELF):  $(DECODER_OBJS)
	@$(CC) -o $@ $^ $(LDFLAGS)

# Compile
$(OBJECT_DIR)/%.o: %.c
	@mkdir -p $(dir $@)
	@echo %% $(notdir $<)
	@$(CC) -c -o $@ $(CFLAGS) $<

clean:
	rm -f $(DECODER_ELF) $(DECODER_OBJS) $(TARGET_MAP)

help:
	@echo ""
	@echo "Makefile for the baseflight blackbox data decoder"
	@echo ""
	@echo "Usage:"
	@echo "        make [OPTIONS=\"<options>\"]"
	@echo ""

# use by 'github copilot'

# Nintendo 3DS Homebrew Makefile (cleaned and organized)

# Set up toolchain paths
export PATH := $(DEVKITPRO)/portlibs/3ds/bin:$(PATH)

include base_tools

# Source and object files
SOURCES   := Sources Lib/ctrulib

INCLUDES	:=	-I Includes -I Includes\ctrulib

CPPFILES	:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.cpp)))
SFILES		:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.s)))

# Architecture and compile options
ARCH      := -march=armv6k -mlittle-endian -mtune=mpcore -mfloat-abi=hard

CXXFLAGS  := -Os -mword-relocations \
			-fomit-frame-pointer -ffunction-sections -fno-strict-aliasing \
			$(ARCH) \
			$(INCLUDES)
			-DARM11 -D__3DS__ \
			-fno-rtti -fno-exceptions -std=gnu++11

.PHONY: all
all: 3gx0002ctrpf080.3gx

$(OFILES).o: $(SFILES).s
	$(SILENTMSG) $(notdir $<)
	$(ADD_COMPILE_COMMAND) add $(CC) "-x assembler-with-cpp $(_EXTRADEFS) $(ARCH) -c $< -o $@" $<
	$(SILENTCMD)$(CC) -MMD -MP -MF -x assembler-with-cpp $(_EXTRADEFS) $(ARCH) -c $< -o $@

$(OFILES).o: $(CPPFILES).cpp
	$(SILENTMSG) $(notdir $<)
	$(ADD_COMPILE_COMMAND) add $(CXX) "$(_EXTRADEFS) $(CXXFLAGS) -c $< -o $@" $<
	$(SILENTCMD)$(CXX) -MMD -MP -MF $(_EXTRADEFS) $(CXXFLAGS) -c $< -o $@

3gx0002ctrpf080.elf: $(OFILES).o
	$(SILENTMSG) linking $(notdir $@)
	$(ADD_COMPILE_COMMAND) end
	$(SILENTCMD)$(CXX) -T 3ds.ld $(ARCH) -Os -Wl,-Map,$(notdir $*.map),--gc-sections $(OFILES) -L Lib -lCTRPluginFramework -o $@
	$(SILENTCMD)$(NM) -CSn $@ > $(notdir $*.lst)
	
3gx0002ctrpf080.3gx: %.elf

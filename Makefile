#---------------------------------------------------------------------------------
.SUFFIXES:
#---------------------------------------------------------------------------------

ifeq ($(strip $(DEVKITARM)),)
$(error "Please set DEVKITARM in your environment. export DEVKITARM=<path to>devkitARM")
endif

TOPDIR ?= $(CURDIR)
include $(DEVKITARM)/base_rules

TARGET		:= 	$(notdir $(CURDIR))
BUILD		:= 	Build
INCLUDES	:= 	Includes \
				Includes\ctrulib \
				Includes\ctrulib\allocator \
				Includes\ctrulib\gpu \
				Includes\ctrulib\services \
				Includes\ctrulib\util
SOURCES 	:= 	Sources \
				Sources\CTRPluginFramework \
				Sources\CTRPluginFramework\Graphics \
				Sources\CTRPluginFramework\Menu \
				Sources\CTRPluginFramework\System \
				Sources\CTRPluginFramework\Utils \
				Sources\CTRPluginFrameworkImpl \
				Sources\CTRPluginFrameworkImpl\ActionReplay \
				Sources\CTRPluginFrameworkImpl\Disassembler \
				Sources\CTRPluginFrameworkImpl\Graphics \
				Sources\CTRPluginFrameworkImpl\Graphics\Icons \
				Sources\CTRPluginFrameworkImpl\Menu \
				Sources\CTRPluginFrameworkImpl\Search \
				Sources\CTRPluginFrameworkImpl\System \
				Sources\ctrulib \
				Sources\ctrulib\allocator \
				Sources\ctrulib\gpu \
				Sources\ctrulib\services \
				Sources\ctrulib\system \
				Sources\ctrulib\util\utf \
				Sources\ctrulib\util\rbtree
				
#---------------------------------------------------------------------------------
# options for code generation
#---------------------------------------------------------------------------------
ARCH	:=	-march=armv6k -mlittle-endian -mtune=mpcore -mfloat-abi=hard

CFLAGS	:=	-g -Os -mword-relocations \
 			-fomit-frame-pointer -ffunction-sections -fno-strict-aliasing \
			$(ARCH)

CFLAGS		+=	$(INCLUDE) -DARM11 -D_3DS
#-Wall -Wextra -Wdouble-promotion -Werror

CXXFLAGS	:= $(CFLAGS) -fno-rtti -fno-exceptions -std=gnu++11

ASFLAGS		:= -g $(ARCH)
LDFLAGS		:= -T $(TOPDIR)/3ds.ld $(ARCH) -Os -Wl,-Map,$(notdir $*.map),--gc-sections,--strip-discarded,--strip-debug
#LDFLAGS := -pie -specs=3dsx.specs -g $(ARCH) -mtp=soft -Wl,--section-start,.text=0x14000000 -Wl,--gc-sections

#---------------------------------------------------------------------------------
# no real need to edit anything past this point unless you need to add additional
# rules for different file extensions
#---------------------------------------------------------------------------------
ifneq ($(BUILD),$(notdir $(CURDIR)))
#---------------------------------------------------------------------------------

export OUTPUT	:=	$(CURDIR)/$(TARGET)
export TOPDIR	:=	$(CURDIR)

export VPATH	:=	$(foreach dir,$(SOURCES),$(CURDIR)/$(dir)) \

export DEPSDIR	:=	$(CURDIR)/$(BUILD)

CFILES			:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.c)))
CPPFILES		:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.cpp)))
SFILES			:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.s)))

export LD 		:= 	$(CXX)
export OFILES	:=	$(CPPFILES:.cpp=.o) $(CFILES:.c=.o) $(SFILES:.s=.o)

export INCLUDE	:=	$(foreach dir,$(INCLUDES),-I$(CURDIR)/$(dir)) \
					-I$(CURDIR)/$(BUILD)
					
.PHONY: $(BUILD) all

#---------------------------------------------------------------------------------
all: $(BUILD)

$(BUILD):
	@[ -d $@ ] || mkdir -p $@
	@$(MAKE) --no-print-directory -C $(BUILD) -f $(CURDIR)/Makefile
#---------------------------------------------------------------------------------

else

#---------------------------------------------------------------------------------
# main targets
#---------------------------------------------------------------------------------

DEPENDS	:=	$(OFILES:.o=.d)

$(OUTPUT).3gx : $(OFILES)

#---------------------------------------------------------------------------------
%.elf:
	$(SILENTMSG) linking $(notdir $@)
	$(ADD_COMPILE_COMMAND) end
	$(SILENTCMD)$(LD) $(LDFLAGS) $(OFILES) -o $@
	$(SILENTCMD)$(NM) -CSn $@ > $(notdir $*.lst)

%.3gx: %.elf
	@echo creating $(notdir $@)
	@$(OBJCOPY) -O binary $(OUTPUT).elf $(TOPDIR)/objdump -S
	@3gxtool.exe -s $(TOPDIR)/objdump $(TOPDIR)/CTRPluginFramework.plgInfo $@

-include $(DEPENDS)

#---------------------------------------------------------------------------------------
endif
#---------------------------------------------------------------------------------------

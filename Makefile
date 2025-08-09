#---------------------------------------------------------------------------------
.SUFFIXES:
#---------------------------------------------------------------------------------

ifeq ($(strip $(DEVKITARM)),)
$(error "Please set DEVKITARM in your environment. export DEVKITARM=<path to>devkitARM")
endif

TOPDIR ?= $(CURDIR)
include $(DEVKITARM)/base_rules

SOUCES_DIR		:=	Sources

TARGET		:= 	$(notdir $(CURDIR))
BUILD		:= 	Build
INCLUDES	:= 	$(SOUCES_DIR) Includes Includes/ctrulib Includes/ctrulib/allocator Includes/ctrulib/gpu Includes/ctrulib/services Includes/ctrulib/util

CTRPF_DIR		:=	$(SOUCES_DIR)/CTRPluginFramework
CTRPFIMPL_DIR	:=	$(SOUCES_DIR)/CTRPluginFrameworkImpl
SOURCES 		:= 	$(SOUCES_DIR) $(CTRPF_DIR) $(CTRPF_DIR)/Graphics $(CTRPF_DIR)/Menu $(CTRPF_DIR)/System $(CTRPF_DIR)/Utils $(CTRPFIMPL_DIR) $(CTRPFIMPL_DIR)/ActionReplay $(CTRPFIMPL_DIR)/Disassembler $(CTRPFIMPL_DIR)/Graphics $(CTRPFIMPL_DIR)/Graphics\Icons $(CTRPFIMPL_DIR)/Menu $(CTRPFIMPL_DIR)/Search $(CTRPFIMPL_DIR)/System $(SOUCES_DIR)/ctrulib $(SOUCES_DIR)/ctrulib/allocator $(SOUCES_DIR)/ctrulib/gpu $(SOUCES_DIR)/ctrulib/services $(SOUCES_DIR)/ctrulib/system $(SOUCES_DIR)/ctrulib/util/utf $(SOUCES_DIR)/ctrulib/util/rbtree
				
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

export INCLUDE	:=	$(foreach dir,$(INCLUDES),-I$(CURDIR)/$(dir))  	-I$(CURDIR)/$(BUILD)
					
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
#	$(SILENTCMD)$(NM) -CSn $@ > $(notdir $*.lst)

%.3gx: %.elf
	@echo creating $(notdir $@)
	@$(OBJCOPY) -O binary $(OUTPUT).elf $(TOPDIR)/objdump -S
	@3gxtool.exe -s $(TOPDIR)/objdump $(TOPDIR)/CTRPluginFramework.plgInfo $@

-include $(DEPENDS)

#---------------------------------------------------------------------------------------
endif
#---------------------------------------------------------------------------------------

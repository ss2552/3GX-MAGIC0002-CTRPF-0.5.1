.SUFFIXES:

ifeq ($(strip $(DEVKITARM)),)
$(error "Please set DEVKITARM in your environment. export DEVKITARM=<path to>devkitARM")
endif

TOPDIR 		?= 	$(CURDIR)
DKP_RULES	:=	 $(TOPDIR)/devkitpro_0_6_1
include		$(DKP_RULES)/3ds_rules

TARGET		:= 	CTRPluginFramework
PLGINFO 	:= 	CTRPluginFramework.plgInfo

BUILD		:= 	Build
INCLUDES	:= 	Includes
LIBDIRS		:= 	Lib
SOURCES 	:= 	Sources

#---------------------------------------------------------------------------------
# options for code generation
#---------------------------------------------------------------------------------
ARCH		:=	-march=armv6k -mlittle-endian -mtune=mpcore -mfloat-abi=hard 

CFLAGS		:=	-Os -mword-relocations \
				-fomit-frame-pointer -ffunction-sections -fno-strict-aliasing \
				$(ARCH)

CFLAGS		+=	$(INCLUDE) -DARM11 -D_3DS 

CXXFLAGS	:= $(CFLAGS) -fno-rtti -fno-exceptions -std=gnu++11

ASFLAGS		:=	$(ARCH)
LDFLAGS		:= -T $(TOPDIR)/3ds.ld $(ARCH) -Os -Wl,-Map,$(notdir $*.map),--gc-sections 

LIBS		:= -lCTRPluginFramework

#---------------------------------------------------------------------------------
# no real need to edit anything past this point unless you need to add additional
# rules for different file extensions
#---------------------------------------------------------------------------------
ifneq ($(BUILD),$(notdir $(CURDIR)))
#---------------------------------------------------------------------------------

export OUTPUT	:=	$(CURDIR)/$(TARGET)
export TOPDIR	:=	$(CURDIR)

export DEPSDIR	:=	$(CURDIR)/$(BUILD)

CPPFILES		:=	$(CURDIR)/$(SOURCES)/main.cpp
SFILES			:=	$(CURDIR)/$(SOURCES)/bootloader.s
#	BINFILES	:=	$(foreach dir,$(DATA),$(notdir $(wildcard $(dir)/*.*)))

export LD 		:= 	$(CXX)
export OFILES	:=	$(CPPFILES:.cpp=.o) $(SFILES:.s=.o)
export INCLUDE	:=	$(foreach dir,$(INCLUDES),-I $(CURDIR)/$(dir) ) -I $(CURDIR)/$(BUILD)

export LIBPATHS	:=	$(CURDIR)/$(LIBDIRS)/libCTRPluginFramework.a

.PHONY: $(BUILD)

#---------------------------------------------------------------------------------

$(BUILD):
	@[ -d $@ ] || mkdir -p $@
	@$(MAKE) --no-print-directory -C $(BUILD) -f $(CURDIR)/Makefile

#---------------------------------------------------------------------------------

else

DEPENDS	:=	$(OFILES:.o=.d)

#---------------------------------------------------------------------------------
# main targets
#---------------------------------------------------------------------------------
$(OUTPUT).3gx : $(OFILES)
#---------------------------------------------------------------------------------
# you need a rule like this for each extension you use as binary data
#---------------------------------------------------------------------------------
%.bin.o	:	%.bin
#---------------------------------------------------------------------------------
	@echo $(notdir $<)
	@$(bin2o)

#---------------------------------------------------------------------------------
%.3gx: %.elf
	@echo creating $(notdir $@)
	@3gxtool -s $(word 1, $^) $(TOPDIR)/$(PLGINFO) $@
#	@$(OBJCOPY) -O binary $(OUTPUT).elf $(TOPDIR)/objdump -S
#	@3gxtool -s $(TOPDIR)/objdump $(TOPDIR)/$(PLGINFO) $@
#	@- rm $(TOPDIR)/objdump

-include $(DEPENDS)

#---------------------------------------------------------------------------------------
endif
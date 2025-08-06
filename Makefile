.SUFFIXES:

TOPDIR 		?=	$(CURDIR)
DKP_RULES	:=	$(TOPDIR)/devkitpro_0_6_1

include $(DKP_RULES)/3ds_rules

TARGET		:= 	$(notdir $(CURDIR))
BUILD		:= 	Build
INCLUDES	:= 	Includes
SOURCES 	:= 	Sources
				
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

LIBS 		:= 	-lctru -lCTRPluginFramework
LIBDIRS		:= 	$(CTRULIB)

#---------------------------------------------------------------------------------
# no real need to edit anything past this point unless you need to add additional
# rules for different file extensions
#---------------------------------------------------------------------------------
ifneq ($(BUILD),$(notdir $(CURDIR)))
#---------------------------------------------------------------------------------

export OUTPUT	:=	$(CURDIR)/$(TARGET)
export LIBOUT	:=  $(CURDIR)/lib$(TARGET).a
export TOPDIR	:=	$(CURDIR)

export VPATH	:=	$(foreach dir,$(SOURCES),$(CURDIR)/$(dir)) \
					$(foreach dir,$(DATA),$(CURDIR)/$(dir))

export DEPSDIR	:=	$(CURDIR)/$(BUILD)

CPPFILES		:=	$(SOURCES)/main.cpp
SFILES			:=	$(SOURCES)/bootloader.s

export LD 		:= 	$(CXX)
export OFILES	:=	$(CPPFILES:.cpp=.o) $(CFILES:.c=.o) $(SFILES:.s=.o)

export INCLUDE	:=	$(foreach dir,$(INCLUDES),-I $(CURDIR)/$(dir) )

export LIBPATHS	:=	$(foreach dir,$(LIBDIRS),-L $(dir)/lib)

.PHONY: $(OUTPUT).3gx

DEPENDS	:=	$(OFILES:.o=.d)
EXCLUDE := main.o


$(OUTPUT).3gx : $(OFILES) $(LIBOUT)
$(LIBOUT):	$(filter-out $(EXCLUDE), $(OFILES))

#---------------------------------------------------------------------------------
# you need a rule like this for each extension you use as binary data
#---------------------------------------------------------------------------------
%.bin.o	:	%.bin
#---------------------------------------------------------------------------------
	@echo $(notdir $<)
	@$(bin2o)

%.elf:
 	@echo linking $(notdir $@)
 	@$(LD) $(LDFLAGS) $(OFILES) $(LIBPATHS) $(LIBS) -o $@
 	@$(NM) -CSn $@ > $(notdir $*.lst)
#---------------------------------------------------------------------------------
%.3gx: %.elf
	@echo creating $(notdir $@)
	@$(OBJCOPY) -O binary $@ $(TOPDIR)/objdump -S
	@3gxtool.exe -s $(TOPDIR)/objdump $(TOPDIR)/CTRPluginFramework.plgInfo $@

-include $(DEPENDS)





# .SUFFIXES:

# ifeq ($(strip $(DEVKITARM)),)
# $(error "Please set DEVKITARM in your environment. export DEVKITARM=<path to>devkitARM")
# endif

# TOPDIR 		?= 	$(CURDIR)
# DKP_RULES	:=	 $(TOPDIR)/devkitpro_0_6_1
# include $(DKP_RULES)/base_rules

# TARGET		:= 	CTRPluginFramework
# PLGINFO 	:= 	CTRPluginFramework.plgInfo

# BUILD		:= 	Build
# INCLUDES	:= 	Includes
# LIBDIRS		:= 	Lib
# SOURCES 	:= 	Sources

# #---------------------------------------------------------------------------------
# # options for code generation
# #---------------------------------------------------------------------------------
# ARCH		:=	-march=armv6k -mlittle-endian -mtune=mpcore -mfloat-abi=hard 

# CFLAGS		:=	-Os -mword-relocations \
# 				-fomit-frame-pointer -ffunction-sections -fno-strict-aliasing \
# 				$(ARCH)

# CFLAGS		+=	$(INCLUDE) -DARM11 -D_3DS 

# CXXFLAGS	:= $(CFLAGS) -fno-rtti -fno-exceptions -std=gnu++11

# ASFLAGS		:=	$(ARCH)
# LDFLAGS		:= -T $(TOPDIR)/3ds.ld $(ARCH) -Os -Wl,-Map,$(notdir $*.map),--gc-sections 

# LIBS		:= -lCTRPluginFramework -lctru

# #---------------------------------------------------------------------------------

# export OUTPUT	:=	$(CURDIR)/$(TARGET)
# export TOPDIR	:=	$(CURDIR)

# export DEPSDIR	:=	$(CURDIR)/$(BUILD)

# CPPFILES		:=	$(CURDIR)/$(SOURCES)/main.cpp
# SFILES			:=	$(CURDIR)/$(SOURCES)/bootloader.s
# #	BINFILES	:=	$(foreach dir,$(DATA),$(notdir $(wildcard $(dir)/*.*)))

# export LD 		:= 	$(CXX)
# export OFILES	:=	$(CPPFILES:.cpp=.o) $(SFILES:.s=.o)
# export INCLUDE	:=	$(foreach dir,$(INCLUDES),-I $(CURDIR)/$(dir) ) -I $(CURDIR)/$(BUILD)

# export LIBPATHS	:=	$(CURDIR)/$(LIBDIRS)/libCTRPluginFramework.a

# .PHONY: $(OUTPUT).3gx $(BUILD)

# PORTLIBS	:=	$(PORTLIBS_PATH)/3ds

# export PATH := $(PORTLIBS_PATH)/3ds/bin:$(PATH)

# CTRULIB	?=	$(DEVKITPRO)/libctru

# #---------------------------------------------------------------------------------

	
# DEPENDS	:=	$(OFILES:.o=.d)

# #---------------------------------------------------------------------------------
# # main targets
# #---------------------------------------------------------------------------------
# $(OUTPUT).3gx : $(OFILES)
# #---------------------------------------------------------------------------------
# # you need a rule like this for each extension you use as binary data
# #---------------------------------------------------------------------------------
# %.bin.o	:	%.bin
# #---------------------------------------------------------------------------------
# 	@echo $(notdir $<)
# 	@pwd
# 	@cd $(BUILD)
# 	@pwd
# 	@$(bin2o)

# #---------------------------------------------------------------------------------
# %.elf:
# 	@echo linking $(notdir $@)
# 	@$(LD) $(LDFLAGS) $(OFILES) $(LIBPATHS) $(LIBS) -o $@
# 	@$(NM) -CSn $@ > $(notdir $*.lst)

# %.3gx: %.elf
# 	@ls
# 	@echo 3gxの生成 $(word 1, $^)
# #@3gxtool -s $(word 1, $^) $(TOPDIR)/$(PLGINFO) $@
# 	@$(OBJCOPY) -O binary $@ $(TOPDIR)/objdump -S
# 	@3gxtool -s $(TOPDIR)/objdump $(TOPDIR)/$(PLGINFO) $@
# #	@- rm $(TOPDIR)/objdump

# -include $(DEPENDS)

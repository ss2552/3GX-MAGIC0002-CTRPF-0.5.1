.SUFFIXES:

ifeq ($(strip $(DEVKITARM)),)
$(error "DEVKITARMを環境変数に設定して下さい。 export DEVKITARM=<位置を>devkitARM")
endif

TOPDIR		?=	$(CURDIR)
include $(DEVKITARM)/3ds_rules

# ディレクトリー
TARGET		:= 	$(notdir $(CURDIR))
PLGINFO 	:= 	CTRPluginFramework.plgInfo
BUILD		:= 	Build
INCLUDES	:= 	Includes
LIBDIRS		:=  $(TOPDIR)/lib/CTRPluginFramework.a
SOURCES 	:= 	Sources

# cmake オプション -mtp=soft
ARCH		:=	-march=armv6k -mlittle-endian -mtune=mpcore -mfloat-abi=hard

CFLAGS		:=	-Os -mword-relocations \
				-fomit-frame-pointer -ffunction-sections -fno-strict-aliasing \
				$(ARCH)

CFLAGS		+=	$(INCLUDE) -DARM11 -D_3DS 

CXXFLAGS	:= $(CFLAGS) -fno-rtti -fno-exceptions -std=gnu++11

ASFLAGS		:=	$(ARCH)
LDFLAGS		:= -T $(TOPDIR)/3ds.ld $(ARCH) -Os -Wl,-Map,$(notdir $*.map),--gc-sections 

# ライブラリのパス
LIBS		:=	-lCTRPluginFramework




export OUTPUT	:=	$(CURDIR)/$(TARGET)
export TOPDIR	:=	$(CURDIR)
export VPATH	:=	$(foreach dir,$(SOURCES),$(CURDIR)/$(dir)) \
						$(foreach dir,$(DATA),$(CURDIR)/$(dir))

export DEPSDIR	:=	$(CURDIR)/$(BUILD)

CFILES			:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.c)))
CPPFILES		:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.cpp)))
SFILES			:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.s)))

export LD 		:= 	$(CXX)
export OFILES	:=	$(CPPFILES:.cpp=.o) $(CFILES:.c=.o) $(SFILES:.s=.o)
export INCLUDE	:=	$(foreach dir,$(INCLUDES),-I$(CURDIR)/$(dir)) \
					$(foreach dir,$(LIBDIRS),-I$(dir)/include) \
					-I$(CURDIR)/$(BUILD)

export LIBPATHS	:=	$(foreach dir,$(LIBDIRS),-L $(dir)/lib)

.PHONY:	$(BUILD) all

all: $(BUILD)

$(BUILD):
	@[ -d $@ ] || mkdir -p $@
	
DEPENDS	:=	$(OFILES:.o=.d)
$(OUTPUT).3gx	:	$(OFILES)

%.bin.o	:	%.bin
	@echo $(notdir $<)
	@$(bin2o)

.PRECIOUS: %.elf
%.3gx: %.elf
	@echo creating $(notdir $@)
	@3gxtool -s $(word 1, $^) $(TOPDIR)/$(PLGINFO) $@
#	@$(OBJCOPY) -O binary $(OUTPUT).elf $(TOPDIR)/objdump -S
#	@3gxtool -s $(TOPDIR)/objdump $(TOPDIR)/$(PLGINFO) $@

-include $(DEPENDS)
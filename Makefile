#---------------------------------------------------------------------------------
.SUFFIXES:
#---------------------------------------------------------------------------------

# devkitARMのパスが設定されていない場合はエラーを出す
ifeq ($(strip $(DEVKITARM)),)
$(error "Please set DEVKITARM in your environment. export DEVKITARM=<path to>devkitARM")
endif

# プロジェクトのトップディレクトリ
TOPDIR ?= $(CURDIR)
# devkitARMの共通ルールをインクルード
include $(DEVKITARM)/base_rules

# ソースディレクトリ
SOURCES_DIR		:=	Sources

# 出力ファイル名（カレントディレクトリ名）
TARGET		:= 	$(notdir $(CURDIR))
# ビルドディレクトリ
BUILD		:= 	Build
# インクルードディレクトリ一覧
INCLUDES	:= 	$(SOURCES_DIR) $(SOURCES_DIR)/ctrulib Includes Includes/ctrulib Includes/ctrulib/allocator Includes/ctrulib/gpu Includes/ctrulib/services Includes/ctrulib/util

# 各種サブディレクトリ
CTRPF_DIR		:=	$(SOURCES_DIR)/CTRPluginFramework
CTRPFIMPL_DIR	:=	$(SOURCES_DIR)/CTRPluginFrameworkImpl
# ソースファイル探索ディレクトリ一覧
SOURCES 		:= 	$(SOURCES_DIR) $(CTRPF_DIR) $(CTRPF_DIR)/Graphics $(CTRPF_DIR)/Menu $(CTRPF_DIR)/System $(CTRPF_DIR)/Utils $(CTRPFIMPL_DIR) $(CTRPFIMPL_DIR)/ActionReplay $(CTRPFIMPL_DIR)/Disassembler $(CTRPFIMPL_DIR)/Graphics $(CTRPFIMPL_DIR)/Graphics/Icons $(CTRPFIMPL_DIR)/Menu $(CTRPFIMPL_DIR)/Search $(CTRPFIMPL_DIR)/System $(SOURCES_DIR)/ctrulib $(SOURCES_DIR)/ctrulib/allocator $(SOURCES_DIR)/ctrulib/gpu $(SOURCES_DIR)/ctrulib/services $(SOURCES_DIR)/ctrulib/system $(SOURCES_DIR)/ctrulib/util/utf $(SOURCES_DIR)/ctrulib/util/rbtree
                
#---------------------------------------------------------------------------------
# コード生成オプション
#---------------------------------------------------------------------------------
ARCH	:=	-march=armv6k -mlittle-endian -mtune=mpcore -mfloat-abi=hard

# Cコンパイルフラグ
CFLAGS	:=	-g -Os -mword-relocations \
             -fomit-frame-pointer -ffunction-sections -fno-strict-aliasing \
            $(ARCH)

# インクルードパスと定義を追加
CFLAGS		+=	$(INCLUDE) -DARM11 -D_3DS
#-Wall -Wextra -Wdouble-promotion -Werror

# C++コンパイルフラグ
CXXFLAGS	:= $(CFLAGS) -fno-rtti -fno-exceptions -std=gnu++11

# アセンブラフラグ
ASFLAGS		:= -g $(ARCH)
# リンカフラグ
LDFLAGS		:= -T $(TOPDIR)/3ds.ld $(ARCH) -Os -Wl,-Map,$(notdir $*.map),--gc-sections,--strip-discarded,--strip-debug
#LDFLAGS := -pie -specs=3dsx.specs -g $(ARCH) -mtp=soft -Wl,--section-start,.text=0x14000000 -Wl,--gc-sections

#---------------------------------------------------------------------------------
# ここから下は拡張子ごとのルール追加以外は基本的に編集不要
#---------------------------------------------------------------------------------
ifneq ($(BUILD),$(notdir $(CURDIR)))
#---------------------------------------------------------------------------------

# 出力ファイルやビルド用変数をエクスポート
export OUTPUT	:=	$(CURDIR)/$(TARGET)
export TOPDIR	:=	$(CURDIR)

# ソース探索パス
export VPATH	:=	$(foreach dir,$(SOURCES),$(CURDIR)/$(dir)) \

# 依存ファイル出力先
export DEPSDIR	:=	$(CURDIR)/$(BUILD)

# 各種ソースファイルリスト
CFILES			:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.c)))
CPPFILES		:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.cpp)))
SFILES			:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.s)))

# リンカ、オブジェクトファイルリスト
export LD 		:= 	$(CXX)
export OFILES	:=	$(CPPFILES:.cpp=.o) $(CFILES:.c=.o) $(SFILES:.s=.o)

# インクルードパス
export INCLUDE	:=	$(foreach dir,$(INCLUDES),-I$(CURDIR)/$(dir))  	-I$(CURDIR)/$(BUILD)
                    
.PHONY: $(BUILD) all

#---------------------------------------------------------------------------------
# allターゲット（デフォルト）
all: $(BUILD)

# ビルドディレクトリ作成とサブメイク
$(BUILD):
	@[ -d $@ ] || mkdir -p $@
	@$(MAKE) --no-print-directory -C $(BUILD) -f $(CURDIR)/Makefile
#---------------------------------------------------------------------------------

else

#---------------------------------------------------------------------------------
# メインターゲット
#---------------------------------------------------------------------------------

DEPENDS	:=	$(OFILES:.o=.d)

$(OUTPUT).3gx : $(OFILES)

#---------------------------------------------------------------------------------
# ELFファイル生成ルール
%.elf:
	$(SILENTMSG) linking $(notdir $@)
	$(ADD_COMPILE_COMMAND) end
	$(SILENTCMD)$(LD) $(LDFLAGS) $(OFILES) -o $@
#	$(SILENTCMD)$(NM) -CSn $@ > $(notdir $*.lst)

# 3gxファイル生成ルール
%.3gx: %.elf
	@echo creating $(notdir $@)
	@$(OBJCOPY) -O binary $(OUTPUT).elf $(TOPDIR)/objdump -S
	@3gxtool.exe -s $(TOPDIR)/objdump $(TOPDIR)/CTRPluginFramework.plgInfo $@

-include $(DEPENDS)

#---------------------------------------------------------------------------------------
endif
#---------------------------------------------------------------------------------------

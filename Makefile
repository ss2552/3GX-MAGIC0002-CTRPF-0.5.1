#コメントアウトはgithub copilotを使用した

export SHELL := /usr/bin/env bash  # 使用するシェルを指定
DEVKITPATH=$(shell echo "$(DEVKITPRO)" | sed -e 's/^\([a-zA-Z]\):/\/\1/')  # WindowsパスをUNIX形式に変換
export PATH	:=	$(DEVKITPATH)/tools/bin:$(DEVKITPATH)/devkitARM/bin:$(DEVKITPRO)/portlibs/3ds/bin:$(PATH)  # 必要なツールのパスを追加

# ソースディレクトリのリスト
SOURCES		:=	Sources \
    Lib Lib\ctrulib Lib\ctrulib\allocator Lib\ctrulib\gpu Lib\ctrulib\services Lib\ctrulib\system Lib\ctrulib\util\utf Lib\ctrulib\util\rbtree
# 各ディレクトリ内の.cppファイルを取得
CPPFILES	:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.cpp)))
# 各ディレクトリ内の.sファイルを取得
SFILES		:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.s)))

# オブジェクトファイルと依存ファイルのリスト
OFILES	:=	$(CPPFILES:.cpp=.o) $(SFILES:.c=.s)
DEPENDS	:=	$(OFILES:.o=.d)

.PHONY: all  # allターゲットはファイルではないことを明示
all: 3gx0002ctrpf080.3gx  # デフォルトターゲット

# ARMアーキテクチャ用のコンパイルオプション
ARCH      := -march=armv6k -mlittle-endian -mtune=mpcore -mfloat-abi=hard

# C++コンパイルフラグ
CXXFLAGS  := -Os -mword-relocations \
            -fomit-frame-pointer -ffunction-sections -fno-strict-aliasing \
            $(ARCH) \
            -I Includes -I Includes\ctrulib \
            -DARM11 -D__3DS__ \
            -fno-rtti -fno-exceptions -std=gnu++11

# アセンブリファイルのビルドルール
$(OFILES).o: $(SFILES).s
	@echo $(notdir $<)
	arm-none-eabi-gcc -MMD -MP -MF $*.d -x assembler-with-cpp $(_EXTRADEFS) $(ARCH) -c $< -o $@

# C++ファイルのビルドルール
$(OFILES).o: $(CPPFILES).cpp
	@echo $(notdir $<)
	arm-none-eabi-gcc -MMD -MP -MF $*.d $(_EXTRADEFS) $(CXXFLAGS) -c $< -o $@

# リンカフラグ
LDFLAGS		:=	-T 3ds.ld $(ARCH) -Os -Wl,-Map,$(notdir $*.map),--gc-sections
LIBPATHS	:=	-L Lib  # ライブラリパス
LIBS		:=	-lCTRPluginFramework  # リンクするライブラリ

# ELFファイルのリンク
3gx0002ctrpf080.elf: $(OFILES).o
	@echo linking $(notdir $@)
	arm-none-eabi-gcc $(LDFLAGS) $(OFILES) $(LIBPATHS) $(LIBS) -o $@
    
# 3GXファイルの生成
3gx0002ctrpf080.3gx: 3gx0002ctrpf080.elf
	@echo creating $(notdir $@)
#	@$(OBJCOPY) -O binary 3gx0002ctrpf080.elf objdump -S
	@3gxtool -s $< CTRPluginFramework.plgInfo $@

-include $(DEPENDS)  # 依存関係ファイルをインクルード
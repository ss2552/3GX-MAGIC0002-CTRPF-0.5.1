#コメントアウトはgithub copilotを使用した

include base_tools

# ソースディレクトリのリスト
SOURCES		:=	Sources \
	Lib Lib/ctrulib Lib/ctrulib/allocator Lib/ctrulib/gpu Lib/ctrulib/services Lib/ctrulib/system Lib/ctrulib/util/utf Lib/ctrulib/util/rbtree
# 各ディレクトリ内の.cppファイルを取得
CPPFILES	:=	$(foreach dir,$(SOURCES),$(wildcard $(dir)/*.cpp))
# 各ディレクトリ内の.sファイルを取得
SFILES		:=	$(foreach dir,$(SOURCES),$(wildcard $(dir)/*.s))

# オブジェクトファイルと依存ファイルのリスト
OFILES	:=	$(CPPFILES:.cpp=.o) $(SFILES:.s=.o)
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
%.o: %.s
	@echo $(notdir $<)
	@arm-none-eabi-gcc -MMD -MP -MF $*.d -x assembler-with-cpp $(_EXTRADEFS) $(ARCH) -c $< -o $@ $(ERROR_FILTER)

# C++ファイルのビルドルール
%.o: %.cpp
	@echo $(notdir $<)
	@arm-none-eabi-gcc -MMD -MP -MF $*.d $(_EXTRADEFS) $(CXXFLAGS) -c $< -o $@ $(ERROR_FILTER)

# リンカフラグ
LDFLAGS		:=	-T 3ds.ld $(ARCH) -Os -Wl,-Map,$(notdir $*.map),--gc-sections
LIBPATHS	:=	-L Lib  # ライブラリパス
LIBS		:=	-lCTRPluginFramework  # リンクするライブラリ

# ELFファイルのリンク
3gx0002ctrpf080.elf: $(OFILES)
	@echo linking $(notdir $@)
	@arm-none-eabi-gcc $(LDFLAGS) $(OFILES) $(LIBPATHS) $(LIBS) -o $@ $(ERROR_FILTER)
	
# 3GXファイルの生成
3gx0002ctrpf080.3gx: 3gx0002ctrpf080.elf
	@echo creating $(notdir $@)
#	@$(OBJCOPY) -O binary 3gx0002ctrpf080.elf objdump -S
	@3gxtool -s $< CTRPluginFramework.plgInfo $@

-include $(DEPENDS)  # 依存関係ファイルをインクルード
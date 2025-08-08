#コメントアウトはgithub copilotを使用した

include base_tools

# ソースディレクトリのリスト
SOURCES		:=	Sources \
	Lib Lib/ctrulib Lib/ctrulib/allocator Lib/ctrulib/gpu Lib/ctrulib/services Lib/ctrulib/system Lib/ctrulib/util/utf Lib/ctrulib/util/rbtree
# 各ディレクトリ内の.cppファイルを取得
CPPFILES	:=	$(foreach dir,$(SOURCES),$(wildcard $(dir)/*.cpp))
# 各ディレクトリ内の.sファイルを取得
SFILES		:=	$(foreach dir,$(SOURCES),$(wildcard $(dir)/*.s))

OUTPUT	:=	Build  # 出力ディレクトリ

# オブジェクトファイルと依存ファイルのリスト
OFILES	:=	$(CPPFILES:.cpp=.o) $(SFILES:.s=.o)

.PHONY: all  # allターゲットはファイルではないことを明示
all: 3gx0002ctrpf080.3gx  # デフォルトターゲット

# ARMアーキテクチャ用のコンパイルオプション
ARCH      := -march=armv6k -mlittle-endian -mtune=mpcore -mfloat-abi=hard

# C++コンパイルフラグ
CXXFLAGS  := -Os -mword-relocations \
            -fomit-frame-pointer -ffunction-sections -fno-strict-aliasing \
            $(ARCH) \
            -I Includes -I Includes/ctrulib -I Includes/ctrulib/allocator -I Includes/ctrulib/gpu -I Includes/ctrulib/services -I Includes/ctrulib/system -I Includes/ctrulib/util/utf -I Includes/ctrulib/util/rbtree \
            -DARM11 -D__3DS__ \
            -fno-rtti -fno-exceptions -std=gnu++11

# アセンブリファイルのビルドルール
%.o: %.s
	@echo $(CURDIR)/$(notdir $<)
	@arm-none-eabi-gcc -MMD -MP -MF -x assembler-with-cpp $(_EXTRADEFS) $(ARCH) -c $< -o $(OUTPUT)/$@ $(ERROR_FILTER)

# C++ファイルのビルドルール
%.o: %.cpp
	@echo $(CURDIR)/$(notdir $<)
	@arm-none-eabi-g++ -MMD -MP -MF $(_EXTRADEFS) $(CXXFLAGS) -c $< -o $(OUTPUT)/$@ $(ERROR_FILTER)

# リンカフラグ
LDFLAGS		:=	-T 3ds.ld $(ARCH) -Os -Wl,-Map,$(notdir $*.map),--gc-sections
LIBPATHS	:=	-L Lib  # ライブラリパス
LIBS		:=	-lCTRPluginFramework  # リンクするライブラリ

# ELFファイルのリンク
3gx0002ctrpf080.elf: $(OFILES)
	@echo linking $(CURDIR)/$(notdir $@)
	@ls
	@arm-none-eabi-gcc $(LDFLAGS) $< $(LIBPATHS) $(LIBS) -o $(OUTPUT)/3gx0002ctrpf080.elf $(ERROR_FILTER)
	
# 3GXファイルの生成
3gx0002ctrpf080.3gx: 3gx0002ctrpf080.elf
	@echo creating $(CURDIR)/$(notdir $@)
#	@$(OBJCOPY) -O binary 3gx0002ctrpf080.elf objdump -S
	@3gxtool -s $(OUTPUT)/3gx0002ctrpf080.elf $(CURDIR)/CTRPluginFramework.plgInfo $(OUTPUT)/3gx0002ctrpf080.3gx

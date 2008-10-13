BIN_NAME=equa_prog.hex

SRCS=src/equa_prog.asm \
	src/common/global.asm  \
	src/common/delay.asm  \
	src/common/eeprom.asm  \
	src/common/encoder.asm  \
	src/common/io.asm  \
	src/common/spi.asm \
	src/common/lcd.asm \

IMGS=src/common/font.xcf

DEPEND_FILE=mkdepend

OBJ_DIR=obj
DEPEND_DIR=depend

AS=gpasm
LD=gplink

IMG2GPASM=utils/img2gpasm.sh

AS_FLAGS=-pp16f886
LINK_SCRIPT=16f886.lkr
LD_FLAGS= -c -ainhx32 -m -s$(LINK_SCRIPT)

OBJS=$(patsubst %.asm,$(OBJ_DIR)/%.o, $(SRCS))
DEPENDS=$(patsubst %.asm,$(OBJ_DIR)/%.d, $(SRCS))

OBJS_DIR=$(dir $(OBJS))
INC_DIR=$(dir $(SRCS))
UNIQ_INC_DIR=$(shell echo $(INC_DIR) | tr ' ' \\n | uniq)

INC_IMGS=$(addsuffix .inc,$(basename $(IMGS)))

.PHONY: all
all: make_dir image $(BIN_NAME)

.PHONY:prog
prog: all
	pk2cmd -PPIC16F886 -F$(BIN_NAME) -M

$(BIN_NAME): $(OBJS)
	$(LD) -o$@ $(LD_FLAGS) $^

.PHONY: image
image: $(INC_IMGS)

.PHONY: make_dir
make_dir:
	@-mkdir -p $(OBJS_DIR)

.PHONY: clean
clean:
	rm -f $(OBJS) $(BIN_NAME) $(DEPEND_FILE) $(DEPENDS) $(INC_IMGS)

.PHONY: depend
depend: make_dir $(DEPENDS)
	cat $(DEPENDS) > $(DEPEND_FILE)

$(OBJ_DIR)/%.o: %.asm
	$(AS) -c -M $(AS_FLAGS) -I. $(addprefix -I,$(UNIQ_INC_DIR)) $< -o $@

$(OBJ_DIR)/%.d: %.asm
	$(AS) -c -M $(AS_FLAGS) -I. $(addprefix -I,$(UNIQ_INC_DIR)) $< -o $@

%.inc: %.xcf
	$(IMG2GPASM) $< $@ 64 8 8

ifneq ($(strip $(wildcard $(DEPEND_FILE))),)
include $(DEPEND_FILE)
endif

BIN_NAME=equa_prog

SRCS=src/common/numpot.asm \
	src/common/global.asm  \
	src/common/delay.asm  \
	src/common/encoder.asm  \
	src/common/io.asm  \
	src/common/lcd.asm \
	src/common/menu.asm \
	src/common/menu_button.asm \
	src/common/menu_edit.asm \
	src/common/menu_eq.asm \
	src/common/spi.asm \
	src/common/std.asm \
	src/common/eeprom.asm  \
	src/common/flash.asm  \
	src/common/timer.asm  \
	src/common/math.asm  \
	src/equa_prog.asm \
	src/edit_eq.asm \
	src/edit_trem.asm \
	src/edit_common.asm \
	src/bank.asm \
	src/process.asm \
	src/io_interrupt.asm \

IMGS=src/common/font.xcf

OTHER_GEN_INC=src/common/numpot_mapping.inc

OBJ_DIR=obj

AS=gpasm
LD=gplink

IMG2GPASM=utils/img2gpasm.sh
NUMPOT_MAPPING=utils/numpot_mapping.py

AS_FLAGS=-pp16f886
UNASM_FLAGS=-pp16f886
LINK_SCRIPT=16f886.lkr
LD_FLAGS= -c -ainhx32 -m -s$(LINK_SCRIPT)

UNASM_NAME=$(BIN_NAME:.hex=.unasm)

OBJS=$(patsubst %.asm,$(OBJ_DIR)/%.o, $(SRCS))

OBJS_DIR=$(dir $(OBJS))
INC_DIR=$(dir $(SRCS))
UNIQ_INC_DIR=$(shell echo $(INC_DIR) | tr ' ' \\n | uniq)

INC_IMGS=$(addsuffix .inc,$(basename $(IMGS)))

MAKEDEP=Makefile.dep

.PHONY: all
all: make_dir image $(OTHER_GEN_INC) $(BIN_NAME)

.PHONY:prog
prog: all
	pk2cmd -B/usr/share/pk2 -PPIC16F886 -F$(BIN_NAME).hex -M -Z #-W

.PHONY:unasm
unasm: all
	gpdasm $(UNASM_FLAGS) $(BIN_NAME) > $(UNASM_NAME)

$(BIN_NAME): $(OBJS)
	$(LD) -o$@ $(LD_FLAGS) $^

.PHONY: image
image: $(INC_IMGS)

.PHONY: make_dir
make_dir:
	@-mkdir -p $(OBJS_DIR)

.PHONY: clean
clean:
	rm -f $(OBJS) $(BIN_NAME).*  $(INC_IMGS) $(OTHER_GEN_INC) $(MAKEDEP)

$(OBJ_DIR)/%.o: %.asm
	$(AS) -c -M $(AS_FLAGS) -I. $(addprefix -I,$(UNIQ_INC_DIR)) $< -o $@

$(OBJ_DIR)/%.d: %.asm
	$(AS) -c -M $(AS_FLAGS) -I. $(addprefix -I,$(UNIQ_INC_DIR)) $< -o $@

%.inc: %.xcf
	$(IMG2GPASM) $< $@ 64 32 8

src/common/numpot_mapping.inc:
	$(NUMPOT_MAPPING) > $@

sinclude $(MAKEDEP)
$(MAKEDEP): $(SRCS)
	touch $@
	makedepend $(addprefix -I,$(UNIQ_INC_DIR)) -p $(OBJ_DIR)/ -f $@ $(SRCS) 2> /dev/null
	-rm $(MAKEDEP).bak 2> /dev/null

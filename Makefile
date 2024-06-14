# ----------------------------------------------
# Makefile
# ----------------------------------------------
# @author Johannes Braun <hannenz@posteo.de>
# @package zoo
# @version 2024-06-09
# ----------------------------------------------
PRG:=zoo.prg
OBJECTS:=src/zoo.o src/zoo_ass.o
CC:=cc65
CA:=ca65
LD:=ld65
CONFIG:=conf/zoo.cfg
DISKIMAGE:=zoo.d64
HISCOREFILE:=data/zoo.hi
ASMINC=/usr/share/cc65/asminc # not really needed but I like being explicit

all: $(PRG) $(DISKIMAGE)

$(PRG): $(OBJECTS) $(CONFIG)
	# Link all together
	# -Ln zoo.lbl 	Generate a label file which can be used in Vice Monitor (type "ll zoo.lbl" in monitor to load and use it)
	# -o 			The output file
	# -C 			Use custom config file for memroy and file layout
	$(LD) -Ln zoo.lbl -o $@ -C $(CONFIG) $(OBJECTS) c64.lib

# Disable (cancel) make's implicit rule
%.o: %.c

%.o: %.s
	# Assembler: Generate .o from .s source code files
	# -g 		Generate debug info (will not end up in executablbe, so is fine to keep)
	# -t c64 	target platform `c64` (for character code conversion)
	# -o		The output file
	$(CA) -g -t c64 --include-dir $(ASMINC) -o $@ $<

%.s: %.c
	# C Compiler: Generate .s from .c source code files
	# -g 		Generate debug info (will not end up in executablbe, so is fine to keep)
	# -t c64 	target platform `c64`
	# -o		The output file
	$(CC) -g -t c64 -o $@ $<


# Write program and highscore file on a disk image
$(DISKIMAGE): $(PRG) $(HISCOREFILE)
	rm -rf $(DISKIMAGE)
	c1541 -format "zoo mania 2024",2a d64 $(DISKIMAGE)
	c1541 $(DISKIMAGE) -write $(PRG)
	c1541 $(DISKIMAGE) -write $(HISCOREFILE)



PHONY: clean
clean:
	rm -rf $(OBJECTS)
	rm -rf $(PRG)
	rm -rf $(DISKIMAGE)
	rm -rf zoo.lbl

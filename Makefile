zoo.prg: zoo.c zoo.h zoo_ass.s zoo.dat zootitle.pic jumper_msx
	cl65 -t c64 --config zoo.cfg -o zoo.prg zoo.c zoo_ass.s

clean:
	rm -rf *.o
	rm -rf *.prg

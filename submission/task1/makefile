all: encoder

encoder: start.o
	ld -m elf_i386 start.o -o encoder

start.o: start.s
	nasm -f elf32 start.s -o start.o

clean:
	rm -f *.o encoder

.PHONY: all clean

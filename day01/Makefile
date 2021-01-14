SRCS=$(wildcard *.asm)
OBJS=$(patsubst %.asm,%.o, $(SRCS))

all: soln

soln: soln.o string.o
	gcc -o $@ $? -no-pie

%.o: %.asm
	nasm -f elf64 -g -F dwarf $<

clean:
	rm *.o soln

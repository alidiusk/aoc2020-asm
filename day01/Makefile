all: soln

soln: soln.o
	gcc -o $@ $? -no-pie

%.o: %.asm
	nasm -f elf64 -g -F dwarf $<

clean:
	rm *.o soln

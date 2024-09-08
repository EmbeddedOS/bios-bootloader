all:
	nasm -f bin -o boot.bin boot.asm
	nasm -f bin -o loader.bin loader.asm
	dd if=boot.bin of=boot.img bs=512 count=1 conv=notrunc
	dd if=loader.bin of=boot.img bs=512 count=5 seek=1 conv=notrunc

	gcc -m32 -ffreestanding -c kernel.c -o kernel.o -fno-pie
	ld -m elf_i386 -o kernel.bin kernel.o -nostdlib --oformat=binary -Ttext=0x10000

	dd if=kernel.bin of=boot.img bs=512 count=5 seek=6 conv=notrunc
	dd if=/dev/zero of=boot.img bs=512 count=1 seek=11 conv=notrunc

clean:
	rm -f *.bin *.img *.o *.a
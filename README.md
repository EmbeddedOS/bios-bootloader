# bios-bootloader

A simple BIOS second stage bootloader to load the kernel. This repository includes a Master Boot Record sector code to load the second stage bootloader. the second stage bootloader will load the kernel.

## How to

To build a raw hard disk image:

```bash
./image.sh
```

To run qemu emulator:

```bash
qemu-system-i386 -hda boot.img
```

To boot with a USB drive:

```bash
sudo dd if=boot.img of=/dev/sdb
```

Full blog: [link](https://embeddedos.github.io/posts/Build-A-x86-Bootloader-BIOS/)
Youtube:

- [video 1](https://youtu.be/1sme52DW9WU?si=tJ5ERuBouEvU4jiu)
- [video 2](https://youtu.be/bX4CIuBaejM?si=5bLUQEb1YZprP4YC)

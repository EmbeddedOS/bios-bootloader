[BITS 16]
[ORG 0x7E00]

Start:
    ; 1. Load the kernel file to address 0x10000.
LoadKernel:
    mov si, ReadPacket
    mov word[si], 0x10          ; Packet size is 16 bytes.
    mov word[si + 2], 0x05      ; We will load 5 sectors from the disk.
    mov word[si + 4], 0x00      ; Memory offset.
    mov word[si + 6], 0x1000    ; Memory segment. So, we will load the kernel
                                ; code to physical memory at address: 0x1000 *
                                ; 0x10 + 0x00 = 0x10000
    mov dword[si + 8], 0x06     ; We load from sector 7th.
    mov dword[si + 12], 0x00

    mov ah, 0x42                ; Use INT 13 Extensions - EXTENDED READ service.
    int 0x13                    ; Call the Disk Service.
    jc ReadError                ; Carry flag will be set if error.

    ; 2. Set video mode.
SetVideoMode:
    mov ax, 0x03            ; AH=0x00 use BIOS VIDEO - SET VIDEO MODE service.
                            ; AL=0x03 use the base address to print at 0xB8000.
    int 0x10                ; Call the service.

    ; 3. Switch to protected mode.
SwitchToProtectedMode:
    cli                     ; Disable interrupts.
    lgdt [GDT32Pointer]     ; Load global descriptor table.
    lidt [IDT32Pointer]     ; Load an invalid IDT (NULL) because we don't deal
                            ; with interrupt.

    mov eax, cr0            ; We enable Protected Mode by set bit 0 of Control
    or eax, 0x01            ; register, that will change the processor behavior.
    mov cr0, eax

    jmp 0x08:PMEntry        ; Jump to Protected Mode Entry with selector select 
                            ; index 1 in GDT (code segment descriptor) so 
                            ; segment selector: Index=000000001, TI=0, RPL=00

; Halt CPU if we encounter some errors.
ReadError:
NotSupport:
    mov ah, 0x13
    mov al, 1
    mov bx, 0xA
    xor dx, dx
    mov bp, Message
    mov cx, MessageLen
    int 0x10

; Halt CPU if we encounter some errors.
End:
    hlt
    jmp End

Message:            db "Can not load kernel!"
MessageLen:         equ $-Message

DriveID:        db 0
ReadPacket:     times 16 db 0

; Global Descriptor Table Structure, we define 3 entries with 8 bytes for each.
GDT32:
    dq 0            ; First entry is NULL.
CodeSegDes32:       ; Next entry is Code Segment Descriptor.
    dw 0xFFFF       ; First two byte is segment size, we set to maximum size for
                    ; code segment.
    db 0, 0, 0      ; Next three byte are the lower 24 bits of base address, we
                    ; set to 0, means the code segment starts from 0.
    db 0b10011010   ; Next byte specifies the segment attributes, we will set
                    ; code segment attributes: P=1, DPL=00, S=1, TYPE=1010.
    db 0b11001111   ; Next byte is segment size and attributes, we will set code
                    ; segment attributes and size: G=1,D=1,L=0,A=0,LIMIT=1111.
    db 0            ; Last byte is higher 24 bits of bit address, we set to 0,
                    ; means the code segment starts from 0.
DataSegDes32:       ; Next entry is Data Segment Descriptor. We will set data
                    ; and code segment base on same memory (address + size).
    dw 0xFFFF
    db 0, 0, 0
    db 0b10010010   ; Different between data segment and code segment descriptor
                    ; is the type segment attributes: TYPE=0010 means this a
                    ; WRITABLE segment.
    db 0b11001111
    db 0

GDT32Len: equ $-GDT32

GDT32Pointer: dw GDT32Len - 1   ; First two bytes is GDT length.
              dd GDT32          ; Second is GDT32 address.

IDT32Pointer: dw 0              ; First two bytes is IDT length.
              dd 0              ; Second is IDT32 address.

[BITS 32]
PMEntry:
    ; 4. In Protected mode, segment registers are meaningless, so we initialize
    ; them to data segment descriptor entry.
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov gs, ax
    mov fs, ax
    mov ss, ax

    mov esp, 0x7c00

    ; 5. Jump to kernel main function.
    jmp 0x08:0x10000
    jmp $
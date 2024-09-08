;  ___________________
; |        Free       | -> We will use this region for Protected Mode kernel.
; |___________________| 0x010000
; |    Second-Stage   |
; |      Loader       |
; |___________________| 0x7E00
; |     MBR code      | 
; |___________________| 0x7C00
; |      Free         | -> We used this region for stack.
; |-------------------|
; | BIOS data vectors |
; |-------------------| 0

[BITS 16]
[ORG 0x7C00]

jmp short Start
nop

; TODO: Setup BIOS Parameters Block here.

Start:
    ; 1. Clear segment registers.
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax

    ; 2. Set up SP starting at address 0x7C00 and grows downwards.
    mov sp, 0x7C00

    ; 3. Load the second-stage loader.
LoadLoader:
    mov si, ReadPacket          ; Load the packet address to si.
    mov word[si], 0x10          ; Packet size is 16 bytes.
    mov word[si + 2], 0x05      ; We we load 5 sectors which is enough space
                                ; for our second-stage loader.
    mov word[si + 4], 0x7E00    ; Offset which we want to read loader file.
    mov word[si + 6], 0x00      ; Segment, the logical memory to load the file
                                ; is: 0x00 * 0x10 + 0x7E00 = 0x7E00
    mov dword[si + 8], 0x01     ; 32 bit low address of LBA.
    mov dword[si + 12], 0x00    ; 32 bit high address of LBA.
                                ; We will start at sector 2 but set 1 to LBA
                                ; Because the LBA is zero-based address.

    mov ah, 0x42                ; Use INT 13 Extensions - EXTENDED READ service.
    int 0x13                    ; Call the Disk Service.
    jc ReadError                ; Carry flag will be set if error.

    ; 5. Loader code has been loaded to physical memory, jump to loader code and 
    ; transfer control to it.
    jmp 0x7E00

NotSupport:
ReadError:
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

Message:            db "Can not load second-stage bootloader!"
MessageLen:         equ $-Message

; Disk Address Packet Structure.
ReadPacket:         times 16 db 0

; Fill 0 to all the rest memory up to 0x1BE.
times (0x1BE-($-$$)) db 0

; End of boot sector, we need 16 * 4 = 64 bytes for 4 partition entries. Some
; BIOS will try to find the valid partition entries. We want the BIOS treat our
; image as a hard disk and boot from them, so we need to define these entries.
; The first  partition entry:
db 0x80                     ; Boot indicator, 0x80 means boot-able partition.
db 0, 2, 0                  ; Starting of CHS value (Cylinder, Head, Sector).
db 0xF0                     ; Type of sector.
db 0xFF, 0xFF, 0xFF         ; Ending of CHS value (Cylinder, Head, Sector).
dd 1                        ; Starting sector.
dd (20*16*63 - 1)           ; Size of our disk: 10MB.

; Other entries are set to 0.
times (16*3) db 0

db 0x55
db 0xAA
; memcpy.asm -- copy 32 words, two at a time (memory bound: 50% loads/stores)
; Owner: Jatin
; Source 0x20..0x3F, destination 0x60..0x7F. Afterwards the destination is
; summed and the checksum is sent to the output port.

        li   r7, 256
        li   r1, 32          ; src
        li   r2, 96          ; dst
        li   r3, 32          ; words left
copy:   lw   r4, 0(r1)
        lw   r5, 1(r1)
        sw   r4, 0(r2)
        sw   r5, 1(r2)
        addi r1, r1, 2
        addi r2, r2, 2
        addi r3, r3, -2
        bne  r3, r0, copy

        li   r2, 96          ; checksum of destination
        li   r3, 32
        li   r6, 0
sum:    lw   r4, 0(r2)
        add  r6, r6, r4
        addi r2, r2, 1
        addi r3, r3, -1
        bne  r3, r0, sum
        out  r6
        halt

.data 0x20
.word  1  4  7 10 13 16 19 22 25 28 31 34 37 40 43 46
.word 49 52 55 58 61 64 67 70 73 76 79 82 85 88 91 94
.expect 1520

; vector_add.asm -- C[i] = A[i] + B[i] for 16 elements
; Owner: Jatin
; A at 0x80, B at 0x90, C at 0xA0. Checksum of C is sent out.

        li   r7, 256
        li   r1, 128         ; r1 = &A[i]   (B[i] is 16 words further)
        li   r2, 160         ; r2 = &C[i]
        li   r3, 16          ; count
        li   r6, 0           ; checksum
loop:   lw   r4, 0(r1)       ; A[i]
        lw   r5, 16(r1)      ; B[i]
        add  r4, r4, r5
        sw   r4, 0(r2)       ; C[i]
        add  r6, r6, r4
        addi r1, r1, 1
        addi r2, r2, 1
        addi r3, r3, -1
        bne  r3, r0, loop
        out  r6
        halt

.data 0x80
.word   0   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15
.word 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115
.expect 1840

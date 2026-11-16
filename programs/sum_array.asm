; sum_array.asm -- add 16 words of an array (load heavy)
; Owner: Jatin
; Array lives at data words 0x10..0x1F, result is stored at 0x00 and sent out.

        li   r7, 256        ; r7 = I/O base (output port)
        li   r1, 16         ; r1 = pointer to array
        li   r2, 16         ; r2 = elements left
        li   r3, 0          ; r3 = running sum
loop:   lw   r4, 0(r1)
        add  r3, r3, r4
        addi r1, r1, 1
        addi r2, r2, -1
        bne  r2, r0, loop
        sw   r3, 0(r0)      ; DMEM[0] = sum
        out  r3
        halt

.data 0x10
.word 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16
.expect 136

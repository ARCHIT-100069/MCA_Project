; fibonacci.asm -- compute F(20) in registers (compute bound, almost no memory)
; Owner: Jatin

        li   r7, 256
        li   r1, 0           ; F(k-1)
        li   r2, 1           ; F(k)
        li   r4, 19          ; iterations
loop:   add  r3, r1, r2
        mov  r1, r2
        mov  r2, r3
        addi r4, r4, -1
        bne  r4, r0, loop
        sw   r2, 0(r0)       ; DMEM[0] = F(20)
        out  r2
        halt

.expect 6765

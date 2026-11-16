; bubble_sort.asm -- sort 8 words in place, then print them (mixed workload)
; Owner: Jatin
; Array at 0x40..0x47.

        li   r7, 256
        li   r6, 7           ; passes left
outer:  li   r1, 64          ; pointer to a[0]
        mov  r5, r6          ; comparisons in this pass
inner:  lw   r2, 0(r1)       ; a[j]
        lw   r3, 1(r1)       ; a[j+1]
        slt  r4, r3, r2      ; a[j+1] < a[j] ?
        beq  r4, r0, noswap
        sw   r3, 0(r1)
        sw   r2, 1(r1)
noswap: addi r1, r1, 1
        addi r5, r5, -1
        bne  r5, r0, inner
        addi r6, r6, -1
        bne  r6, r0, outer

        li   r1, 64          ; print sorted array
        li   r5, 8
print:  lw   r2, 0(r1)
        out  r2
        addi r1, r1, 1
        addi r5, r5, -1
        bne  r5, r0, print
        halt

.data 0x40
.word 23 5 99 42 7 64 1 18
.expect 1 5 7 18 23 42 64 99

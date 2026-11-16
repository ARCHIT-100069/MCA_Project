; io_decode.asm -- exercises the address decoder and read/write control
; Owner: Jatin
;   * stores and reloads the first and last data-memory words (0x00, 0xFF)
;   * writes the output port (0x100)
;   * reads the cycle counter (0x101) twice and checks that it advanced

        li   r7, 256
        li   r1, 0x1A5
        sw   r1, 0(r0)       ; DMEM[0x00]
        li   r2, 255
        li   r3, 0x0C3
        sw   r3, 0(r2)       ; DMEM[0xFF]
        lw   r4, 0(r0)
        lw   r5, 0(r2)
        out  r4              ; expect 0x1A5
        out  r5              ; expect 0x0C3
        lw   r4, 1(r7)       ; cycle counter, first read
        nop
        lw   r5, 1(r7)       ; cycle counter, second read
        slt  r6, r4, r5      ; 1 if the counter advanced
        out  r6
        halt

.expect 0x1A5 0x0C3 1

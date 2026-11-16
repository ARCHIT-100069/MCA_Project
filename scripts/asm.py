#!/usr/bin/env python3
"""
asm.py -- two-pass assembler for the MH-16 ISA
Owner : Jatin

Usage:
    python3 scripts/asm.py programs/sum_array.asm build/programs

Writes three files next to each other:
    <name>.imem.hex   256 instruction words (HALT padded)
    <name>.dmem.hex   256 data words (zero padded)
    <name>.expect.hex expected output-port values, first line = count

Syntax
    label:  add  r1, r2, r3        ; comments start with ';' or '#'
            addi r1, r1, -1
            lw   r4, 2(r1)         ; rd, imm(rs)
            sw   r4, 0(r1)
            beq  r1, r2, label     ; branch targets are labels or numbers
            li   r7, 256           ; 0..511
            j    label
            halt
    pseudo-instructions
            nop            -> add r0, r0, r0
            mov rd, rs     -> add rd, rs, r0
            out rd         -> sw  rd, 0(r7)     (r7 must hold 0x100)
    directives
            .data <addr>          start of data words at word address <addr>
            .word v1 v2 ...       data words (decimal, 0x.., negative ok)
            .expect v1 v2 ...     expected values written to the output port
"""
import re
import sys
from pathlib import Path

OPCODES = {"addi": 0x1, "lw": 0x2, "sw": 0x3, "beq": 0x4, "bne": 0x5,
           "li": 0x6, "j": 0x7, "halt": 0xF}
ALU_FUNCT = {"add": 0, "sub": 1, "and": 2, "or": 3, "xor": 4,
             "slt": 5, "sll": 6, "srl": 7}
IMEM_WORDS = 256
DMEM_WORDS = 256


class AsmError(Exception):
    pass


def parse_int(tok):
    tok = tok.strip()
    try:
        return int(tok, 0)
    except ValueError as exc:
        raise AsmError(f"bad number '{tok}'") from exc


def reg(tok):
    tok = tok.strip().lower()
    if not re.fullmatch(r"r[0-7]", tok):
        raise AsmError(f"bad register '{tok}'")
    return int(tok[1])


def check_range(val, lo, hi, what):
    if not lo <= val <= hi:
        raise AsmError(f"{what} {val} out of range [{lo}, {hi}]")
    return val


def expand_pseudo(mnem, args):
    if mnem == "nop":
        return "add", ["r0", "r0", "r0"]
    if mnem == "mov":
        return "add", [args[0], args[1], "r0"]
    if mnem == "out":
        return "sw", [args[0], "0(r7)"]
    return mnem, args


def strip_comment(line):
    return re.split(r"[;#]", line, maxsplit=1)[0].strip()


def assemble(src_text):
    # ---------------------------------------------------------- pass 1
    labels, code, data, expect = {}, [], {}, []
    data_ptr, in_data = 0, False
    for lineno, raw in enumerate(src_text.splitlines(), 1):
        line = strip_comment(raw)
        if not line:
            continue
        try:
            while ":" in line:
                label, line = line.split(":", 1)
                label = label.strip()
                if label in labels:
                    raise AsmError(f"duplicate label '{label}'")
                labels[label] = data_ptr if in_data else len(code)
                line = line.strip()
            if not line:
                continue
            parts = line.split(None, 1)
            mnem = parts[0].lower()
            rest = parts[1] if len(parts) > 1 else ""
            if mnem == ".data":
                in_data, data_ptr = True, parse_int(rest)
            elif mnem == ".word":
                for tok in rest.replace(",", " ").split():
                    data[data_ptr] = parse_int(tok) & 0xFFFF
                    data_ptr += 1
            elif mnem == ".expect":
                expect += [parse_int(t) & 0xFFFF for t in rest.replace(",", " ").split()]
            else:
                if in_data:
                    raise AsmError("instruction after .data")
                args = [a.strip() for a in rest.split(",")] if rest else []
                code.append((lineno, *expand_pseudo(mnem, args)))
        except AsmError as exc:
            raise AsmError(f"line {lineno}: {exc}") from None

    # ---------------------------------------------------------- pass 2
    words = []
    for pc, (lineno, mnem, args) in enumerate(code):
        try:
            words.append(encode(pc, mnem, args, labels))
        except (AsmError, IndexError) as exc:
            raise AsmError(f"line {lineno}: {mnem} {', '.join(args)}: {exc}") from None
    if len(words) > IMEM_WORDS:
        raise AsmError("program larger than instruction memory")
    if data and max(data) >= DMEM_WORDS:
        raise AsmError("data outside data memory")
    return words, data, expect


def value_or_label(tok, labels):
    tok = tok.strip()
    return labels[tok] if tok in labels else parse_int(tok)


def encode(pc, mnem, args, labels):
    if mnem in ALU_FUNCT:
        rd, rs, rt = (reg(a) for a in args[:3])
        return (rd << 9) | (rs << 6) | (rt << 3) | ALU_FUNCT[mnem]
    if mnem not in OPCODES:
        raise AsmError("unknown instruction")
    op = OPCODES[mnem] << 12
    if mnem == "halt":
        return op
    if mnem == "j":
        return op | check_range(value_or_label(args[0], labels), 0, IMEM_WORDS - 1, "jump target")
    if mnem == "li":
        return op | (reg(args[0]) << 9) | check_range(value_or_label(args[1], labels), 0, 511, "li immediate")
    if mnem == "addi":
        imm = check_range(value_or_label(args[2], labels), -32, 31, "immediate")
        return op | (reg(args[0]) << 9) | (reg(args[1]) << 6) | (imm & 0x3F)
    if mnem in ("lw", "sw"):
        m = re.fullmatch(r"(.*)\((r[0-7])\)", args[1].replace(" ", ""))
        if not m:
            raise AsmError("expected imm(rs)")
        imm = check_range(value_or_label(m.group(1) or "0", labels), -32, 31, "offset")
        return op | (reg(args[0]) << 9) | (reg(m.group(2)) << 6) | (imm & 0x3F)
    if mnem in ("beq", "bne"):
        off = value_or_label(args[2], labels) - (pc + 1)
        check_range(off, -32, 31, "branch offset")
        return op | (reg(args[0]) << 9) | (reg(args[1]) << 6) | (off & 0x3F)
    raise AsmError("unknown instruction")


def write_outputs(src, outdir):
    words, data, expect = assemble(Path(src).read_text())
    name = Path(src).stem
    outdir = Path(outdir)
    outdir.mkdir(parents=True, exist_ok=True)
    imem = words + [0xF000] * (IMEM_WORDS - len(words))
    dmem = [data.get(i, 0) for i in range(DMEM_WORDS)]
    (outdir / f"{name}.imem.hex").write_text("".join(f"{w:04x}\n" for w in imem))
    (outdir / f"{name}.dmem.hex").write_text("".join(f"{w:04x}\n" for w in dmem))
    (outdir / f"{name}.expect.hex").write_text("".join(f"{w:04x}\n" for w in ([len(expect)] + expect + [0] * 256)[:256]))
    print(f"{name}: {len(words)} instructions, {len(data)} data words, {len(expect)} expected outputs")


def main(argv):
    if len(argv) != 3:
        print(__doc__)
        return 1
    try:
        write_outputs(argv[1], argv[2])
    except AsmError as exc:
        print(f"{argv[1]}: error: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))

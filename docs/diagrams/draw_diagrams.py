#!/usr/bin/env python3
"""
draw_diagrams.py -- block diagrams of both memory organizations
Owner : Kumar Sanu

    python3 docs/diagrams/draw_diagrams.py docs/diagrams

Writes harvard_block_diagram.(png|svg), vonneumann_block_diagram.(png|svg)
and system_overview.(png|svg). Needs matplotlib.
"""
import sys
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch

CORE, IPATH, DPATH, SHARED, CTRL = "#e8eef8", "#dcebdc", "#fbe7d6", "#f3e3f0", "#f4f4f4"
EDGE = "#333333"


def box(ax, x, y, w, h, title, sub="", color=CTRL):
    ax.add_patch(FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0.02,rounding_size=0.12",
                                fc=color, ec=EDGE, lw=1.2))
    ax.text(x + w / 2, y + h / 2 + (0.16 if sub else 0), title, ha="center", va="center",
            fontsize=10, weight="bold")
    if sub:
        ax.text(x + w / 2, y + h / 2 - 0.22, sub, ha="center", va="center", fontsize=7.5, color="#444")


def arrow(ax, x0, y0, x1, y1, label="", color=EDGE, both=False, lpos=0.5, loff=(0, 0.13)):
    ax.annotate("", xy=(x1, y1), xytext=(x0, y0),
                arrowprops=dict(arrowstyle="<|-|>" if both else "-|>", color=color, lw=1.4,
                                shrinkA=0, shrinkB=0))
    if label:
        ax.text(x0 + (x1 - x0) * lpos + loff[0], y0 + (y1 - y0) * lpos + loff[1], label,
                ha="center", va="bottom", fontsize=7.5, color=color)


def canvas(w, h, title):
    fig, ax = plt.subplots(figsize=(w, h))
    ax.set_xlim(0, w)
    ax.set_ylim(0, h)
    ax.axis("off")
    ax.set_title(title, fontsize=12, weight="bold")
    return fig, ax


def harvard(out):
    fig, ax = canvas(12, 6.2, "Proposed design: Harvard instruction / data organization (harvard_top.v)")
    # core
    ax.add_patch(FancyBboxPatch((0.4, 0.6), 4.2, 4.6, boxstyle="round,pad=0.02,rounding_size=0.15",
                                fc=CORE, ec=EDGE, lw=1.4))
    ax.text(2.5, 4.95, "cpu_core (MH-16, single cycle)", ha="center", fontsize=10, weight="bold")
    box(ax, 0.7, 3.6, 1.5, 0.9, "Program", "Counter", "white")
    box(ax, 2.6, 3.6, 1.7, 0.9, "Decode", "op / rd / rs / imm", "white")
    box(ax, 0.7, 1.0, 1.5, 1.1, "Register", "file 8x16", "white")
    box(ax, 2.6, 1.0, 1.7, 1.1, "ALU", "16-bit", "white")
    box(ax, 0.7, 2.35, 3.6, 0.8, "Next-PC logic", "pc+1 / branch / jump / halt", "white")
    # instruction path
    box(ax, 6.0, 3.7, 2.3, 1.3, "instr_mem", "ROM 256 x 16, async read", IPATH)
    arrow(ax, 2.2, 4.75, 6.0, 4.6, "instruction address (pc[7:0])", "#2b6b2b", lpos=0.62)
    arrow(ax, 6.0, 4.0, 4.3, 4.0, "instruction[15:0]", "#2b6b2b", lpos=0.5)
    ax.text(7.15, 5.25, "INSTRUCTION PATH", ha="center", fontsize=8.5, color="#2b6b2b", weight="bold")
    # data path
    box(ax, 5.5, 1.75, 1.8, 1.0, "addr_decoder", "0x000-0x0FF / 0x100 / 0x101", CTRL)
    box(ax, 7.8, 1.75, 1.7, 1.0, "rw_control", "enables + read mux", CTRL)
    box(ax, 10.0, 2.45, 1.7, 1.1, "data_mem", "RAM 256 x 16", DPATH)
    box(ax, 10.0, 0.75, 1.7, 1.2, "I/O", "OUT port 0x100\ncycle ctr 0x101", DPATH)
    arrow(ax, 4.3, 1.55, 5.5, 2.1, "data addr", "#9a4a12", lpos=0.45, loff=(-0.1, 0.05))
    arrow(ax, 7.3, 2.25, 7.8, 2.25)
    arrow(ax, 9.5, 2.5, 10.0, 2.9, "re / we", "#9a4a12", lpos=0.5, loff=(-0.25, 0.05))
    arrow(ax, 9.5, 1.95, 10.0, 1.4, "out_we", "#9a4a12", lpos=0.5, loff=(-0.3, -0.25))
    arrow(ax, 8.65, 1.75, 4.3, 1.2, "read data", "#9a4a12", lpos=0.5, loff=(0, -0.35))
    arrow(ax, 4.3, 0.85, 10.0, 0.85, "write data (rd)", "#9a4a12", lpos=0.62, loff=(0, -0.3))
    ax.text(8.6, 3.4, "DATA PATH", ha="center", fontsize=8.5, color="#9a4a12", weight="bold")
    ax.text(6, 0.12, "Both paths are independent: an instruction fetch and a load/store complete in the "
            "same clock cycle  ->  CPI = 1", ha="center", fontsize=9, style="italic")
    save(fig, out, "harvard_block_diagram")


def vonneumann(out):
    fig, ax = canvas(12, 5.6, "Baseline: shared single-port (Von Neumann) organization (vonneumann_top.v)")
    ax.add_patch(FancyBboxPatch((0.4, 0.9), 3.6, 3.8, boxstyle="round,pad=0.02,rounding_size=0.15",
                                fc=CORE, ec=EDGE, lw=1.4))
    ax.text(2.2, 4.4, "cpu_core (same core)", ha="center", fontsize=10, weight="bold")
    ax.text(2.2, 2.8, "PC, decode,\nregister file, ALU", ha="center", fontsize=9)
    ax.text(2.2, 1.5, "stall input freezes\nPC + writeback", ha="center", fontsize=8, color="#7a1f1f")
    box(ax, 5.0, 3.0, 2.6, 1.4, "Port arbiter FSM", "FETCH -> (LW/SW) -> DATA\nlatches IR and MAR", SHARED)
    box(ax, 5.0, 0.9, 2.6, 1.3, "addr_decoder +\nrw_control", "", CTRL)
    box(ax, 9.0, 1.6, 2.6, 2.3, "unified_mem", "512 x 16, ONE port\n0x000-0x0FF code\n0x100-0x1FF data", SHARED)
    arrow(ax, 4.0, 4.0, 5.0, 4.0, "pc", lpos=0.5)
    arrow(ax, 4.0, 1.5, 5.0, 1.5, "data addr", lpos=0.5)
    arrow(ax, 7.6, 3.55, 9.0, 3.2, "addr = FETCH ? pc : MAR", "#7a1f1f", lpos=0.5, loff=(0, 0.12))
    arrow(ax, 7.6, 1.5, 9.0, 2.1, "we (DATA only)", lpos=0.5, loff=(-0.1, -0.35))
    arrow(ax, 9.0, 2.65, 7.6, 2.65, "rdata", lpos=0.5, loff=(0, 0.03))
    arrow(ax, 5.0, 3.3, 4.0, 3.3, "instr (mem or IR)", lpos=0.5, loff=(0, -0.38))
    arrow(ax, 5.0, 2.6, 4.0, 2.6, "stall", "#7a1f1f", lpos=0.5, loff=(0, 0.03))
    ax.text(6, 0.25, "Fetch and data access compete for one port: each LW/SW takes 2 cycles  ->  "
            "CPI = 1 + (loads + stores) / instructions", ha="center", fontsize=9, style="italic")
    save(fig, out, "vonneumann_block_diagram")


def overview(out):
    fig, ax = canvas(12, 4.2, "Verification and comparison flow")
    steps = [("programs/*.asm", "6 benchmark programs"), ("scripts/asm.py", "assembler -> hex"),
             ("tb_system.v", "same program on\nboth machines"), ("checks", "outputs, halt,\nmemory equal"),
             ("results.csv", "cycles, CPI,\nspeed-up"), ("plots + report", "charts, tables")]
    x = 0.3
    for i, (t, s) in enumerate(steps):
        box(ax, x, 1.4, 1.65, 1.5, t, s, [CTRL, IPATH, CORE, DPATH, SHARED, CTRL][i])
        if i < len(steps) - 1:
            arrow(ax, x + 1.65, 2.15, x + 2.0, 2.15)
        x += 2.0
    ax.text(6, 0.6, "Unit tests: tb_memories.v (267 checks), tb_decoder_rw.v (13 directed cases).  "
            "Synthesis: Yosys, Xilinx 7-series.", ha="center", fontsize=9)
    save(fig, out, "system_overview")


def save(fig, out, name):
    fig.tight_layout()
    fig.savefig(out / f"{name}.png", dpi=150)
    fig.savefig(out / f"{name}.svg")
    plt.close(fig)
    print(f"wrote {name}.png / .svg")


if __name__ == "__main__":
    o = Path(sys.argv[1] if len(sys.argv) > 1 else "docs/diagrams")
    o.mkdir(parents=True, exist_ok=True)
    harvard(o)
    vonneumann(o)
    overview(o)

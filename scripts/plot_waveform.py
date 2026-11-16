#!/usr/bin/env python3
"""
plot_waveform.py -- turn build/waves.vcd into a timing-diagram PNG
Owner : Mukund Mangla

    ./scripts/run_all.sh --vcd
    python3 scripts/plot_waveform.py build/waves.vcd docs/evidence/waveform_sum_array.png

Shows the first cycles of sum_array on both machines: on the Harvard side the
instruction fetch and the data read happen in the same cycle; on the Von
Neumann side every LW needs an extra DATA cycle in which the PC is frozen.
Needs matplotlib.
"""
import sys
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

SIGNALS = [  # (label, hierarchical name, kind)
    ("clk",                 "tb_system.clk", "bit"),
    ("H: pc (imem addr)",   "tb_system.u_harvard.u_core.imem_addr", "bus"),
    ("H: instruction",      "tb_system.u_harvard.instr", "bus"),
    ("H: dmem_re",          "tb_system.u_harvard.dmem_re", "bit"),
    ("H: dmem addr",        "tb_system.u_harvard.dmem_addr", "bus"),
    ("VN: arbiter state",   "tb_system.u_vonneumann.state", "bit"),
    ("VN: stall",           "tb_system.u_vonneumann.stall", "bit"),
    ("VN: pc",              "tb_system.u_vonneumann.pc", "bus"),
    ("VN: shared mem addr", "tb_system.u_vonneumann.mem_addr", "bus"),
]


def parse_vcd(path, wanted):
    ids, scope, changes, t = {}, [], {}, 0
    with open(path) as fh:
        tokens = iter(fh.read().split())
    for tok in tokens:
        if tok == "$scope":
            next(tokens); scope.append(next(tokens))
        elif tok == "$upscope":
            scope.pop()
        elif tok == "$var":
            next(tokens); next(tokens)          # type, width
            code, name = next(tokens), next(tokens)
            full = ".".join(scope + [name])
            if full in wanted:
                ids.setdefault(code, []).append(full)
        elif tok.startswith("#"):
            t = int(tok[1:])
        elif tok[0] in "01xz" and tok[1:] in ids:
            for n in ids[tok[1:]]:
                changes.setdefault(n, []).append((t, tok[0]))
        elif tok[0] == "b":
            code = next(tokens)
            if code in ids:
                for n in ids[code]:
                    changes.setdefault(n, []).append((t, tok[1:]))
    return changes


def value_at(chg, t):
    v = "x"
    for tt, val in chg:
        if tt > t:
            break
        v = val
    return v


def main(vcd, png, period=10000, start_cycle=2, n_cycles=22):
    wanted = {s[1] for s in SIGNALS}
    ch = parse_vcd(vcd, wanted)
    t0 = start_cycle * period + 1000
    t1 = t0 + n_cycles * period
    fig, ax = plt.subplots(figsize=(15, 0.62 * len(SIGNALS) + 1.2))
    for row, (label, name, kind) in enumerate(SIGNALS):
        y = len(SIGNALS) - 1 - row
        chg = ch.get(name, [])
        pts = sorted({t0, t1} | {t for t, _ in chg if t0 < t < t1})
        color = "#1f5fa8" if label.startswith("H") else "#b5531c" if label.startswith("VN") else "#333"
        for a, b in zip(pts[:-1], pts[1:]):
            v = value_at(chg, a)
            xa, xb = (a - t0) / period, (b - t0) / period
            if kind == "bit":
                lvl = y + (0.7 if v == "1" else 0.1)
                ax.plot([xa, xb], [lvl, lvl], color=color, lw=1.6)
                if b != t1:
                    nv = value_at(chg, b)
                    ax.plot([xb, xb], [y + 0.1, y + 0.7], color=color, lw=1.2) if nv != v else None
            else:
                ax.fill_between([xa + 0.03, xb - 0.03], y + 0.1, y + 0.7, color=color, alpha=0.12)
                ax.plot([xa + 0.03, xb - 0.03], [y + 0.1, y + 0.1], color=color, lw=1)
                ax.plot([xa + 0.03, xb - 0.03], [y + 0.7, y + 0.7], color=color, lw=1)
                try:
                    txt = f"{int(v, 2):X}"
                except ValueError:
                    txt = v
                if xb - xa >= 0.6:
                    ax.text((xa + xb) / 2, y + 0.4, txt, ha="center", va="center", fontsize=7.5)
        ax.text(-0.3, y + 0.4, label, ha="right", va="center", fontsize=9, color=color)
    for c in range(n_cycles + 1):
        ax.axvline(c, color="#ddd", lw=0.6, zorder=0)
    ax.set_xlim(0, n_cycles)
    ax.set_ylim(-0.2, len(SIGNALS))
    ax.set_yticks([])
    ax.set_xticks(range(0, n_cycles + 1, 2))
    ax.set_xlabel("clock cycle after reset (sum_array program)")
    ax.set_title("Harvard (blue): fetch and load share a cycle.   "
                 "Von Neumann (orange): each LW adds a DATA cycle and stalls the PC.", fontsize=10)
    for s in ("top", "right", "left"):
        ax.spines[s].set_visible(False)
    fig.tight_layout()
    fig.savefig(png, dpi=150)
    print(f"wrote {png}")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)
    main(sys.argv[1], sys.argv[2])

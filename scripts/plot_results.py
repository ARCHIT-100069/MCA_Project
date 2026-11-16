#!/usr/bin/env python3
"""
plot_results.py -- charts and a markdown table from build/results.csv
Owner : Kumar Sanu

    python3 scripts/plot_results.py build/results.csv docs/evidence

Writes:
    cycles_comparison.png   cycles per program, Harvard vs Von Neumann
    cpi_vs_memfraction.png  measured CPI against the share of loads/stores,
                            with the analytical line CPI = 1 + f_mem
    results_table.md        the numbers used in the report
Needs matplotlib.
"""
import csv
import sys
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

BLUE, ORANGE = "#1f5fa8", "#c0632a"


def load(path):
    rows = []
    with open(path) as fh:
        for r in csv.DictReader(fh):
            for k in ("instructions", "loads", "stores", "harvard_cycles",
                      "vonneumann_cycles", "overlap_cycles"):
                r[k] = int(r[k])
            n = r["instructions"]
            r["fmem"] = (r["loads"] + r["stores"]) / n
            r["cpi_h"] = r["harvard_cycles"] / n
            r["cpi_v"] = r["vonneumann_cycles"] / n
            r["speedup"] = r["vonneumann_cycles"] / r["harvard_cycles"]
            rows.append(r)
    return sorted(rows, key=lambda r: r["fmem"])


def cycles_chart(rows, out):
    names = [r["program"] for r in rows]
    x = range(len(rows))
    w = 0.38
    fig, ax = plt.subplots(figsize=(8, 4.2))
    ax.bar([i - w / 2 for i in x], [r["harvard_cycles"] for r in rows], w, label="Harvard", color=BLUE)
    ax.bar([i + w / 2 for i in x], [r["vonneumann_cycles"] for r in rows], w, label="Von Neumann", color=ORANGE)
    for i, r in zip(x, rows):
        ax.text(i + w / 2, r["vonneumann_cycles"] + 5, f"x{r['speedup']:.2f}", ha="center", fontsize=8)
    ax.set_xticks(list(x))
    ax.set_xticklabels(names, rotation=15)
    ax.set_ylabel("clock cycles to finish")
    ax.set_title("Execution time of the same programs on both memory organizations")
    ax.legend(frameon=False)
    ax.spines[["top", "right"]].set_visible(False)
    fig.tight_layout()
    fig.savefig(out / "cycles_comparison.png", dpi=150)


def cpi_chart(rows, out):
    fig, ax = plt.subplots(figsize=(7, 4.2))
    xs = [0, 0.65]
    ax.plot(xs, [1 + x for x in xs], "--", color=ORANGE, lw=1, label="model: CPI = 1 + f_mem")
    ax.plot(xs, [1, 1], "--", color=BLUE, lw=1, label="model: CPI = 1")
    ax.scatter([r["fmem"] for r in rows], [r["cpi_v"] for r in rows], color=ORANGE, zorder=3, label="Von Neumann (measured)")
    ax.scatter([r["fmem"] for r in rows], [r["cpi_h"] for r in rows], color=BLUE, zorder=3, label="Harvard (measured)")
    for i, r in enumerate(rows):
        dy = 8 if i % 2 == 0 else -14            # alternate so close points stay readable
        ax.annotate(r["program"], (r["fmem"], r["cpi_v"]), textcoords="offset points",
                    xytext=(6, dy), fontsize=7.5)
    ax.set_xlabel("f_mem = (loads + stores) / instructions")
    ax.set_ylabel("cycles per instruction")
    ax.set_xlim(-0.02, 0.65)
    ax.set_ylim(0.9, 1.7)
    ax.legend(frameon=False, fontsize=8, loc="upper left")
    ax.spines[["top", "right"]].set_visible(False)
    ax.set_title("CPI grows with memory traffic only when the port is shared")
    fig.tight_layout()
    fig.savefig(out / "cpi_vs_memfraction.png", dpi=150)


def table(rows, out):
    lines = ["| Program | Instr. | Loads | Stores | f_mem | Harvard cycles | Harvard CPI | "
             "VN cycles | VN CPI | Speed-up | Same-cycle fetch+data |",
             "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|"]
    for r in rows:
        lines.append(f"| {r['program']} | {r['instructions']} | {r['loads']} | {r['stores']} | "
                     f"{r['fmem']:.3f} | {r['harvard_cycles']} | {r['cpi_h']:.3f} | "
                     f"{r['vonneumann_cycles']} | {r['cpi_v']:.3f} | {r['speedup']:.3f} | "
                     f"{r['overlap_cycles']} |")
    (out / "results_table.md").write_text("\n".join(lines) + "\n")


def main(csv_path, outdir):
    out = Path(outdir)
    out.mkdir(parents=True, exist_ok=True)
    rows = load(csv_path)
    cycles_chart(rows, out)
    cpi_chart(rows, out)
    table(rows, out)
    print((out / "results_table.md").read_text())


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)
    main(sys.argv[1], sys.argv[2])

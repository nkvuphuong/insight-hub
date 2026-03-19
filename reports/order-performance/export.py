"""
Order Performance — Static PNG Export
Design: openspec/changes/order-performance/design.md  |  Scope: Jan–Feb 2026, US
Run: python3 export.py  (from order-performance/ directory)
Output: exports/
"""

import os
import sys
from datetime import datetime
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
from matplotlib.patches import Patch
from matplotlib.gridspec import GridSpec

OUT_DIR = "exports"
os.makedirs(OUT_DIR, exist_ok=True)

SCOPE      = "Jan–Feb 2026 · US"
C_PROD     = "#2ca02c"
C_LAG      = "#d62728"
C_P50      = "#1f77b4"
C_P90      = "#ff7f0e"
C_NEUTRAL  = "#4a90d9"

SLA_TARGET = 2  # TikTok Shop SLA, business days
pct_fmt = mticker.FuncFormatter(lambda v, _: f"{v:.0f}%")

# ---------------------------------------------------------------------------
# Load data  (CSV = MCP cache — reuse until data refresh needed)
# ---------------------------------------------------------------------------
_CSV_MAP = {
    "queries/kpi.csv":      "kpi.sql      → queries/kpi.csv",
    "queries/segment.csv":  "segment.sql  → queries/segment.csv",
    "queries/cdf.csv":      "cdf.sql      → queries/cdf.csv",
    "queries/sla.csv":      "sla.sql      → queries/sla.csv",
}
_missing = [f for f in _CSV_MAP if not os.path.exists(f)]
if _missing:
    print("ERROR: Missing data cache. Run MCP queries first:\n")
    for f in _missing:
        print(f"  {_CSV_MAP[f]}")
    print("\nRun each SQL via MCP (run_select_query) and save result as the CSV above.")
    sys.exit(1)

# Show cache freshness for debugging / audit
print("Data cache:")
for f in _CSV_MAP:
    mtime = datetime.fromtimestamp(os.path.getmtime(f))
    print(f"  {f}  (fetched {mtime.strftime('%Y-%m-%d %H:%M')})")

kpi = pd.read_csv("queries/kpi.csv").iloc[0]
seg = pd.read_csv("queries/segment.csv")
seg_clean = seg[seg["facility"] != "Unknown"].copy()
cdf = pd.read_csv("queries/cdf.csv").iloc[0]
sla = pd.read_csv("queries/sla.csv")
sla_clean = sla[sla["facility"] != "Unknown"].copy().sort_values("tiktok_sla_pct")

n_orders = int(kpi["orders"])
print(f"KPI: {n_orders:,} orders | Segment: {len(seg)} rows | SLA: {len(sla)} rows")


def save(fig, name):
    path = os.path.join(OUT_DIR, name)
    fig.savefig(path, dpi=150, bbox_inches="tight")
    plt.close(fig)
    print(f"  Saved: {path}")


# ---------------------------------------------------------------------------
# Chart 1 — KPI Summary card
# ---------------------------------------------------------------------------
fig, ax = plt.subplots(figsize=(10, 5))
ax.axis("off")

fig.patch.set_facecolor("#f8f9fa")
ax.set_facecolor("#f8f9fa")

# Title
ax.text(0.5, 0.97, "Tracking Active Lead — KPI Summary",
        ha="center", va="top", fontsize=15, fontweight="bold",
        transform=ax.transAxes)
ax.text(0.5, 0.86, f"{SCOPE}  ·  n = {n_orders:,} orders",
        ha="center", va="top", fontsize=11, color="#555",
        transform=ax.transAxes)
# Metric definition line
ax.text(0.5, 0.76,
        "Tracking Active Lead  =  Production Time (payment → fulfilled)  +  Tracking Lag (fulfilled → 1st carrier scan)",
        ha="center", va="top", fontsize=9, color="#888", style="italic",
        transform=ax.transAxes)

# Main KPI numbers
metrics = [
    ("P50  —  median\n(half of orders complete faster)",   f"{kpi['p50_active_lead_d']:.2f} days", C_P50),
    ("P90  —  90th percentile\n(9 in 10 orders complete faster)", f"{kpi['p90_active_lead_d']:.2f} days", C_P90),
    ("Avg  —  arithmetic mean",                            f"{kpi['avg_active_lead_d']:.2f} days", "#7f7f7f"),
]
for i, (label, value, color) in enumerate(metrics):
    x = 0.18 + i * 0.32
    ax.text(x, 0.57, value, ha="center", va="center", fontsize=22,
            fontweight="bold", color=color, transform=ax.transAxes)
    ax.text(x, 0.34, label, ha="center", va="center", fontsize=9,
            color="#555", transform=ax.transAxes)

# Breakdown footnote
ax.text(0.5, 0.10,
        f"Breakdown (avg):  Production {kpi['avg_prod_d']:.2f}d (biz days)  +  Tracking Lag {kpi['avg_lag_d']:.2f}d (biz days)  =  {kpi['avg_active_lead_d']:.2f}d (biz days)",
        ha="center", va="bottom", fontsize=10, color="#444",
        transform=ax.transAxes)

plt.tight_layout()
save(fig, "01_kpi_summary.png")


# ---------------------------------------------------------------------------
# Chart 2 — Breakdown: Production vs Tracking Lag (stacked horizontal bar)
# ---------------------------------------------------------------------------
total_avg = kpi["avg_prod_d"] + kpi["avg_lag_d"]
pct_prod  = kpi["avg_prod_d"] / total_avg * 100
pct_lag   = kpi["avg_lag_d"]  / total_avg * 100

fig, ax = plt.subplots(figsize=(10, 3))
ax.barh(["Tracking Active Lead"], [kpi["avg_prod_d"]], color=C_PROD,
        label=f"Production Time  {kpi['avg_prod_d']:.2f}d ({pct_prod:.0f}%)  —  payment → fulfilled (business days)")
ax.barh(["Tracking Active Lead"], [kpi["avg_lag_d"]],  left=[kpi["avg_prod_d"]], color=C_LAG,
        label=f"Tracking Lag  {kpi['avg_lag_d']:.2f}d ({pct_lag:.0f}%)  —  fulfilled → 1st carrier scan (business days)")

# Labels inside bars
ax.text(kpi["avg_prod_d"] / 2, 0,
        f"{kpi['avg_prod_d']:.2f}d\n({pct_prod:.0f}%)", ha="center", va="center",
        fontsize=12, fontweight="bold", color="white")
ax.text(kpi["avg_prod_d"] + kpi["avg_lag_d"] / 2, 0,
        f"{kpi['avg_lag_d']:.2f}d\n({pct_lag:.0f}%)", ha="center", va="center",
        fontsize=12, fontweight="bold", color="white")

ax.set_title(f"Lead Time Breakdown — Production vs Carrier  ({SCOPE})", fontsize=13, fontweight="bold")
ax.set_xlabel("Days (avg)")
ax.legend(loc="lower right", fontsize=9)
ax.set_xlim(0, total_avg * 1.05)
ax.grid(axis="x", linestyle="--", alpha=0.4)
plt.tight_layout()
save(fig, "02_lead_breakdown.png")


# ---------------------------------------------------------------------------
# Chart 3/4/4b — Distribution curves
# ---------------------------------------------------------------------------
def plot_cdf(points, title, definition, xlabel, color, outfile):
    x_vals = [p[0] for p in points]
    y_vals = [float(cdf[col]) for _, col in points]
    fig, ax = plt.subplots(figsize=(10, 5))
    ax.plot(x_vals, y_vals, marker="o", markersize=7, color=color, linewidth=2.5)
    for x, y in zip(x_vals, y_vals):
        ax.annotate(f"{y:.1f}%", (x, y), textcoords="offset points",
                    xytext=(0, 10), ha="center", fontsize=9)
    ax.set_title(f"{title}\n{SCOPE}  ·  n = {n_orders:,}", fontsize=13, fontweight="bold")
    # Definition subtitle (italic, small)
    ax.text(0.5, -0.14, definition, transform=ax.transAxes,
            ha="center", va="top", fontsize=9, color="#666", style="italic")
    ax.set_xlabel(xlabel)
    ax.set_ylabel("% Orders (cumulative)\nHow to read: a point at (X, Y%) means Y% of orders finished within X biz days")
    ax.yaxis.set_major_formatter(pct_fmt)
    ax.set_xticks(x_vals)
    ax.set_ylim(0, 110)
    ax.grid(linestyle="--", alpha=0.4)
    plt.tight_layout(rect=[0, 0.06, 1, 1])
    save(fig, outfile)


plot_cdf(
    [(0.5,"prod_le_0d5"),(1,"prod_le_1d"),(2,"prod_le_2d"),(3,"prod_le_3d"),(5,"prod_le_5d"),(7,"prod_le_7d")],
    "Production Time Distribution — % Orders Fulfilled Within X Days",
    "Production Time = days from payment to order fulfillment  (business days, warehouse processing)",
    "Business days from payment to fulfillment", C_PROD, "03_production_cdf.png"
)
plot_cdf(
    [(0.25,"lag_le_0d25"),(0.5,"lag_le_0d5"),(1,"lag_le_1d"),(2,"lag_le_2d"),(3,"lag_le_3d")],
    "Tracking Lag Distribution — % Orders First-Scanned Within X Business Days",
    "Tracking Lag = days from fulfillment to 1st carrier scan  (business days, carrier pickup delay)",
    "Business days from fulfillment to 1st carrier scan", C_LAG, "04_tracking_lag_cdf.png"
)
plot_cdf(
    [(1,"lead_le_1d"),(2,"lead_le_2d"),(3,"lead_le_3d"),(5,"lead_le_5d"),(7,"lead_le_7d")],
    "Tracking Active Lead — % Orders Completed Within X Days",
    "Tracking Active Lead = Production Time + Tracking Lag  (payment → fulfillment → 1st carrier scan, business days)",
    "Business days from payment to 1st carrier scan", C_P50, "04b_active_lead_cdf.png"
)


# ---------------------------------------------------------------------------
# Chart 5 — P50 Production Time by Facility × Shipping Class
# ---------------------------------------------------------------------------
classes   = seg["shipping_class"].unique()
facilities = seg["facility"].unique()
n_cls    = len(classes)
bar_w    = 0.7 / n_cls
x_fac    = range(len(facilities))
colors   = plt.cm.tab10.colors

fig, ax = plt.subplots(figsize=(10, 5))
for i, cls in enumerate(classes):
    sub = seg[seg["shipping_class"] == cls]
    vals = []
    for fac in facilities:
        match = sub[sub["facility"] == fac]
        vals.append(match["p50_prod_d"].values[0] if len(match) else 0)
    offset = (i - n_cls / 2 + 0.5) * bar_w
    bars = ax.bar([xi + offset for xi in x_fac], vals, width=bar_w,
                  label=cls, color=colors[i], alpha=0.85)
    for bar, val in zip(bars, vals):
        if val > 0:
            ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + 0.03,
                    f"{val:.2f}", ha="center", va="bottom", fontsize=9)

ax.set_title(f"P50 Production Time — Facility × Shipping Class  ({SCOPE})\n"
             f"P50 = median business days from payment to fulfillment",
             fontsize=13, fontweight="bold")
ax.set_xticks(list(x_fac))
ax.set_xticklabels(facilities)
ax.set_ylabel("Days (P50 = median)")
ax.legend(title="Shipping Class")
ax.grid(axis="y", linestyle="--", alpha=0.4)
plt.tight_layout()
save(fig, "05_production_by_segment.png")


# ---------------------------------------------------------------------------
# Chart 6 — Same-day Scan Rate by Facility × Shipping Class
# ---------------------------------------------------------------------------
seg["label"] = seg["facility"] + "\n" + seg["shipping_class"]
norm   = plt.Normalize(seg["pct_scan_within_1d"].min(), seg["pct_scan_within_1d"].max())
colors_bar = plt.cm.RdYlGn(norm(seg["pct_scan_within_1d"]))

fig, ax = plt.subplots(figsize=(10, 5))
bars = ax.bar(seg["label"], seg["pct_scan_within_1d"], color=colors_bar, alpha=0.9)
for bar, val, n in zip(bars, seg["pct_scan_within_1d"], seg["orders"]):
    ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + 1,
            f"{val:.1f}%\n(n={n:,})", ha="center", va="bottom", fontsize=9)

ax.set_title(f"Same-day Scan Rate — by Facility × Shipping Class  ({SCOPE})\n"
             f"% orders first-scanned by carrier within 1 business day of fulfillment",
             fontsize=13, fontweight="bold")
ax.set_ylabel("% Orders  (higher = carrier scans faster after pickup)")
ax.yaxis.set_major_formatter(pct_fmt)
ax.set_ylim(0, 130)
ax.grid(axis="y", linestyle="--", alpha=0.4)
plt.tight_layout()
save(fig, "06_scan_rate_by_segment.png")


# ---------------------------------------------------------------------------
# Chart 7 — TikTok Shop SLA Compliance by Facility × Shipping Class
# ---------------------------------------------------------------------------
sla_clean["label"] = sla_clean["facility"] + "\n" + sla_clean["shipping_class"]

TIKTOK_SLA = 2  # BD
C_SLA_BAD  = "#d62728"
C_SLA_MID  = "#ff7f0e"
C_SLA_GOOD = "#2ca02c"

def sla_color(pct):
    if pct < 30:   return C_SLA_BAD
    if pct < 60:   return C_SLA_MID
    return C_SLA_GOOD

bar_colors = [sla_color(v) for v in sla_clean["tiktok_sla_pct"]]

fig, ax = plt.subplots(figsize=(12, 5))
bars = ax.bar(sla_clean["label"], sla_clean["tiktok_sla_pct"],
              color=bar_colors, alpha=0.9)
for bar, row in zip(bars, sla_clean.itertuples()):
    ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + 1.5,
            f"{row.tiktok_sla_pct:.1f}%\n(n={row.total_orders:,})",
            ha="center", va="bottom", fontsize=9)

ax.axhline(100, color="#aaa", linewidth=1, linestyle="--", label="100% target")
ax.set_title(f"TikTok Shop SLA Compliance — by Facility × Shipping Class  ({SCOPE})\n"
             f"% orders with Tracking Active Lead ≤ {TIKTOK_SLA} BD (TikTok Shop SLA requirement)",
             fontsize=13, fontweight="bold")
ax.set_ylabel("% Orders within TikTok SLA")
ax.yaxis.set_major_formatter(pct_fmt)
ax.set_ylim(0, 130)
ax.legend(fontsize=9)
ax.grid(axis="y", linestyle="--", alpha=0.4)

legend_elements = [
    Patch(facecolor=C_SLA_BAD,  label="< 30%  — Critical"),
    Patch(facecolor=C_SLA_MID,  label="30–60% — At risk"),
    Patch(facecolor=C_SLA_GOOD, label="> 60%  — Acceptable"),
]
ax.legend(handles=legend_elements, fontsize=9, loc="upper left")
plt.tight_layout()
save(fig, "07_tiktok_sla_compliance.png")


# ---------------------------------------------------------------------------
# Chart 8 — Stacked P50 Production + Tracking Lag vs SLA target (Metric 2)
# ---------------------------------------------------------------------------
fig, ax = plt.subplots(figsize=(12, 5))
x_pos = range(len(sla_clean))

ax.bar(x_pos, sla_clean["p50_production"], color=C_PROD,
       label="Production Time (paid→fulfilled, biz days)")
ax.bar(x_pos, sla_clean["p50_tracking_lag"], bottom=sla_clean["p50_production"],
       color=C_LAG, label="Tracking Lag (fulfilled→1st scan, biz days)")
ax.axhline(SLA_TARGET, color="#1f77b4", linewidth=2.5, linestyle="--",
           label=f"TikTok SLA = {SLA_TARGET} BD")

for i, row in enumerate(sla_clean.itertuples()):
    if row.p50_production >= 0.3:
        ax.text(i, row.p50_production / 2, f"{row.p50_production:.2f}d",
                ha="center", va="center", fontsize=9, fontweight="bold", color="white")
    if row.p50_tracking_lag >= 0.3:
        ax.text(i, row.p50_production + row.p50_tracking_lag / 2,
                f"{row.p50_tracking_lag:.2f}d",
                ha="center", va="center", fontsize=9, fontweight="bold", color="white")

ax.set_title(f"P50 Production + Tracking Lag vs TikTok SLA  ({SCOPE})\n"
             f"Bars above dashed line = SLA miss. Red = Tracking Lag, Green = Production Time.",
             fontsize=13, fontweight="bold")
ax.set_xticks(list(x_pos))
ax.set_xticklabels(sla_clean["label"])
ax.set_ylabel("Business days (P50 = median)")
ax.legend(fontsize=9)
ax.grid(axis="y", linestyle="--", alpha=0.4)
plt.tight_layout()
save(fig, "08_stacked_vs_sla.png")


# ---------------------------------------------------------------------------
# Dashboard — 2-metric executive view: Metric 1 (SLA%) + Metric 2 (Stacked)
# ---------------------------------------------------------------------------
fig = plt.figure(figsize=(14, 11))
fig.suptitle(f"Order Performance — SLA Analysis  ·  {SCOPE}  ·  n = {n_orders:,} orders",
             fontsize=15, fontweight="bold", y=0.99)

gs = GridSpec(3, 1, figure=fig, hspace=0.55, height_ratios=[1, 1, 0.18])

# --- Metric 1: SLA Compliance Rate ---
ax_m1 = fig.add_subplot(gs[0])
bar_colors_db = [sla_color(v) for v in sla_clean["tiktok_sla_pct"]]
bars_m1 = ax_m1.bar(sla_clean["label"], sla_clean["tiktok_sla_pct"],
                    color=bar_colors_db, alpha=0.9)
for bar, row in zip(bars_m1, sla_clean.itertuples()):
    ax_m1.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + 1.5,
               f"{row.tiktok_sla_pct:.1f}%\n(n={row.total_orders:,})",
               ha="center", va="bottom", fontsize=9)
ax_m1.set_title("Metric 1 — SLA Compliance Rate  (% orders with Tracking Active Lead ≤ 2 BD, TikTok Shop SLA)",
                fontsize=12, fontweight="bold")
ax_m1.set_ylabel("% Orders within TikTok SLA")
ax_m1.yaxis.set_major_formatter(pct_fmt)
ax_m1.set_ylim(0, 130)
legend_m1 = [
    Patch(facecolor=C_SLA_BAD,  label="< 30%  — Critical"),
    Patch(facecolor=C_SLA_MID,  label="30–60% — At risk"),
    Patch(facecolor=C_SLA_GOOD, label="> 60%  — Acceptable"),
]
ax_m1.legend(handles=legend_m1, fontsize=9, loc="upper left")
ax_m1.grid(axis="y", linestyle="--", alpha=0.4)

# --- Metric 2: Stacked Production + Tracking Lag vs SLA ---
ax_m2 = fig.add_subplot(gs[1])
x_db = range(len(sla_clean))
ax_m2.bar(x_db, sla_clean["p50_production"], color=C_PROD,
          label="Production Time (paid→fulfilled, biz days)")
ax_m2.bar(x_db, sla_clean["p50_tracking_lag"], bottom=sla_clean["p50_production"],
          color=C_LAG, label="Tracking Lag (fulfilled→1st scan, biz days)")
ax_m2.axhline(SLA_TARGET, color="#1f77b4", linewidth=2.5, linestyle="--",
              label=f"TikTok SLA = {SLA_TARGET} BD")
for i, row in enumerate(sla_clean.itertuples()):
    if row.p50_production >= 0.3:
        ax_m2.text(i, row.p50_production / 2, f"{row.p50_production:.2f}d",
                   ha="center", va="center", fontsize=9, fontweight="bold", color="white")
    if row.p50_tracking_lag >= 0.3:
        ax_m2.text(i, row.p50_production + row.p50_tracking_lag / 2,
                   f"{row.p50_tracking_lag:.2f}d",
                   ha="center", va="center", fontsize=9, fontweight="bold", color="white")
ax_m2.set_title("Metric 2 — Production + Tracking Lag vs SLA Budget  (P50, business days)\n"
                "Bars above dashed line = SLA miss. Red segment = Tracking Lag; Green = Production Time.",
                fontsize=12, fontweight="bold")
ax_m2.set_xticks(list(x_db))
ax_m2.set_xticklabels(sla_clean["label"])
ax_m2.set_ylabel("Business days (P50 = median)")
ax_m2.legend(fontsize=9)
ax_m2.grid(axis="y", linestyle="--", alpha=0.4)

# --- Key Finding ---
ax_note = fig.add_subplot(gs[2])
ax_note.axis("off")
finding_text = (
    "KEY FINDING:  TikTok SLA (≤2 BD): overall 37.1%.  "
    "HB1 Standard (50% volume): 19.4% — Tracking Lag 1.88d, budget 0.67d.  "
    "TX1 Standard: 56.4% — Tracking Lag 0.96d (on target).  "
    "▶  ACTION: Vận hành & PT + Leadership — giảm carrier pickup lag tại HB1/HB2."
)
ax_note.text(0.5, 0.5, finding_text,
             transform=ax_note.transAxes,
             ha="center", va="center", fontsize=10, color="#5d4037", style="italic",
             bbox=dict(boxstyle="round,pad=0.4", facecolor="#fff8e1", edgecolor="#f9a825", linewidth=1.5))

save(fig, "00_dashboard.png")

print("\nDone. All charts saved to exports/")

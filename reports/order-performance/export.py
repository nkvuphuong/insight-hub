"""
Order Performance — Static PNG Export
Spec: spec.md v0.6  |  Scope: Jan–Feb 2026, US
Run: python3 export.py  (from order-performance/ directory)
Output: exports/
"""

import os
import sys
from datetime import datetime
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
from matplotlib.gridspec import GridSpec

OUT_DIR = "exports"
os.makedirs(OUT_DIR, exist_ok=True)

SCOPE      = "Jan–Feb 2026 · US"
C_PROD     = "#2ca02c"
C_LAG      = "#d62728"
C_P50      = "#1f77b4"
C_P90      = "#ff7f0e"
C_NEUTRAL  = "#4a90d9"

pct_fmt = mticker.FuncFormatter(lambda v, _: f"{v:.0f}%")

# ---------------------------------------------------------------------------
# Load data  (CSV = MCP cache — reuse until data refresh needed)
# ---------------------------------------------------------------------------
_CSV_MAP = {
    "queries/kpi.csv":      "kpi.sql      → queries/kpi.csv",
    "queries/segment.csv":  "segment.sql  → queries/segment.csv",
    "queries/cdf.csv":      "cdf.sql      → queries/cdf.csv",
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

n_orders = int(kpi["orders"])
print(f"KPI: {n_orders:,} orders | Segment: {len(seg)} rows")


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
# Dashboard — composite: Row1=2col, Row2=3col, Row3=2col, Row4=note
# ---------------------------------------------------------------------------
seg_clean["label"] = seg_clean["facility"] + "\n" + seg_clean["shipping_class"]
norm_clean   = plt.Normalize(seg_clean["pct_scan_within_1d"].min(), seg_clean["pct_scan_within_1d"].max())
classes_c    = seg_clean["shipping_class"].unique()
facilities_c = seg_clean["facility"].unique()
n_cls_c      = len(classes_c)
bar_w_c      = 0.7 / n_cls_c
x_fac_c      = range(len(facilities_c))

fig = plt.figure(figsize=(22, 18))
fig.suptitle(f"Order Performance Dashboard  ·  {SCOPE}  ·  n = {n_orders:,} orders",
             fontsize=16, fontweight="bold", y=0.99)

gs = GridSpec(4, 6, figure=fig, hspace=0.5, wspace=0.4,
              height_ratios=[1.2, 1.2, 1.2, 0.35])

# --- Row 1: KPI card (left) + Breakdown bar (right) ---
ax1 = fig.add_subplot(gs[0, :3])
ax1.axis("off")
ax1.set_facecolor("#f0f4f8")
for spine in ax1.spines.values(): spine.set_visible(False)
kpi_items = [
    ("P50 Active Lead",    f"{kpi['p50_active_lead_d']:.2f} days", C_P50,  "median: payment → 1st carrier scan"),
    ("P90 Active Lead",    f"{kpi['p90_active_lead_d']:.2f} days", C_P90,  "9 in 10 orders complete faster"),
    ("Avg Active Lead",    f"{kpi['avg_active_lead_d']:.2f} days", "#555", "= Production + Tracking Lag (avg)"),
    ("Same-day Scan Rate", f"{kpi['pct_scan_within_1d']:.1f}%",    C_PROD, "% orders scanned ≤1 biz day after fulfillment"),
]
for i, (label, val, color, defn) in enumerate(kpi_items):
    y = 0.84 - i * 0.21
    ax1.text(0.06, y + 0.05, label, transform=ax1.transAxes, fontsize=10,
             color="#333", va="center", fontweight="bold")
    ax1.text(0.06, y - 0.04, defn,  transform=ax1.transAxes, fontsize=8,
             color="#999", va="center", style="italic")
    ax1.text(0.96, y, val,          transform=ax1.transAxes, fontsize=13, color=color,
             fontweight="bold", va="center", ha="right")
ax1.set_title("KPI Summary  —  Tracking Active Lead = Production + Tracking Lag",
              fontsize=11, fontweight="bold")

ax2 = fig.add_subplot(gs[0, 3:])
ax2.barh([""], [kpi["avg_prod_d"]], color=C_PROD,
         label=f"Production (payment→fulfilled)  {kpi['avg_prod_d']:.2f}d ({pct_prod:.0f}%)")
ax2.barh([""], [kpi["avg_lag_d"]], left=[kpi["avg_prod_d"]], color=C_LAG,
         label=f"Tracking Lag (fulfilled→1st scan, biz days)  {kpi['avg_lag_d']:.2f}d ({pct_lag:.0f}%)")
ax2.text(kpi["avg_prod_d"]/2, 0, f"{kpi['avg_prod_d']:.2f}d\n({pct_prod:.0f}%)", ha="center", va="center", fontsize=11, fontweight="bold", color="white")
ax2.text(kpi["avg_prod_d"]+kpi["avg_lag_d"]/2, 0, f"{kpi['avg_lag_d']:.2f}d\n({pct_lag:.0f}%)", ha="center", va="center", fontsize=11, fontweight="bold", color="white")
ax2.set_title("Lead Time Breakdown  (avg, business days)", fontsize=12, fontweight="bold")
ax2.set_xlabel("Days (avg)")
ax2.legend(fontsize=8)
ax2.grid(axis="x", linestyle="--", alpha=0.4)

# --- Row 2: Production Distribution + Tracking Lag Distribution + Active Lead Distribution ---
ax3 = fig.add_subplot(gs[1, :2])
prod_pts = [(0.5,"prod_le_0d5"),(1,"prod_le_1d"),(2,"prod_le_2d"),(3,"prod_le_3d"),(5,"prod_le_5d"),(7,"prod_le_7d")]
x3 = [p[0] for p in prod_pts]; y3 = [float(cdf[c]) for _,c in prod_pts]
ax3.plot(x3, y3, marker="o", markersize=6, color=C_PROD, linewidth=2)
for x, y in zip(x3, y3): ax3.annotate(f"{y:.0f}%", (x,y), xytext=(0,8), textcoords="offset points", ha="center", fontsize=8)
ax3.set_title("Production Time Distribution\n(payment → fulfilled, business days)", fontsize=11, fontweight="bold")
ax3.set_xlabel("Days"); ax3.set_ylabel("% Orders (cumulative)")
ax3.yaxis.set_major_formatter(pct_fmt); ax3.set_xticks(x3); ax3.set_ylim(0,110); ax3.grid(linestyle="--",alpha=0.4)

ax4 = fig.add_subplot(gs[1, 2:4])
lag_pts = [(0.25,"lag_le_0d25"),(0.5,"lag_le_0d5"),(1,"lag_le_1d"),(2,"lag_le_2d"),(3,"lag_le_3d")]
x4 = [p[0] for p in lag_pts]; y4 = [float(cdf[c]) for _,c in lag_pts]
ax4.plot(x4, y4, marker="o", markersize=6, color=C_LAG, linewidth=2)
for x, y in zip(x4, y4): ax4.annotate(f"{y:.0f}%", (x,y), xytext=(0,8), textcoords="offset points", ha="center", fontsize=8)
ax4.set_title("Tracking Lag Distribution\n(fulfilled → 1st carrier scan, business days)", fontsize=11, fontweight="bold")
ax4.set_xlabel("Business days"); ax4.set_ylabel("% Orders (cumulative)")
ax4.yaxis.set_major_formatter(pct_fmt); ax4.set_xticks(x4); ax4.set_ylim(0,110); ax4.grid(linestyle="--",alpha=0.4)

ax4b = fig.add_subplot(gs[1, 4:])
lead_pts = [(1,"lead_le_1d"),(2,"lead_le_2d"),(3,"lead_le_3d"),(5,"lead_le_5d"),(7,"lead_le_7d")]
x4b = [p[0] for p in lead_pts]; y4b = [float(cdf[c]) for _,c in lead_pts]
ax4b.plot(x4b, y4b, marker="o", markersize=6, color=C_P50, linewidth=2)
for x, y in zip(x4b, y4b): ax4b.annotate(f"{y:.0f}%", (x,y), xytext=(0,8), textcoords="offset points", ha="center", fontsize=8)
ax4b.set_title("Active Lead Distribution\n(payment → 1st scan = Production + Lag, business days)", fontsize=11, fontweight="bold")
ax4b.set_xlabel("Business days"); ax4b.set_ylabel("% Orders (cumulative)")
ax4b.yaxis.set_major_formatter(pct_fmt); ax4b.set_xticks(x4b); ax4b.set_ylim(0,110); ax4b.grid(linestyle="--",alpha=0.4)

# --- Row 3: Segment Production + Segment Scan Rate (seg_clean, no Unknown) ---
ax5 = fig.add_subplot(gs[2, :3])
for i, cls in enumerate(classes_c):
    sub = seg_clean[seg_clean["shipping_class"] == cls]
    vals = [sub[sub["facility"]==fac]["p50_prod_d"].values[0] if len(sub[sub["facility"]==fac]) else 0 for fac in facilities_c]
    offset = (i - n_cls_c/2 + 0.5) * bar_w_c
    bars5 = ax5.bar([xi+offset for xi in x_fac_c], vals, width=bar_w_c, label=cls, color=colors[i], alpha=0.85)
    for bar, val in zip(bars5, vals):
        if val > 0: ax5.text(bar.get_x()+bar.get_width()/2, bar.get_height()+0.02, f"{val:.2f}", ha="center", va="bottom", fontsize=8)
ax5.set_title("P50 Production Time by Segment\n(median days, payment → fulfilled)", fontsize=11, fontweight="bold")
ax5.set_xticks(list(x_fac_c)); ax5.set_xticklabels(facilities_c)
ax5.set_ylabel("Days (P50 = median)"); ax5.legend(fontsize=8); ax5.grid(axis="y", linestyle="--", alpha=0.4)

ax6 = fig.add_subplot(gs[2, 3:])
bars6 = ax6.bar(seg_clean["label"], seg_clean["pct_scan_within_1d"],
                color=plt.cm.RdYlGn(norm_clean(seg_clean["pct_scan_within_1d"])), alpha=0.9)
for bar, val, n in zip(bars6, seg_clean["pct_scan_within_1d"], seg_clean["orders"]):
    ax6.text(bar.get_x()+bar.get_width()/2, bar.get_height()+1, f"{val:.1f}%\n(n={n:,})", ha="center", va="bottom", fontsize=8)
ax6.axhline(50, color="#333", linewidth=1, linestyle="--", alpha=0.5, label="Target: 50%")
ax6.legend(fontsize=8)
for bar, row in zip(bars6, seg_clean.itertuples()):
    if row.facility == "HB1" and row.shipping_class == "Standard":
        bar.set_edgecolor("#cc0000")
        bar.set_linewidth(2.5)
        ax6.annotate("⚠ Bottleneck\n44% of volume",
                     xy=(bar.get_x() + bar.get_width()/2, row.pct_scan_within_1d),
                     xytext=(0, 25), textcoords="offset points",
                     ha="center", fontsize=8, color="#cc0000",
                     arrowprops=dict(arrowstyle="->", color="#cc0000", lw=1.2))
ax6.set_title("Same-day Scan Rate by Segment\n(% orders 1st-scanned ≤1 biz day after fulfillment)", fontsize=11, fontweight="bold")
ax6.set_ylabel("% Orders"); ax6.yaxis.set_major_formatter(pct_fmt); ax6.set_ylim(0, 130)
ax6.grid(axis="y", linestyle="--", alpha=0.4)

# --- Row 4: Key Finding text panel ---
ax_note = fig.add_subplot(gs[3, :])
ax_note.axis("off")
ax_note.set_facecolor("#fff8e1")
finding_text = (
    "KEY FINDING:  HB1 Standard (44% of volume) — Same-day scan rate 27% vs TX1 Standard 62%  (+35pp gap).  "
    "Production time HB1 1.33d vs TX1 1.17d.  "
    "▶  NEXT STEP: Investigate HB1 carrier pickup schedule & production flow."
)
ax_note.text(0.5, 0.5, finding_text,
             transform=ax_note.transAxes,
             ha="center", va="center", fontsize=10,
             color="#5d4037", style="italic",
             bbox=dict(boxstyle="round,pad=0.4", facecolor="#fff8e1", edgecolor="#f9a825", linewidth=1.5))

save(fig, "00_dashboard.png")

print("\nDone. All charts saved to exports/")

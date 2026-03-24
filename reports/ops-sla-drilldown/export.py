"""
export.py — Ops SLA Drilldown
Export 4 charts as PNG. Requires CSV files in queries/.

Usage:
    python export.py

Required CSVs (run SQL via MCP and save results):
    queries/ops_contribution.csv
    queries/ops_product_breakdown.csv
    queries/ops_location_breakdown.csv
    queries/ops_facility_product.csv
"""
import sys
import os
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import numpy as np

EXPORT_DIR = 'exports'
os.makedirs(EXPORT_DIR, exist_ok=True)

SLA = {'Platform': 3, 'Standard': 4}
COLOR_PROD  = '#e67e22'
COLOR_SCAN  = '#3498db'
COLOR_OK    = '#2ecc71'   # >= 90%
COLOR_WARN  = '#e74c3c'   # < 90%
COLORS_GROUP = {'Platform': '#e67e22', 'Standard': '#3498db'}
FACILITIES  = ['CA', 'TX1']
PERIOD_LABEL = 'Tháng 2/2026 (tháng gần nhất)'
THRESHOLD_VISUAL = 90  # % — ngưỡng tham khảo cho color coding

# --- Load & validate CSVs ---
required = {
    'ops_contribution':      'queries/ops_contribution.csv',
    'ops_product_breakdown': 'queries/ops_product_breakdown.csv',
    'ops_location_breakdown':'queries/ops_location_breakdown.csv',
    'ops_facility_product':  'queries/ops_facility_product.csv',
}

missing = [path for path in required.values() if not os.path.exists(path)]
if missing:
    print('ERROR: Missing CSV files:')
    for f in missing:
        print(f'  {f}')
    print('\nRun these queries via MCP and save results to queries/*.csv')
    sys.exit(1)

df_contrib  = pd.read_csv(required['ops_contribution'])
df_product  = pd.read_csv(required['ops_product_breakdown'])
df_location = pd.read_csv(required['ops_location_breakdown'])
df_fac_prod = pd.read_csv(required['ops_facility_product'])

# Clean
df_location = df_location[df_location['ordx_fulfill_locate'] != 'Unknown']
df_fac_prod = df_fac_prod[
    (df_fac_prod['ordx_fulfill_locate'] != 'Unknown') &
    (df_fac_prod['avg_first_scan_day'] >= 0) &
    (df_fac_prod['order_count'] >= 100)
]
df_product = df_product[df_product['total_orders'] >= 100]
df_contrib = df_contrib[df_contrib['order_count'] >= 100]


# ── Chart 3: Xưởng nào đang chậm SLA? ───────────────────────────────────────
fig, ax = plt.subplots(figsize=(9, 5))

x = np.arange(len(FACILITIES))
width = 0.35

for i, group in enumerate(['Platform', 'Standard']):
    g = df_location[df_location['group'] == group].set_index('ordx_fulfill_locate').reindex(FACILITIES)
    offset = (i - 0.5) * width
    bars = ax.bar(x + offset, g['pass_rate'].fillna(0), width,
                  label=f"{group} (cam kết SLA ≤{SLA[group]} ngày)",
                  color=COLORS_GROUP[group], alpha=0.85)
    for bar, fac in zip(bars, FACILITIES):
        if fac in g.index and not pd.isna(g.loc[fac, 'pass_rate']):
            row = g.loc[fac]
            ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + 1.5,
                    f"{row['pass_rate']:.1f}%\n({int(row['total_orders']):,} đơn)",
                    ha='center', va='bottom', fontsize=9)
        elif bar.get_height() == 0:
            ax.text(bar.get_x() + bar.get_width() / 2, 2,
                    'không có đơn', ha='center', va='bottom', fontsize=7, color='gray')

# Reference line at 90%
ax.axhline(THRESHOLD_VISUAL, color='#e74c3c', linestyle=':', linewidth=1.5, alpha=0.6)
ax.text(len(FACILITIES) - 0.05, THRESHOLD_VISUAL + 1, f'Ngưỡng tham khảo {THRESHOLD_VISUAL}%',
        ha='right', fontsize=8, color='#e74c3c')

ax.set_xticks(x)
ax.set_xticklabels(['CA (California)', 'TX1 (Texas)'], fontsize=11)
ax.set_ylim(0, 120)
ax.yaxis.set_major_formatter(mticker.FuncFormatter(lambda v, _: f'{v:.0f}%'))
ax.set_ylabel('% đơn đạt SLA')
ax.set_title(f'Xưởng nào đang chậm SLA?\n{PERIOD_LABEL} | Platform ≤3 ngày, Standard ≤4 ngày',
             fontsize=13, fontweight='bold')
ax.text(x[1], 107, '✓ Tốt nhất — dùng làm chuẩn so sánh', ha='center', color='#27ae60', fontsize=9)
ax.legend(loc='upper left', fontsize=9)
ax.set_facecolor('#f8f9fa')
plt.tight_layout()
out = f'{EXPORT_DIR}/chart3_facility_triage.png'
fig.savefig(out, dpi=150)
print(f'Saved: {out}')
plt.close()


# ── Chart 4: Nguyên nhân tại từng xưởng? ─────────────────────────────────────
groups = ['Platform', 'Standard']
fig, axes = plt.subplots(2, 2, figsize=(12, 9), sharey=False)
fig.suptitle(
    'Nguyên nhân tại từng xưởng — sản xuất chậm hay carrier chậm?\n'
    f'{PERIOD_LABEL} | Đường đứt nét = ngưỡng SLA | Chỉ sản phẩm có đủ dữ liệu (≥100 đơn)',
    fontsize=12, fontweight='bold'
)

for row_idx, group in enumerate(groups):
    for col_idx, facility in enumerate(FACILITIES):
        ax = axes[row_idx][col_idx]
        sub = df_fac_prod[
            (df_fac_prod['group'] == group) &
            (df_fac_prod['ordx_fulfill_locate'] == facility)
        ]
        if sub.empty:
            ax.text(0.5, 0.5, 'Không đủ dữ liệu\n(< 100 đơn/sản phẩm)',
                    ha='center', va='center', transform=ax.transAxes,
                    fontsize=10, color='gray')
            ax.set_title(f'{group} — {facility}', fontsize=10)
            ax.set_facecolor('#f8f9fa')
            continue
        sub = sub.sort_values('avg_tal', ascending=False)
        xi = np.arange(len(sub))
        ax.bar(xi, sub['avg_processing_day'], color=COLOR_PROD, alpha=0.85)
        ax.bar(xi, sub['avg_first_scan_day'], bottom=sub['avg_processing_day'], color=COLOR_SCAN, alpha=0.85)
        ax.axhline(SLA[group], color='red', linestyle='--', linewidth=1.5, alpha=0.7,
                   label=f'SLA ≤{SLA[group]} ngày')
        ax.set_xticks(xi)
        ax.set_xticklabels(sub['product_type'], rotation=30, ha='right', fontsize=9)
        ax.set_title(f'{group} — {facility}', fontsize=10)
        ax.set_ylabel('Số ngày trung bình')
        ax.legend(fontsize=8)
        ax.set_facecolor('#f8f9fa')

handles = [
    plt.Rectangle((0, 0), 1, 1, color=COLOR_PROD, alpha=0.85),
    plt.Rectangle((0, 0), 1, 1, color=COLOR_SCAN, alpha=0.85),
]
fig.legend(handles, ['Sản xuất (Gearment)', 'Carrier handoff (vận chuyển)'],
           loc='lower center', ncol=2, fontsize=10, bbox_to_anchor=(0.5, 0))
plt.tight_layout(rect=[0, 0.06, 1, 1])
out = f'{EXPORT_DIR}/chart4_facility_product.png'
fig.savefig(out, dpi=150)
print(f'Saved: {out}')
plt.close()


# ── Chart 2: Sản phẩm nào cần ưu tiên? ──────────────────────────────────────
fig, axes = plt.subplots(1, 2, figsize=(13, 6))
fig.suptitle(
    f'Sản phẩm nào cần ưu tiên cải thiện?\n'
    f'{PERIOD_LABEL} | Đỏ = dưới {THRESHOLD_VISUAL}% (cần xem xét) | Chỉ sản phẩm ≥100 đơn',
    fontsize=12, fontweight='bold'
)

for ax, group in zip(axes, ['Platform', 'Standard']):
    g = df_product[df_product['group'] == group].sort_values('pass_rate')
    bar_colors = [COLOR_WARN if r < THRESHOLD_VISUAL else COLOR_OK for r in g['pass_rate']]
    bars = ax.barh(g['product_type'], g['pass_rate'], color=bar_colors, alpha=0.85)
    for bar, (_, row) in zip(bars, g.iterrows()):
        ax.text(bar.get_width() + 0.5, bar.get_y() + bar.get_height() / 2,
                f"{row['pass_rate']:.1f}%  ({int(row['total_orders']):,} đơn)",
                va='center', fontsize=9)
    ax.axvline(THRESHOLD_VISUAL, color='#e74c3c', linestyle=':', linewidth=1.5, alpha=0.6,
               label=f'Ngưỡng tham khảo {THRESHOLD_VISUAL}%')
    ax.set_xlim(0, 130)
    ax.xaxis.set_major_formatter(mticker.FuncFormatter(lambda v, _: f'{v:.0f}%'))
    ax.set_xlabel('% đơn đạt SLA')
    ax.set_title(f'{group}\n(cam kết ≤{SLA[group]} ngày)', fontsize=11)
    ax.legend(fontsize=8, loc='lower right')
    ax.set_facecolor('#f8f9fa')

plt.tight_layout()
out = f'{EXPORT_DIR}/chart2_product_breakdown.png'
fig.savefig(out, dpi=150)
print(f'Saved: {out}')
plt.close()


# ── Chart 1: Nguyên nhân: sản xuất hay vận chuyển? ───────────────────────────
fig, axes = plt.subplots(1, 2, figsize=(14, 6))
fig.suptitle(
    'Nguyên nhân: chậm ở khâu sản xuất hay carrier vận chuyển?\n'
    f'{PERIOD_LABEL} | Đường đứt nét = ngưỡng SLA | Sắp xếp từ chậm nhất → nhanh nhất',
    fontsize=12, fontweight='bold'
)

BOTTLENECK_LABELS = {
    # product_type → (label, position) nếu muốn annotate
}

for ax, group in zip(axes, ['Platform', 'Standard']):
    g = df_contrib[df_contrib['group'] == group].sort_values('avg_tal', ascending=False)
    xi = np.arange(len(g))
    ax.bar(xi, g['avg_processing_day'], color=COLOR_PROD, alpha=0.85)
    ax.bar(xi, g['avg_first_scan_day'], bottom=g['avg_processing_day'], color=COLOR_SCAN, alpha=0.85)
    ax.axhline(SLA[group], color='red', linestyle='--', linewidth=1.5, alpha=0.7)
    ax.text(len(g) - 0.5, SLA[group] + 0.05, f'SLA ≤{SLA[group]} ngày',
            ha='right', fontsize=8, color='red')

    # Annotate bottleneck type on bars exceeding threshold
    for i, (_, row) in enumerate(g.iterrows()):
        total = row['avg_processing_day'] + row['avg_first_scan_day']
        if total > SLA[group]:
            dominant = 'Sản xuất' if row['avg_processing_day'] > row['avg_first_scan_day'] else 'Carrier'
            ax.text(i, total + 0.08, dominant, ha='center', fontsize=7,
                    color=COLOR_PROD if dominant == 'Sản xuất' else COLOR_SCAN, fontweight='bold')

    ax.set_xticks(xi)
    ax.set_xticklabels(g['product_type'], rotation=35, ha='right', fontsize=9)
    ax.set_ylabel('Số ngày trung bình')
    ax.set_title(f'{group} (cam kết ≤{SLA[group]} ngày)', fontsize=11)
    ax.set_facecolor('#f8f9fa')

handles = [
    plt.Rectangle((0, 0), 1, 1, color=COLOR_PROD, alpha=0.85),
    plt.Rectangle((0, 0), 1, 1, color=COLOR_SCAN, alpha=0.85),
]
fig.legend(handles, ['Sản xuất (Gearment kiểm soát)', 'Carrier handoff (sau khi xuất kho)'],
           loc='lower center', ncol=2, fontsize=10, bbox_to_anchor=(0.5, 0))
plt.tight_layout(rect=[0, 0.07, 1, 1])
out = f'{EXPORT_DIR}/chart1_contribution_split.png'
fig.savefig(out, dpi=150)
print(f'Saved: {out}')
plt.close()

print('\nDone. 4 PNGs saved to exports/')

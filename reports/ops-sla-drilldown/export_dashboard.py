"""
export_dashboard.py — Ops SLA Drilldown
Xuất 1 dashboard tổng hợp duy nhất: 3 câu hỏi, 5 biểu đồ, 1 trang.

Luồng đọc:
  Bước 1 — Xưởng nào đang chậm?       (facility triage)
  Bước 2 — Sản phẩm nào cần ưu tiên?  (product breakdown, Platform + Standard)
  Bước 3 — Nguyên nhân?               (contribution split, Platform + Standard)

Usage:
    python export_dashboard.py
"""
import sys
import os
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
import matplotlib.ticker as mticker
import matplotlib.patches as mpatches
import numpy as np

EXPORT_DIR = 'exports'
os.makedirs(EXPORT_DIR, exist_ok=True)

# ── Cấu hình ──────────────────────────────────────────────────────────────────
SLA             = {'Platform': 3, 'Standard': 4}
COLOR_PROD      = '#e67e22'   # cam — sản xuất
COLOR_SCAN      = '#3498db'   # xanh — carrier handoff
COLOR_OK        = '#2ecc71'   # xanh lá — đạt
COLOR_WARN      = '#e74c3c'   # đỏ — cần xử lý
COLOR_PLT       = '#e67e22'   # màu Platform
COLOR_STD       = '#3498db'   # màu Standard
COLOR_BG        = '#f8f9fa'
FACILITIES      = ['CA', 'TX1']
THRESHOLD_VIS   = 90          # ngưỡng tham khảo visual (%)
PERIOD_LABEL    = 'Tháng 2/2026 (tháng gần nhất hoàn chỉnh)'
PERIOD_NOTE     = '(*) Chỉ tính đơn đã có tracking data (first_scan_day IS NOT NULL)'

# ── Load & validate ────────────────────────────────────────────────────────────
required = {
    'contrib':   'queries/ops_contribution.csv',
    'product':   'queries/ops_product_breakdown.csv',
    'location':  'queries/ops_location_breakdown.csv',
}
missing = [p for p in required.values() if not os.path.exists(p)]
if missing:
    print('ERROR: Missing CSV files:', missing)
    sys.exit(1)

df_contrib  = pd.read_csv(required['contrib'])
df_product  = pd.read_csv(required['product'])
df_location = pd.read_csv(required['location'])

df_location = df_location[df_location['ordx_fulfill_locate'] != 'Unknown']
df_product  = df_product[df_product['total_orders'] >= 100]
df_contrib  = df_contrib[df_contrib['order_count'] >= 100]

# ── Tính key findings để điền vào header ──────────────────────────────────────
ca_plt  = df_location.query("group=='Platform' and ordx_fulfill_locate=='CA'")['pass_rate'].values
tx_plt  = df_location.query("group=='Platform' and ordx_fulfill_locate=='TX1'")['pass_rate'].values
ca_std  = df_location.query("group=='Standard' and ordx_fulfill_locate=='CA'")['pass_rate'].values
tx_std  = df_location.query("group=='Standard' and ordx_fulfill_locate=='TX1'")['pass_rate'].values

worst_plt = df_product[df_product['group'] == 'Platform'].sort_values('pass_rate').head(2)
worst_std = df_product[df_product['group'] == 'Standard'].sort_values('pass_rate').head(1)

# ── Figure layout ──────────────────────────────────────────────────────────────
fig = plt.figure(figsize=(16, 22), facecolor='white')
gs = gridspec.GridSpec(
    4, 3,
    figure=fig,
    height_ratios=[1.1, 4.2, 4.2, 0.75],
    hspace=0.55, wspace=0.38,
    top=0.97, bottom=0.02, left=0.07, right=0.97,
)

# ─────────────────────────────────────────────────────────────────────────────
# ROW 0 — Header
# ─────────────────────────────────────────────────────────────────────────────
ax_hdr = fig.add_subplot(gs[0, :])
ax_hdr.axis('off')

# Tiêu đề chính
ax_hdr.text(0.5, 1.02,
            'Báo cáo SLA Ops — Drilldown theo Xưởng & Sản phẩm',
            ha='center', va='top', fontsize=17, fontweight='bold',
            transform=ax_hdr.transAxes)
ax_hdr.text(0.5, 0.82,
            f'{PERIOD_LABEL}  ·  Platform cam kết ≤3 ngày  ·  Standard cam kết ≤4 ngày',
            ha='center', va='top', fontsize=10, color='#555',
            transform=ax_hdr.transAxes)

# Key findings box
box_props = dict(boxstyle='round,pad=0.5', facecolor='#eaf4fb', edgecolor='#2980b9', linewidth=1.5)
findings = (
    f"  Tóm tắt:  "
    f"① CA (California) thấp hơn TX1 — "
    f"Platform {ca_plt[0]:.0f}% vs {tx_plt[0]:.0f}%  ·  Standard {ca_std[0]:.0f}% vs {tx_std[0]:.0f}%    "
    f"② Platform cần ưu tiên: {', '.join(worst_plt['product_type'].tolist())}    "
    f"③ Nguyên nhân: Carrier handoff chậm — không phải khâu sản xuất  "
)
ax_hdr.text(0.5, 0.50, findings,
            ha='center', va='top', fontsize=9.5, color='#1a5276',
            transform=ax_hdr.transAxes, style='italic',
            bbox=box_props)

# ─────────────────────────────────────────────────────────────────────────────
# ROW 1 — Bước 1 (facility) + Bước 2 (product Platform + Standard)
# ─────────────────────────────────────────────────────────────────────────────
ax_fac      = fig.add_subplot(gs[1, 0])
ax_prod_plt = fig.add_subplot(gs[1, 1])
ax_prod_std = fig.add_subplot(gs[1, 2])

# Section header row 1
for ax, step, title in [
    (ax_fac,      'Bước 1', 'Xưởng nào đang chậm SLA?'),
    (ax_prod_plt, 'Bước 2', 'Sản phẩm nào cần ưu tiên?\n(Platform)'),
    (ax_prod_std, 'Bước 2', 'Sản phẩm nào cần ưu tiên?\n(Standard)'),
]:
    ax.set_facecolor(COLOR_BG)
    ax.set_title(f'{step} — {title}', fontsize=10.5, fontweight='bold', pad=8)

# ── Bước 1: Facility ──────────────────────────────────────────────────────────
x = np.arange(len(FACILITIES))
width = 0.33

for i, group in enumerate(['Platform', 'Standard']):
    g = (df_location[df_location['group'] == group]
         .set_index('ordx_fulfill_locate').reindex(FACILITIES))
    offset = (i - 0.5) * width
    bars = ax_fac.bar(
        x + offset, g['pass_rate'].fillna(0), width,
        label=f'{group}', color=COLOR_PLT if group == 'Platform' else COLOR_STD,
        alpha=0.88,
    )
    for bar, fac in zip(bars, FACILITIES):
        if fac in g.index and not pd.isna(g.loc[fac, 'pass_rate']):
            row = g.loc[fac]
            ax_fac.text(
                bar.get_x() + bar.get_width() / 2, bar.get_height() + 1,
                f"{row['pass_rate']:.1f}%\n({int(row['total_orders']):,} đơn)",
                ha='center', va='bottom', fontsize=8,
            )
        elif bar.get_height() == 0:
            ax_fac.text(
                bar.get_x() + bar.get_width() / 2, 2,
                'không có đơn', ha='center', va='bottom', fontsize=7, color='gray',
            )

ax_fac.axhline(THRESHOLD_VIS, color=COLOR_WARN, linestyle=':', linewidth=1.5, alpha=0.7)
ax_fac.text(len(FACILITIES) - 0.1, THRESHOLD_VIS + 1,
            f'Ngưỡng {THRESHOLD_VIS}%', ha='right', fontsize=8, color=COLOR_WARN)
ax_fac.set_xticks(x)
ax_fac.set_xticklabels(['CA\n(California)', 'TX1\n(Texas)'], fontsize=10)
ax_fac.set_ylim(0, 118)
ax_fac.yaxis.set_major_formatter(mticker.FuncFormatter(lambda v, _: f'{v:.0f}%'))
ax_fac.set_ylabel('% đơn đạt SLA')
ax_fac.annotate('✓ Tốt nhất\n(chuẩn so sánh)',
                xy=(x[1], tx_plt[0] if len(tx_plt) else 93),
                xytext=(x[1] + 0.3, 105),
                fontsize=7.5, color='#27ae60', ha='center',
                arrowprops=dict(arrowstyle='->', color='#27ae60', lw=1.2))
ax_fac.legend(fontsize=8, loc='lower right')

# ── Bước 2: Product breakdown ─────────────────────────────────────────────────
for ax, group in [(ax_prod_plt, 'Platform'), (ax_prod_std, 'Standard')]:
    g = df_product[df_product['group'] == group].sort_values('pass_rate')
    bar_colors = [COLOR_WARN if r < THRESHOLD_VIS else COLOR_OK for r in g['pass_rate']]
    bars = ax.barh(g['product_type'], g['pass_rate'], color=bar_colors, alpha=0.88)
    for bar, (_, row) in zip(bars, g.iterrows()):
        ax.text(
            min(bar.get_width() + 0.8, 128),
            bar.get_y() + bar.get_height() / 2,
            f"{row['pass_rate']:.1f}%  ({int(row['total_orders']):,} đơn)",
            va='center', fontsize=8,
        )
    ax.axvline(THRESHOLD_VIS, color=COLOR_WARN, linestyle=':', linewidth=1.5, alpha=0.7,
               label=f'Ngưỡng {THRESHOLD_VIS}%')
    ax.set_xlim(0, 135)
    ax.xaxis.set_major_formatter(mticker.FuncFormatter(lambda v, _: f'{v:.0f}%'))
    ax.set_xlabel('% đơn đạt SLA')
    ax.legend(fontsize=8, loc='lower right')
    ax.set_facecolor(COLOR_BG)

# ─────────────────────────────────────────────────────────────────────────────
# ROW 2 — Bước 3: Nguyên nhân (contribution split)
# ─────────────────────────────────────────────────────────────────────────────
ax_why_plt = fig.add_subplot(gs[2, :2])
ax_why_std = fig.add_subplot(gs[2, 2])

for ax, group in [(ax_why_plt, 'Platform'), (ax_why_std, 'Standard')]:
    g = df_contrib[df_contrib['group'] == group].sort_values('avg_tal', ascending=False)
    xi = np.arange(len(g))
    ax.bar(xi, g['avg_processing_day'],                color=COLOR_PROD, alpha=0.88, label='Sản xuất')
    ax.bar(xi, g['avg_first_scan_day'],
           bottom=g['avg_processing_day'],              color=COLOR_SCAN, alpha=0.88, label='Carrier handoff')
    threshold = SLA[group]
    ax.axhline(threshold, color='red', linestyle='--', linewidth=1.5, alpha=0.75)
    ax.text(len(g) - 0.5, threshold + 0.06,
            f'SLA ≤{threshold} ngày', ha='right', fontsize=8, color='red')

    # Annotate dominant bottleneck trên bars vượt SLA
    for i, (_, row) in enumerate(g.iterrows()):
        total = row['avg_processing_day'] + row['avg_first_scan_day']
        if total > threshold:
            dominant = 'Carrier' if row['avg_first_scan_day'] > row['avg_processing_day'] else 'Sản xuất'
            color = COLOR_SCAN if dominant == 'Carrier' else COLOR_PROD
            ax.text(i, total + 0.07, f'↑ {dominant}',
                    ha='center', fontsize=7.5, color=color, fontweight='bold')

    ax.set_xticks(xi)
    ax.set_xticklabels(g['product_type'], rotation=32, ha='right', fontsize=9)
    ax.set_ylabel('Số ngày trung bình')
    ax.set_title(f'Bước 3 — Nguyên nhân? ({group})', fontsize=10.5, fontweight='bold', pad=8)
    ax.legend(fontsize=8, loc='upper right')
    ax.set_facecolor(COLOR_BG)

# ax_why_plt chiếm 2/3 width → phù hợp vì Platform có nhiều sản phẩm hơn

# ─────────────────────────────────────────────────────────────────────────────
# ROW 3 — Legend + Ghi chú
# ─────────────────────────────────────────────────────────────────────────────
ax_foot = fig.add_subplot(gs[3, :])
ax_foot.axis('off')

# Legend patches
legend_items = [
    mpatches.Patch(color=COLOR_PLT,  alpha=0.88, label='Platform (Ship by Seller — khách tự cung cấp label)'),
    mpatches.Patch(color=COLOR_STD,  alpha=0.88, label='Standard (Ship by Gearment — GM mua label)'),
    mpatches.Patch(color=COLOR_PROD, alpha=0.88, label='Sản xuất — thời gian từ thanh toán đến hoàn tất sản xuất'),
    mpatches.Patch(color=COLOR_SCAN, alpha=0.88, label='Carrier handoff — thời gian từ hoàn tất đến carrier scan lần đầu'),
    mpatches.Patch(color=COLOR_OK,   alpha=0.88, label=f'Đạt (≥ {THRESHOLD_VIS}% — ngưỡng tham khảo)'),
    mpatches.Patch(color=COLOR_WARN, alpha=0.88, label=f'Cần xem xét (< {THRESHOLD_VIS}%)'),
]
ax_foot.legend(
    handles=legend_items, loc='upper left',
    ncol=3, fontsize=8.5,
    frameon=True, framealpha=0.9,
    bbox_to_anchor=(0, 1.05),
)

# Footnotes
footnotes = (
    f'Nguồn dữ liệu: gea__silver.fact_order_fulfillment_performance_by_product · '
    f'TAL = floor(processing_day + first_scan_day) biz days  ·  '
    f'Chỉ hiển thị sản phẩm có ≥ 100 đơn trong kỳ\n'
    f'{PERIOD_NOTE}  ·  '
    f'Ngưỡng {THRESHOLD_VIS}% là tham khảo nội bộ, chưa phải KPI chính thức  ·  '
    f'CA = HB1 + HB2 (cùng ops lead California)'
)
ax_foot.text(0, -0.05, footnotes,
             ha='left', va='top', fontsize=7.5, color='#777',
             transform=ax_foot.transAxes, linespacing=1.6)

# ─────────────────────────────────────────────────────────────────────────────
out = f'{EXPORT_DIR}/dashboard.png'
fig.savefig(out, dpi=150, bbox_inches='tight')
print(f'Saved: {out}')
plt.close()

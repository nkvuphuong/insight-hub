"""
export_dashboard.py — Order SLA (BOD View)
Xuất 1 dashboard duy nhất: scorecard tháng hiện tại + trend 12 tháng.

Audience: BOD — đọc ≤30s, quyết định có cần escalate xuống ops không.

Luồng đọc:
  Phần 1 — Tháng này như thế nào?   (scorecard + delta vs tháng trước)
  Phần 2 — Xu hướng đang đi đâu?    (trend 12 tháng, annotate events)

Usage:
    python3 export_dashboard.py
"""
import sys
import os
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
import matplotlib.patches as mpatches
import matplotlib.ticker as mticker
from pathlib import Path

BASE    = Path(__file__).parent
QUERIES = BASE / 'queries'
EXPORTS = BASE / 'exports'
EXPORTS.mkdir(exist_ok=True)

# ── Cấu hình ──────────────────────────────────────────────────────────────────
COLORS     = {'Standard': '#3498db', 'Platform': '#e67e22'}
THRESHOLDS = {'Standard': 4, 'Platform': 3}
COLOR_UP   = '#27ae60'
COLOR_DOWN = '#c0392b'
COLOR_BG   = '#f8f9fa'
MIN_ORDERS = 30   # lọc tháng quá ít đơn

# ── Load & validate ────────────────────────────────────────────────────────────
for f in ['sla_standard.csv', 'sla_platform.csv']:
    if not (QUERIES / f).exists():
        print(f'ERROR: {f} chưa có. Chạy query tương ứng qua MCP trước.')
        sys.exit(1)

std  = pd.read_csv(QUERIES / 'sla_standard.csv')
plt_ = pd.read_csv(QUERIES / 'sla_platform.csv')

df = pd.concat([
    std[['month', 'group', 'total_orders', 'tal_pass_rate']],
    plt_[['month', 'group', 'total_orders', 'tal_pass_rate']],
], ignore_index=True).sort_values(['group', 'month'])

df_trend = df[df['total_orders'] >= MIN_ORDERS].copy()


def get_scorecard(group):
    g = df_trend[df_trend['group'] == group].sort_values('month').reset_index(drop=True)
    if len(g) < 2:
        return None
    return {
        'month':        g.iloc[-1]['month'],
        'pass_rate':    g.iloc[-1]['tal_pass_rate'],
        'total_orders': int(g.iloc[-1]['total_orders']),
        'delta':        round(g.iloc[-1]['tal_pass_rate'] - g.iloc[-2]['tal_pass_rate'], 1),
        'prev_month':   g.iloc[-2]['month'],
    }

sc_std = get_scorecard('Standard')
sc_plt = get_scorecard('Platform')

# ── Xác định status tổng: tốt / cần theo dõi / cần escalate ──────────────────
def status_label(sc):
    if sc is None:
        return '—'
    r = sc['pass_rate']
    d = sc['delta']
    if r >= 90 and d >= -3:
        return 'Tốt ✓'
    elif r >= 80 or d >= 0:
        return 'Cần theo dõi ⚠'
    else:
        return 'Cần escalate ✗'

status_plt = status_label(sc_plt)
status_std = status_label(sc_std)
overall_ok = all('Tốt' in s for s in [status_plt, status_std])

# ── Figure layout ──────────────────────────────────────────────────────────────
fig = plt.figure(figsize=(14, 18), facecolor='white')
gs = gridspec.GridSpec(
    4, 2,
    figure=fig,
    height_ratios=[1.0, 3.5, 4.5, 0.6],
    hspace=0.50, wspace=0.28,
    top=0.97, bottom=0.02, left=0.07, right=0.97,
)

# ─────────────────────────────────────────────────────────────────────────────
# ROW 0 — Header + status box
# ─────────────────────────────────────────────────────────────────────────────
ax_hdr = fig.add_subplot(gs[0, :])
ax_hdr.axis('off')

ax_hdr.text(0.5, 1.02,
            'Báo cáo SLA Đơn Hàng — Tổng Quan',
            ha='center', va='top', fontsize=17, fontweight='bold',
            transform=ax_hdr.transAxes)
ax_hdr.text(0.5, 0.82,
            'Platform cam kết ≤ 3 biz days  ·  Standard cam kết ≤ 4 biz days  ·  Trend 12 tháng',
            ha='center', va='top', fontsize=10, color='#555',
            transform=ax_hdr.transAxes)

# Status box
if overall_ok:
    box_face, box_edge = '#eafaf1', '#27ae60'
    action_text = 'Không cần escalate. Tiếp tục theo dõi tháng tới.'
else:
    box_face, box_edge = '#fef9e7', '#f39c12'
    action_text = 'Xem chi tiết phần scorecard — có nhóm cần chú ý.'

latest_month = max(
    sc_plt['month'] if sc_plt else '—',
    sc_std['month'] if sc_std else '—',
)
summary = (
    f"  Tháng {latest_month}:  "
    f"Platform {sc_plt['pass_rate']:.1f}% "
    f"({'▲' if sc_plt['delta'] >= 0 else '▼'}{abs(sc_plt['delta']):.1f}% vs tháng trước)  ·  "
    f"Standard {sc_std['pass_rate']:.1f}% "
    f"({'▲' if sc_std['delta'] >= 0 else '▼'}{abs(sc_std['delta']):.1f}% vs tháng trước)    "
    f"→  {action_text}  "
)
ax_hdr.text(0.5, 0.50, summary,
            ha='center', va='top', fontsize=9.5, color='#1a5276',
            transform=ax_hdr.transAxes, style='italic',
            bbox=dict(boxstyle='round,pad=0.5', facecolor=box_face,
                      edgecolor=box_edge, linewidth=1.5))

# ─────────────────────────────────────────────────────────────────────────────
# ROW 1 — Scorecard × 2
# ─────────────────────────────────────────────────────────────────────────────
for col_idx, (group, sc) in enumerate([('Standard', sc_std), ('Platform', sc_plt)]):
    ax = fig.add_subplot(gs[1, col_idx])
    ax.axis('off')
    color = COLORS[group]

    # Border box
    rect = mpatches.FancyBboxPatch(
        (0.04, 0.04), 0.92, 0.92,
        boxstyle='round,pad=0.02',
        linewidth=2.5, edgecolor=color,
        facecolor=COLOR_BG, transform=ax.transAxes,
    )
    ax.add_patch(rect)

    if sc is None:
        ax.text(0.5, 0.5, 'Không đủ dữ liệu',
                ha='center', va='center', fontsize=12, color='gray',
                transform=ax.transAxes)
        continue

    arrow  = '▲' if sc['delta'] >= 0 else '▼'
    dcol   = COLOR_UP if sc['delta'] >= 0 else COLOR_DOWN
    status = status_label(sc)
    scol   = COLOR_UP if 'Tốt' in status else (COLOR_DOWN if 'escalate' in status else '#e67e22')

    # Group name
    ax.text(0.5, 0.87, group, ha='center', va='center',
            fontsize=15, fontweight='bold', color=color, transform=ax.transAxes)
    ax.text(0.5, 0.78,
            f"Ship by {'Seller' if group == 'Platform' else 'Gearment'}  ·  SLA ≤ {THRESHOLDS[group]} biz days",
            ha='center', va='center', fontsize=9, color='#777', transform=ax.transAxes)

    # Big number
    ax.text(0.5, 0.55, f"{sc['pass_rate']:.1f}%",
            ha='center', va='center', fontsize=46, fontweight='bold',
            color=color, transform=ax.transAxes)

    # Delta
    ax.text(0.5, 0.35,
            f"{arrow} {abs(sc['delta']):.1f}% so với {sc['prev_month']}",
            ha='center', va='center', fontsize=13,
            color=dcol, fontweight='bold', transform=ax.transAxes)

    # Status + meta
    ax.text(0.5, 0.22, status,
            ha='center', va='center', fontsize=11, color=scol,
            fontweight='bold', transform=ax.transAxes)
    footnote = '\n(*) Chỉ tính đơn có tracking data (first scan IS NOT NULL)' \
               if group == 'Standard' else ''
    ax.text(0.5, 0.10,
            f"{sc['month']}  ·  n = {sc['total_orders']:,} đơn{footnote}",
            ha='center', va='center', fontsize=8, color='gray', transform=ax.transAxes)

# ─────────────────────────────────────────────────────────────────────────────
# ROW 2 — Trend 12 tháng
# ─────────────────────────────────────────────────────────────────────────────
ax_tr = fig.add_subplot(gs[2, :])
ax_tr.set_facecolor(COLOR_BG)

# Tạo shared x-axis từ union tất cả tháng, sắp xếp tăng dần
std_g = df_trend[df_trend['group'] == 'Standard'].sort_values('month').reset_index(drop=True)
plt_g = df_trend[df_trend['group'] == 'Platform'].sort_values('month').reset_index(drop=True)

all_months = sorted(set(std_g['month'].tolist()) | set(plt_g['month'].tolist()))
month_to_x = {m: i for i, m in enumerate(all_months)}

for group, g in [('Standard', std_g), ('Platform', plt_g)]:
    xs = [month_to_x[m] for m in g['month']]
    ax_tr.plot(
        xs, g['tal_pass_rate'],
        marker='o', linewidth=2.2, markersize=7,
        color=COLORS[group],
        label=f"{group} (SLA ≤ {THRESHOLDS[group]} biz days)",
        zorder=3,
    )
    # Annotate endpoint
    ax_tr.annotate(
        f"  {g.iloc[-1]['tal_pass_rate']:.1f}%",
        xy=(xs[-1], g.iloc[-1]['tal_pass_rate']), fontsize=9.5,
        color=COLORS[group], fontweight='bold', va='center',
    )
    # Annotate low-volume Standard months
    if group == 'Standard':
        for x, (_, row) in zip(xs, g.iterrows()):
            if row['total_orders'] < 3000:
                ax_tr.text(x, row['tal_pass_rate'] + 2.5,
                           f"(n={int(row['total_orders']):,})",
                           ha='center', fontsize=7, color='#999')

# Annotation Dec 2025
if '2025-12' in month_to_x:
    dec_x = month_to_x['2025-12']
    dec_val_std = std_g.loc[std_g['month'] == '2025-12', 'tal_pass_rate']
    dec_val_plt = plt_g.loc[plt_g['month'] == '2025-12', 'tal_pass_rate']
    if not dec_val_std.empty:
        ax_tr.annotate(
            'Dec 2025 — Holiday peak\ncả 2 nhóm drop mạnh',
            xy=(dec_x, dec_val_std.values[0]),
            xytext=(dec_x - 1.2, dec_val_std.values[0] - 16),
            fontsize=8.5, ha='center', color='#c0392b', fontweight='bold',
            arrowprops=dict(arrowstyle='->', color='#c0392b', lw=1.3),
        )
    if not dec_val_plt.empty:
        ax_tr.annotate(
            f"{dec_val_plt.values[0]:.1f}%",
            xy=(dec_x, dec_val_plt.values[0]),
            xytext=(dec_x + 0.5, dec_val_plt.values[0] + 5),
            fontsize=8.5, color=COLORS['Platform'],
            arrowprops=dict(arrowstyle='->', color=COLORS['Platform'], lw=1.0),
        )

# Recovery bracket (Jan → latest trong Standard)
if '2026-01' in month_to_x:
    jan_x    = month_to_x['2026-01']
    latest_x = month_to_x[std_g.iloc[-1]['month']]
    mid_x    = (jan_x + latest_x) / 2
    top_y    = 103
    ax_tr.annotate('', xy=(latest_x, top_y), xytext=(jan_x, top_y),
                   arrowprops=dict(arrowstyle='<->', color='#27ae60', lw=1.5),
                   annotation_clip=False)
    ax_tr.text(mid_x, top_y + 1.5, 'Phục hồi 3 tháng liên tục',
               ha='center', fontsize=8.5, color='#27ae60', fontweight='bold')

# Trục x — shared months
ax_tr.set_xticks(range(len(all_months)))
ax_tr.set_xticklabels(all_months, rotation=35, ha='right', fontsize=9)
ax_tr.set_ylim(0, 108)
ax_tr.yaxis.set_major_formatter(mticker.FuncFormatter(lambda v, _: f'{v:.0f}%'))
ax_tr.set_ylabel('% đơn đạt SLA (TAL)', fontsize=10)
ax_tr.set_title('Phần 2 — Xu hướng 12 tháng: Đang đi đâu?',
                fontsize=11, fontweight='bold', pad=8)
ax_tr.legend(fontsize=9.5, loc='lower left')
ax_tr.grid(axis='y', linestyle='--', alpha=0.45, zorder=0)

# Note: Platform chỉ có data từ Aug 2025
ax_tr.text(0.01, 0.04,
           'Platform: data available từ Aug 2025 (trước đó chưa có tracking)',
           transform=ax_tr.transAxes, fontsize=7.5, color='#aaa')

# ─────────────────────────────────────────────────────────────────────────────
# ROW 3 — Footnotes
# ─────────────────────────────────────────────────────────────────────────────
ax_foot = fig.add_subplot(gs[3, :])
ax_foot.axis('off')

footnotes = (
    'Nguồn: gea__silver.fact_order_fulfillment_performance FINAL  ·  '
    'TAL = floor(processing_day + first_scan_day) biz days (payment → first carrier scan)  ·  '
    'Tháng mới nhất có thể chưa hoàn chỉnh\n'
    'Standard: ~36% đơn không có first_scan_day → nằm ngoài denominator (không phải SLA fail)  ·  '
    'Platform: chỉ cover USPS order labels  ·  '
    'Chưa có internal target chính thức — dùng trend để đánh giá'
)
ax_foot.text(0, 0.95, footnotes,
             ha='left', va='top', fontsize=7.5, color='#888',
             transform=ax_foot.transAxes, linespacing=1.6)

# ─────────────────────────────────────────────────────────────────────────────
out = EXPORTS / 'dashboard.png'
fig.savefig(out, dpi=150, bbox_inches='tight')
print(f'Saved: {out}')
plt.close()

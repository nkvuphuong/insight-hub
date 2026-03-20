"""
Order SLA — Export PNG
Audience: BOD

Xuất 2 views:
  - order-sla-scorecard.png  : pass rate tháng hiện tại + MoM delta
  - order-sla-trend.png      : TAL pass rate 12 tháng, Platform vs Standard

Yêu cầu CSV đã có:
  queries/sla_standard.csv
  queries/sla_platform.csv
"""

import sys
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import matplotlib.ticker as mticker
from pathlib import Path

# ── Paths ──────────────────────────────────────────────────────────────────
BASE = Path(__file__).parent
QUERIES = BASE / 'queries'
EXPORTS = BASE / 'exports'
EXPORTS.mkdir(exist_ok=True)

# ── Load ───────────────────────────────────────────────────────────────────
for f in ['sla_standard.csv', 'sla_platform.csv']:
    if not (QUERIES / f).exists():
        print(f'ERROR: {f} chưa có. Chạy query tương ứng qua MCP trước.')
        sys.exit(1)

std = pd.read_csv(QUERIES / 'sla_standard.csv')
plt_ = pd.read_csv(QUERIES / 'sla_platform.csv')

df = pd.concat([
    std[['month', 'group', 'total_orders', 'tal_pass_rate']],
    plt_[['month', 'group', 'total_orders', 'tal_pass_rate']],
], ignore_index=True).sort_values(['group', 'month'])

df_trend = df[df['total_orders'] >= 30].copy()

COLORS = {'Standard': '#3498db', 'Platform': '#e67e22'}
THRESHOLDS = {'Standard': 4, 'Platform': 3}


def get_scorecard(group):
    g = df_trend[df_trend['group'] == group].sort_values('month').reset_index(drop=True)
    if len(g) < 2:
        return None
    return {
        'group': group,
        'month': g.iloc[-1]['month'],
        'pass_rate': g.iloc[-1]['tal_pass_rate'],
        'total_orders': int(g.iloc[-1]['total_orders']),
        'delta': round(g.iloc[-1]['tal_pass_rate'] - g.iloc[-2]['tal_pass_rate'], 1),
        'prev_month': g.iloc[-2]['month'],
    }


# ── View 1: Scorecard ──────────────────────────────────────────────────────
fig, axes = plt.subplots(1, 2, figsize=(10, 4))
fig.suptitle('SLA Pass Rate — Current Month', fontsize=15, fontweight='bold', y=1.02)

for ax, group in zip(axes, ['Standard', 'Platform']):
    s = get_scorecard(group)
    ax.axis('off')
    if not s:
        ax.text(0.5, 0.5, 'Insufficient data', ha='center', va='center', fontsize=12, color='gray')
        continue

    arrow = '▲' if s['delta'] >= 0 else '▼'
    delta_color = '#27ae60' if s['delta'] >= 0 else '#c0392b'
    footnote = '\n(*) chỉ tính đơn có tracking data' if group == 'Standard' else ''

    ax.text(0.5, 0.82, group, ha='center', va='center', fontsize=14,
            fontweight='bold', color=COLORS[group], transform=ax.transAxes)
    ax.text(0.5, 0.52, f"{s['pass_rate']:.1f}%", ha='center', va='center',
            fontsize=40, fontweight='bold', transform=ax.transAxes)
    ax.text(0.5, 0.28, f"{arrow} {abs(s['delta']):.1f}% vs {s['prev_month']}",
            ha='center', va='center', fontsize=13, color=delta_color, transform=ax.transAxes)
    ax.text(0.5, 0.10,
            f"SLA ≤{THRESHOLDS[group]} biz days | {s['month']} | n={s['total_orders']:,}{footnote}",
            ha='center', va='center', fontsize=9, color='gray', transform=ax.transAxes)

    rect = mpatches.FancyBboxPatch((0.05, 0.02), 0.9, 0.96,
                                    boxstyle='round,pad=0.02',
                                    linewidth=2, edgecolor=COLORS[group],
                                    facecolor='#f8f9fa', transform=ax.transAxes)
    ax.add_patch(rect)

plt.tight_layout()
out1 = EXPORTS / 'order-sla-scorecard.png'
fig.savefig(out1, dpi=150, bbox_inches='tight')
print(f'Saved: {out1}')
plt.close()


# ── View 2: Trend ──────────────────────────────────────────────────────────
fig, ax = plt.subplots(figsize=(12, 5))

for group in ['Standard', 'Platform']:
    g = df_trend[df_trend['group'] == group].sort_values('month')
    ax.plot(g['month'], g['tal_pass_rate'],
            marker='o', linewidth=2, markersize=6,
            color=COLORS[group],
            label=f"{group} (SLA ≤{THRESHOLDS[group]} biz days)")
    # Label điểm cuối
    if len(g):
        last = g.iloc[-1]
        ax.annotate(f"{last['tal_pass_rate']:.1f}%",
                    xy=(last['month'], last['tal_pass_rate']),
                    xytext=(5, 4), textcoords='offset points',
                    fontsize=9, color=COLORS[group], fontweight='bold')

ax.set_title('SLA TAL Pass Rate — 12 Tháng', fontsize=14, fontweight='bold', pad=12)
ax.set_xlabel('Tháng', fontsize=11)
ax.set_ylabel('TAL Pass Rate (%)', fontsize=11)
ax.set_ylim(0, 105)
ax.yaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f'{x:.0f}%'))
ax.legend(fontsize=10, loc='lower left')
ax.set_facecolor('#f8f9fa')
ax.grid(axis='y', linestyle='--', alpha=0.5)
plt.xticks(rotation=45, ha='right', fontsize=9)
plt.tight_layout()

out2 = EXPORTS / 'order-sla-trend.png'
fig.savefig(out2, dpi=150, bbox_inches='tight')
print(f'Saved: {out2}')
plt.close()

print('\nDone. 2 files exported.')

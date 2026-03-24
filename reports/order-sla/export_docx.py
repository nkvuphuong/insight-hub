"""
export_docx.py — Order SLA (BOD View)
Xuất bod-summary.md + dashboard.png thành 1 file DOCX.

Usage:
    python3 export_docx.py
Output:
    exports/order-sla-summary.docx
"""
from pathlib import Path
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml.ns import qn
from docx.oxml import OxmlElement
import re

BASE    = Path(__file__).parent
EXPORTS = BASE / 'exports'
IMG     = EXPORTS / 'dashboard.png'
OUT     = EXPORTS / 'order-sla-summary.docx'

assert IMG.exists(), f'Missing: {IMG} — chạy export_dashboard.py trước.'

doc = Document()

# ── Page margins (2cm)
for section in doc.sections:
    section.top_margin    = Inches(0.79)
    section.bottom_margin = Inches(0.79)
    section.left_margin   = Inches(0.98)
    section.right_margin  = Inches(0.98)


def set_heading(para, level=1):
    """Apply heading style."""
    para.style = doc.styles[f'Heading {level}']


def add_rule(doc):
    """Thêm đường kẻ ngang."""
    p = doc.add_paragraph()
    pPr = p._p.get_or_add_pPr()
    pBdr = OxmlElement('w:pBdr')
    bottom = OxmlElement('w:bottom')
    bottom.set(qn('w:val'), 'single')
    bottom.set(qn('w:sz'), '6')
    bottom.set(qn('w:space'), '1')
    bottom.set(qn('w:color'), 'CCCCCC')
    pBdr.append(bottom)
    pPr.append(pBdr)
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.space_after  = Pt(0)


def add_key_value_row(table, key, val, bold_val=False):
    row = table.add_row()
    row.cells[0].text = key
    row.cells[1].text = val
    row.cells[0].paragraphs[0].runs[0].bold = True
    if bold_val:
        row.cells[1].paragraphs[0].runs[0].bold = True
    for cell in row.cells:
        for para in cell.paragraphs:
            for run in para.runs:
                run.font.size = Pt(10)


# ── Title ─────────────────────────────────────────────────────────────────────
title = doc.add_heading('Báo Cáo SLA Đơn Hàng — Tổng Quan', level=1)
title.alignment = WD_ALIGN_PARAGRAPH.CENTER

sub = doc.add_paragraph('Platform ≤ 3 biz days  ·  Standard ≤ 4 biz days  ·  Trend 12 tháng')
sub.alignment = WD_ALIGN_PARAGRAPH.CENTER
sub.runs[0].font.color.rgb = RGBColor(0x55, 0x55, 0x55)
sub.runs[0].font.size = Pt(10)

# ── Dashboard image ────────────────────────────────────────────────────────────
doc.add_paragraph()
p = doc.add_paragraph()
p.alignment = WD_ALIGN_PARAGRAPH.CENTER
run = p.add_run()
run.add_picture(str(IMG), width=Inches(6.3))

add_rule(doc)
doc.add_paragraph()

# ── Phần 1: Scorecard ─────────────────────────────────────────────────────────
doc.add_heading('Phần 1 — Tháng Này Như Thế Nào?', level=2)

tbl = doc.add_table(rows=1, cols=5)
tbl.style = 'Table Grid'
hdr = tbl.rows[0].cells
for cell, text in zip(hdr, ['Nhóm', 'Pass Rate', 'vs Tháng Trước', 'Số Đơn', 'Tình Trạng']):
    cell.text = text
    cell.paragraphs[0].runs[0].bold = True
    cell.paragraphs[0].runs[0].font.size = Pt(9.5)

data_rows = [
    ('Platform (Ship by Seller)',  '96.4%', '▲ +5.5%', '5,481', 'Tốt ✓'),
    ('Standard (Ship by Gearment)', '96.3%', '▲ +2.3%', '2,429', 'Tốt ✓'),
]
for row_data in data_rows:
    row = tbl.add_row()
    for cell, val in zip(row.cells, row_data):
        cell.text = val
        cell.paragraphs[0].runs[0].font.size = Pt(9.5)

doc.add_paragraph()
note = doc.add_paragraph(
    '(*) Standard: chỉ tính đơn có tracking data (first_scan IS NOT NULL). '
    '~36% đơn không có tracking — nằm ngoài denominator, không phải SLA fail.'
)
note.runs[0].font.size = Pt(8.5)
note.runs[0].font.color.rgb = RGBColor(0x77, 0x77, 0x77)

# Action box
doc.add_paragraph()
action_heading = doc.add_heading('Action tháng này', level=3)
action = doc.add_paragraph(
    'Không cần escalate. Cả 2 nhóm đang tăng và đạt mức cao nhất trong data.\n'
    'Theo dõi tháng tới — đặc biệt chú ý nếu bất kỳ nhóm nào giảm quá 5pp so với tháng này.\n\n'
    'Platform: ~197 đơn không đạt SLA (≈3.6% × 5,481). '
    'Nếu cần biết xưởng / sản phẩm nào → xem Ops SLA Drilldown.'
)
action.runs[0].font.size = Pt(10)

add_rule(doc)
doc.add_paragraph()

# ── Phần 2: Trend ─────────────────────────────────────────────────────────────
doc.add_heading('Phần 2 — Xu Hướng Đang Đi Đâu?', level=2)

p = doc.add_paragraph('Tình hình tốt: ')
p.runs[0].bold = True
p.runs[0].font.size = Pt(10)
r = p.add_run(
    'Recovery liên tục 3 tháng (Jan–Mar 2026) sau đáy Dec 2025. '
    'Cả 2 nhóm đang ở mức cao nhất kể từ khi có data.'
)
r.font.size = Pt(10)

tbl2 = doc.add_table(rows=1, cols=4)
tbl2.style = 'Table Grid'
for cell, text in zip(tbl2.rows[0].cells, ['Giai đoạn', 'Sự kiện', 'Platform', 'Standard']):
    cell.text = text
    cell.paragraphs[0].runs[0].bold = True
    cell.paragraphs[0].runs[0].font.size = Pt(9.5)

trend_rows = [
    ('Dec 2025', 'Holiday peak — overload toàn hệ thống', '41.9% (đáy)', '68.6% (đáy)'),
    ('Jan–Mar 2026', 'Recovery rõ ràng', '89% → 91% → 96.4%', '96% → 94% → 96.3%'),
    ('Aug–Oct 2025', 'Standard volume thấp bất thường', '—', '1–2K đơn/tháng (vs bình thường 14–72K)'),
]
for row_data in trend_rows:
    row = tbl2.add_row()
    for cell, val in zip(row.cells, row_data):
        cell.text = val
        cell.paragraphs[0].runs[0].font.size = Pt(9.5)

doc.add_paragraph()
dec_note = doc.add_paragraph(
    'Chuẩn bị Dec 2026: Dec 2025 là outlier rõ nhất trong toàn bộ data. '
    'Nên lên kế hoạch ops capacity tăng cường trước ít nhất 1 tháng.'
)
dec_note.runs[0].bold = True
dec_note.runs[0].font.size = Pt(10)

add_rule(doc)
doc.add_paragraph()

# ── Câu hỏi còn mở ────────────────────────────────────────────────────────────
doc.add_heading('Câu Hỏi Gợi Ý Cho BOD Review', level=2)

questions = [
    'Số liệu có phản ánh đúng thực tế không? Ops team có thể xác nhận Dec 2025 thực sự overload không?',
    'Standard volume Aug–Oct 2025 rất thấp (1–2K vs bình thường 14–72K) — có sự kiện gì không?',
    'Internal target là bao nhiêu? Hiện chưa có benchmark — team đề xuất target % để đưa vào dashboard?',
    'Chuẩn bị Dec 2026: Ops cần plan capacity tăng cường từ bao giờ?',
]
for i, q in enumerate(questions, 1):
    p = doc.add_paragraph(style='List Number')
    p.text = ''
    p.add_run(q).font.size = Pt(10)

add_rule(doc)

# ── Context kỹ thuật ──────────────────────────────────────────────────────────
doc.add_heading('Context Kỹ Thuật', level=2)
tech = [
    'Data source: gea__silver.fact_order_fulfillment_performance FINAL',
    'Platform: is_platform = 1, SLA = floor(processing_day + first_scan_day) ≤ 3 biz days',
    'Standard: is_platform = 0, SLA = floor(processing_day + first_scan_day) ≤ 4 biz days',
    'TAL = payment → first carrier scan (biz days)',
    'Period: 12 tháng gần nhất · Lọc tháng < 30 đơn',
    'Platform data available từ Aug 2025 · Standard từ Mar 2025',
]
for item in tech:
    p = doc.add_paragraph(style='List Bullet')
    p.text = ''
    r = p.add_run(item)
    r.font.size = Pt(9)
    r.font.color.rgb = RGBColor(0x55, 0x55, 0x55)

# ── Save ──────────────────────────────────────────────────────────────────────
doc.save(OUT)
print(f'Saved: {OUT}')

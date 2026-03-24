"""
export_docx.py — Ops SLA Drilldown
Xuất ops_summary.md + dashboard.png thành 1 file DOCX.

Usage:
    python3 export_docx.py
Output:
    exports/ops-sla-summary.docx
"""
from pathlib import Path
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

BASE    = Path(__file__).parent
EXPORTS = BASE / 'exports'
IMG     = EXPORTS / 'dashboard.png'
OUT     = EXPORTS / 'ops-sla-summary.docx'

assert IMG.exists(), f'Missing: {IMG} — chạy export_dashboard.py trước.'

doc = Document()

for section in doc.sections:
    section.top_margin    = Inches(0.79)
    section.bottom_margin = Inches(0.79)
    section.left_margin   = Inches(0.98)
    section.right_margin  = Inches(0.98)


def add_rule(doc):
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


# ── Title ─────────────────────────────────────────────────────────────────────
title = doc.add_heading('Báo Cáo SLA Ops — Drilldown theo Xưởng & Sản phẩm', level=1)
title.alignment = WD_ALIGN_PARAGRAPH.CENTER

sub = doc.add_paragraph('Tháng 2/2026  ·  Platform ≤ 3 biz days  ·  Standard ≤ 4 biz days')
sub.alignment = WD_ALIGN_PARAGRAPH.CENTER
sub.runs[0].font.color.rgb = RGBColor(0x55, 0x55, 0x55)
sub.runs[0].font.size = Pt(10)

# ── Dashboard image ────────────────────────────────────────────────────────────
doc.add_paragraph()
p = doc.add_paragraph()
p.alignment = WD_ALIGN_PARAGRAPH.CENTER
p.add_run().add_picture(str(IMG), width=Inches(6.3))

add_rule(doc)
doc.add_paragraph()

# ── Kết quả tổng quan ─────────────────────────────────────────────────────────
doc.add_heading('Kết Quả Tổng Quan', level=2)

tbl = doc.add_table(rows=1, cols=3)
tbl.style = 'Table Grid'
for cell, text in zip(tbl.rows[0].cells, ['Nhóm', 'CA (California)', 'TX1 (Texas)']):
    cell.text = text
    cell.paragraphs[0].runs[0].bold = True
    cell.paragraphs[0].runs[0].font.size = Pt(9.5)

for row_data in [
    ('Platform', '84.1% ⚠', '93.4% ✓'),
    ('Standard', '90.9% ✓', '98.0% ✓'),
]:
    row = tbl.add_row()
    for cell, val in zip(row.cells, row_data):
        cell.text = val
        cell.paragraphs[0].runs[0].font.size = Pt(9.5)

doc.add_paragraph()
p = doc.add_paragraph('CA đang kéo SLA chung xuống. TX1 là chuẩn so sánh.')
p.runs[0].font.size = Pt(10)

add_rule(doc)
doc.add_paragraph()

# ── Ưu tiên xử lý ─────────────────────────────────────────────────────────────
doc.add_heading('Ưu Tiên Xử Lý (Theo Impact)', level=2)

fixes = [
    (
        'Fix #1 — Platform CA: Poster (n=1,573, pass=84.1%)',
        'Carrier handoff chậm — avg_scan=1.44 ngày. '
        'Action: Kiểm tra lịch carrier pickup tại CA. '
        'Có đơn bị tồn kho chờ scan không?',
        True,
    ),
    (
        'Fix #2 — Platform TX1: Doormat (n=310, pass=82.3%)',
        'avg_tal=3.03 ngày (vượt SLA ≤3). Carrier handoff là chính: avg_scan=2.41 ngày, sản xuất chỉ 0.62 ngày. '
        'Action: Doormat kích thước lớn — carrier pickup có bị delay không?',
        True,
    ),
    (
        'Theo dõi — Platform: Sticker (n=2,958, pass=89.2%)',
        'Borderline (dưới 90% tham khảo). Volume cao nhất. avg_scan=1.50 ngày. '
        'Chưa cần escalate ngay — nếu tiếp tục giảm sang tháng 3 thì prioritize.',
        False,
    ),
]

for heading_text, body_text, is_red in fixes:
    h = doc.add_heading(heading_text, level=3)
    if is_red:
        for run in h.runs:
            run.font.color.rgb = RGBColor(0xc0, 0x39, 0x2b)
    p = doc.add_paragraph(body_text)
    p.runs[0].font.size = Pt(10)

add_rule(doc)
doc.add_paragraph()

# ── Sản phẩm ổn ────────────────────────────────────────────────────────────────
doc.add_heading('Không Cần Lo Ngay', level=2)

tbl2 = doc.add_table(rows=1, cols=3)
tbl2.style = 'Table Grid'
for cell, text in zip(tbl2.rows[0].cells, ['Sản phẩm (Platform)', 'Pass Rate', 'Ghi chú']):
    cell.text = text
    cell.paragraphs[0].runs[0].bold = True
    cell.paragraphs[0].runs[0].font.size = Pt(9.5)

for row_data in [
    ('Apparel', '98.0%', 'Ổn'),
    ('Mug',     '95.5%', 'Ổn'),
    ('Tumbler', '98.1%', 'Ổn'),
    ('Garden Flag', '99.0%', 'Volume thấp (n=98)'),
]:
    row = tbl2.add_row()
    for cell, val in zip(row.cells, row_data):
        cell.text = val
        cell.paragraphs[0].runs[0].font.size = Pt(9.5)

doc.add_paragraph()
p = doc.add_paragraph(
    'Standard Poster (90.9%, n=2,266) — sát ngưỡng nhưng đạt. Theo dõi tháng tới.'
)
p.runs[0].font.size = Pt(10)

add_rule(doc)
doc.add_paragraph()

# ── Nguyên nhân ────────────────────────────────────────────────────────────────
doc.add_heading('Nguyên Nhân Gốc Rễ', level=2)

p = doc.add_paragraph('Carrier handoff là bottleneck chủ đạo — không phải khâu sản xuất.')
p.runs[0].bold = True
p.runs[0].font.size = Pt(10)

p2 = doc.add_paragraph(
    'Hầu hết sản phẩm có avg_production ≈ 0.6–1.3 ngày (tốt). '
    'Thời gian từ khi xuất kho đến carrier scan mới là nơi đơn bị tắc.'
)
p2.runs[0].font.size = Pt(10)

doc.add_paragraph()
doc.add_heading('Câu hỏi cần ops trả lời:', level=3)
questions = [
    'CA — tần suất carrier pickup hiện tại là bao nhiêu? Có thể tăng không?',
    'Doormat — carrier nào đang handle? Có thể chuyển sang carrier có pickup linh hoạt hơn?',
    'Sticker tháng 2 giảm so với tháng 1? (Cần check trend riêng nếu muốn)',
]
for q in questions:
    p = doc.add_paragraph(style='List Number')
    p.text = ''
    p.add_run(q).font.size = Pt(10)

add_rule(doc)

# ── Footer ─────────────────────────────────────────────────────────────────────
doc.add_paragraph()
footer_texts = [
    'Nguồn: gea__silver.fact_order_fulfillment_performance_by_product FINAL',
    'TAL = floor(processing_day + first_scan_day) biz days',
    'Chỉ hiển thị sản phẩm có ≥ 100 đơn trong kỳ',
    'CA = HB1 + HB2 (cùng ops lead California)',
    'Ngưỡng 90% là tham khảo nội bộ, chưa phải KPI chính thức',
]
for item in footer_texts:
    p = doc.add_paragraph(style='List Bullet')
    p.text = ''
    r = p.add_run(item)
    r.font.size = Pt(8.5)
    r.font.color.rgb = RGBColor(0x77, 0x77, 0x77)

# ── Save ──────────────────────────────────────────────────────────────────────
doc.save(OUT)
print(f'Saved: {OUT}')

# Luồng Báo Cáo SLA — Từ BOD đến Ops

> Tài liệu này giải thích cách 2 báo cáo SLA kết nối với nhau, ai đọc gì, khi nào escalate, và ops team báo cáo lại thế nào.

---

## Tổng Quan

Hệ thống báo cáo SLA gồm 2 tầng:

| Tầng | Báo cáo | Audience | Câu hỏi trả lời | Tần suất |
|---|---|---|---|---|
| **L1 — BOD** | Order SLA | BOD, leadership | Tháng này đạt bao nhiêu? Trend đi đâu? | Hàng tháng |
| **L2 — Ops** | Ops SLA Drilldown | Ops team | Xưởng nào? Sản phẩm nào? Nguyên nhân gì? | Khi được escalate |

**Nguyên tắc:** BOD không drill down. Ops không báo cáo aggregate. Hai tầng bổ sung nhau — không thay thế nhau.

---

## Luồng Đọc và Hành Động

```
┌──────────────────────────────────────────────────────────────────┐
│  BOD đọc: Order SLA Dashboard (hàng tháng)                      │
│                                                                  │
│  Phần 1 — Scorecard: Platform XX% ▲/▼ · Standard XX% ▲/▼        │
│  Phần 2 — Trend 12 tháng: đang tốt lên hay xấu đi?             │
└──────────────────────┬───────────────────────────────────────────┘
                       │
          ┌────────────┴────────────┐
          │                         │
     Tình hình ổn              Cần escalate
   (xem tiêu chí dưới)       (xem tiêu chí dưới)
          │                         │
          ▼                         ▼
   Không cần action         Chuyển sang Ops:
   Ghi nhận, theo dõi       "Tháng X: [nhóm] drop [Y]pp
   tháng tới                → cần drill-down"
                                     │
                                     ▼
              ┌──────────────────────────────────────────┐
              │  Ops đọc: Ops SLA Drilldown              │
              │                                          │
              │  Bước 1 — Xưởng nào đang chậm? (CA/TX1) │
              │  Bước 2 — Sản phẩm nào cần ưu tiên?     │
              │  Bước 3 — Nguyên nhân? (carrier/sản xuất)│
              └──────────────────────┬───────────────────┘
                                     │
                                     ▼
              ┌──────────────────────────────────────────┐
              │  Ops báo cáo lại BOD (dùng template)    │
              │  — Vấn đề ở đâu                         │
              │  — Đang làm gì                          │
              │  — Expect kết quả tháng nào             │
              └──────────────────────────────────────────┘
```

---

## BOD — Khi Nào Escalate?

### Escalate ngay (tháng này)

| Điều kiện | Ví dụ |
|---|---|
| Bất kỳ nhóm nào < 85% | Platform 82% tháng này |
| Drop > 10pp so với tháng trước | Standard 96% → 85% |
| Cả 2 nhóm cùng drop trong 1 tháng | Pattern Dec 2025 lặp lại |

### Theo dõi sát (tháng tới)

| Điều kiện | Ví dụ |
|---|---|
| Bất kỳ nhóm nào drop 5–10pp | Platform 96% → 91% |
| Nhóm nào đang trending down 2 tháng liên tiếp | Standard giảm liên tục |
| Pass rate phục hồi nhưng volume tăng mạnh | Tháng cao điểm đang đến |

### Không cần action

Cả 2 nhóm ≥ 90% và delta ≥ −3pp so với tháng trước.

---

## Ops — Cách Đọc Drilldown

Đọc theo thứ tự Bước 1 → 2 → 3 trong dashboard. Mỗi bước trả lời 1 câu hỏi và dẫn đến bước tiếp theo:

**Bước 1 — Xưởng nào chậm?**
Xác định facility cần focus (CA hay TX1). Nếu cả 2 đều thấp → vấn đề systemic, không phải facility-specific.

**Bước 2 — Sản phẩm nào ưu tiên?**
Trong facility đó, sản phẩm nào pass rate thấp nhất + volume đủ lớn? Ưu tiên theo impact = (1 − pass_rate) × volume.

**Bước 3 — Nguyên nhân gì?**
Bar chart stacked: nếu phần xanh (carrier) cao → carrier handoff lag. Nếu phần cam (sản xuất) cao → production bottleneck.
- **Carrier lag** → action: tần suất pickup, đổi carrier, kiểm tra handoff process
- **Production chậm** → action: capacity, quy trình sản xuất, staffing

---

## Template Báo Cáo Từ Ops Lên BOD

Dùng format ngắn sau khi đã drill-down:

```
Ops SLA Update — Tháng [X/XXXX]

Vấn đề xác định:
- [Facility]: [Sản phẩm] — pass rate [X]%, nguyên nhân [carrier/sản xuất]
- (nếu có thêm)

Đang xử lý:
- [Hành động cụ thể đang làm]
- [Timeline dự kiến]

Kỳ vọng:
- Tháng [X+1]: pass rate [Facility/Sản phẩm] cải thiện lên ~[X]%
- Nếu không cải thiện: cần leo thang thêm về [carrier contract / ops process]

Cần BOD support:
- [Nếu có — ví dụ: ngân sách đổi carrier, tăng headcount]
- Không có gì nếu ops tự xử lý được
```

---

## Lịch Vận Hành

| Thời điểm | Ai | Hành động |
|---|---|---|
| Đầu tháng (ngày 3–5) | Data team | Refresh CSV, re-export dashboard 2 báo cáo |
| Đầu tháng (ngày 5–7) | BOD | Đọc Order SLA Dashboard — quyết định escalate hay không |
| Ngày 7–10 (nếu escalate) | Ops | Đọc Ops Drilldown, xác định root cause |
| Ngày 10–12 (nếu escalate) | Ops → BOD | Gửi Ops Update theo template trên |
| Cuối tháng | Ops | Check progress — có đúng hướng không? |

---

## Files Tham Chiếu

| File | Mô tả |
|---|---|
| `order-sla/exports/dashboard.png` | BOD dashboard — đọc hàng tháng |
| `order-sla/exports/order-sla-summary.docx` | DOCX version để share |
| `order-sla/bod-summary.md` | Ghi chú chi tiết kèm câu hỏi gợi ý cho BOD |
| `ops-sla-drilldown/exports/dashboard.png` | Ops drilldown — đọc khi escalate |
| `ops-sla-drilldown/exports/ops-sla-summary.docx` | DOCX version để share |
| `ops-sla-drilldown/ops_summary.md` | Action items cụ thể cho tháng gần nhất |

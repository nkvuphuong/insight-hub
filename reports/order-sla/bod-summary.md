# Order SLA — BOD Summary (Mar 2026)

> Đọc theo cùng thứ tự với dashboard: `exports/dashboard.png`
> Tháng mới nhất trong data: **2026-03** (có thể chưa hoàn chỉnh — tháng gần nhất hoàn chỉnh: Feb 2026)

---

## Phần 1 — Tháng Này Như Thế Nào?

| Nhóm | SLA Pass Rate | vs Tháng Trước | n đơn | Tình trạng |
|---|---|---|---|---|
| Platform (Ship by Seller) | **96.4%** | ▲ +5.5% | 5,481 | Tốt ✓ |
| Standard (Ship by Gearment) | **96.3%** | ▲ +2.3% | 2,429 | Tốt ✓ |

SLA cam kết: Platform ≤ 3 biz days · Standard ≤ 4 biz days.

*(\*) Standard: chỉ tính đơn có tracking data (first_scan IS NOT NULL). ~36% đơn không có tracking — nằm ngoài denominator, không phải SLA fail.*

### Action tháng này

> **Không cần escalate.** Cả 2 nhóm đang tăng và đạt mức cao nhất trong data.
> Tiếp tục theo dõi tháng tới — đặc biệt chú ý nếu bất kỳ nhóm nào giảm quá 5pp so với tháng này.

Platform: ~197 đơn không đạt SLA tháng này (≈3.6% × 5,481). Nếu cần biết nhóm sản phẩm / xưởng nào → xem **Ops SLA Drilldown** (`reports/ops-sla-drilldown/exports/dashboard.png`).

---

## Phần 2 — Xu Hướng Đang Đi Đâu?

**Tình hình tốt:** Recovery liên tục 3 tháng (Jan–Mar 2026) sau đáy Dec 2025. Cả 2 nhóm đang ở mức cao nhất kể từ khi có data.

**Điểm cần lưu ý:**

| Giai đoạn | Sự kiện | Platform | Standard |
|---|---|---|---|
| Dec 2025 | Holiday peak — overload toàn hệ thống | **41.9%** (đáy) | **68.6%** (đáy) |
| Jan–Mar 2026 | Recovery rõ ràng | 89% → 91% → 96.4% | 96% → 94% → 96.3% |
| Aug–Oct 2025 | Standard volume thấp bất thường | — | 1–2K đơn/tháng (vs bình thường 14–72K) |

**Chuẩn bị Dec 2026:** Dec 2025 là outlier rõ nhất trong toàn bộ data. Nên lên kế hoạch ops capacity trước ít nhất 1 tháng.

---

## Câu Hỏi Dashboard Này Trả Lời

| Câu hỏi | Trả lời |
|---|---|
| Tháng này đạt SLA bao nhiêu %? | Platform 96.4% · Standard 96.3% |
| Tốt lên hay xấu đi? | Cả 2 đang tăng (▲2–6%) |
| Trend 12 tháng? | Recovery sau đáy Dec 2025 — tốt dần |
| Khi nào tệ nhất? | Dec 2025 — holiday overload cả 2 nhóm |
| Cần escalate không? | Không — tháng này ổn |

## Câu Hỏi Cần Báo Cáo Khác

| Câu hỏi | Ở đâu |
|---|---|
| Tại sao thấp? Xưởng / sản phẩm nào kéo xuống? | **Ops SLA Drilldown** — `reports/ops-sla-drilldown/` |
| Cải thiện ở đâu trước? | **Ops SLA Drilldown** — xem `ops_summary.md` |
| Standard Aug–Oct 2025 volume thấp — có sự kiện gì? | Cần xác nhận với ops |
| Internal target là bao nhiêu? | Chưa có — team cần propose target % |

---

## Câu Hỏi Gợi Ý Cho BOD Review

1. **Số liệu có phản ánh đúng thực tế không?** Ops team có thể xác nhận Dec 2025 thực sự overload không?
2. **Standard volume Aug–Oct 2025 rất thấp** (1–2K vs bình thường 14–72K) — có sự kiện gì không? Ảnh hưởng đến tính đại diện của trend?
3. **Internal target là bao nhiêu?** Hiện chưa có benchmark — dùng trend để đánh giá. Team đề xuất target % để đưa vào dashboard?
4. **Chuẩn bị Dec 2026:** Ops cần plan capacity tăng cường từ bao giờ?

---

## Context Kỹ Thuật (Không Cần Đọc)

- Data source: `gea__silver.fact_order_fulfillment_performance FINAL`
- Platform: `is_platform = 1`, SLA = `floor(processing_day + first_scan_day) ≤ 3`
- Standard: `is_platform = 0`, SLA = `floor(processing_day + first_scan_day) ≤ 4`
- TAL = Tracking Active Lead = payment → first carrier scan (biz days)
- Period: 12 tháng gần nhất, grain tháng · Lọc tháng < 30 đơn
- Platform data available từ Aug 2025 · Standard từ Mar 2025

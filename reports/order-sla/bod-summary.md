# Order SLA — BOD Summary (Mar 2026)

## Tình Hình Tháng Này

| Nhóm | SLA Pass Rate | vs Tháng Trước |
|---|---|---|
| Platform (Ship by Seller) | **96.4%** | ▲ +5.5% |
| Standard (Ship by Gearment) | **96.3%** | ▲ +2.3% |

SLA cam kết: Platform ≤ 3 biz days, Standard ≤ 4 biz days.

*(*) Chỉ tính đơn có tracking data. Standard ~36% đơn không có tracking — nằm ngoài denominator.*

---

## Trend 12 Tháng — Tóm Tắt

**Tình hình tốt:** Cả 2 nhóm đang ở mức cao nhất kể từ khi có data (96%+), và đang cải thiện liên tục 3 tháng gần nhất.

**Điểm cần lưu ý:**
- **Dec 2025:** Cả 2 nhóm drop mạnh — Platform 41.9%, Standard 68.6%. Đây là đáy thấp nhất trong toàn bộ data. Pattern holiday overload (cuối năm) — cần chuẩn bị trước cho Dec 2026.
- **Jan–Mar 2026:** Recovery rõ ràng. Platform tăng từ 41.9% → 96.4% (+54.5pp trong 3 tháng).

---

## Phạm Vi Câu Hỏi — Report Này Trả Lời Được Gì?

### Đã trả lời

| Câu hỏi | Trả lời |
|---|---|
| Tháng này đang đạt SLA bao nhiêu %? | Platform 96.4%, Standard 96.3% |
| Tốt lên hay xấu đi so với tháng trước? | Cả 2 đang tăng (▲2–6%) |
| Trend 12 tháng đi theo hướng nào? | Recovery sau đáy Dec 2025 — tốt dần |
| Khi nào tệ nhất? | Dec 2025 — cả 2 nhóm cùng drop (holiday overload) |
| Nhóm nào vi phạm nặng hơn? | Dec 2025: Platform (41.9%) tệ hơn Standard (68.6%) |

### Chưa trả lời — và vì sao

**"Tại sao pass rate thấp?"**
Chưa trả lời. Report chỉ cho thấy *kết quả* (pass/fail), không breakdown nguyên nhân. Để biết nguyên nhân cần phân tích thêm: production time chiếm bao nhiêu trong TAL, tracking lag chiếm bao nhiêu. Data đã có (`production_pass_rate`, `avg_tal_days`) nhưng chưa visualize.

**"Cải thiện ở đâu trước?"**
Chưa trả lời. Để ưu tiên cần breakdown theo segment: fulfillment location nào / country nào đang kéo pass rate xuống. Report hiện tại chỉ có aggregate toàn bộ — không drill-down được.

**"Đây có phải xu hướng dài hạn hay sự kiện nhất thời?"**
Trả lời một phần. 12 tháng trend cho thấy Dec 2025 là outlier rõ ràng. Nhưng Standard volume tháng 8–10/2025 rất thấp (1–2K vs bình thường 14–72K) — cần xác nhận từ ops xem có sự kiện gì không, trước khi kết luận trend.

### Tại sao 2 câu hỏi trên chưa được đưa vào?

Report này được thiết kế cho **BOD (≤30s scan)**, không phải ops team. Workflow là:
- BOD thấy pass rate xấu → **escalate xuống ops**
- Ops tự drill-down bằng query trực tiếp

Breakdown segment và contribution analysis là **ops-level** — đưa vào BOD view làm phức tạp thêm, không có giá trị cho quyết định ở cấp này. Nếu cần, sẽ build thêm ops dashboard riêng sau khi BOD confirm report này phù hợp.

---

## Câu Hỏi Gợi Ý Cho BOD Review

1. **Số liệu có phản ánh đúng thực tế không?** Ops team có thể xác nhận Dec 2025 thực sự overload không?
2. **Internal target là bao nhiêu?** Hiện tại chưa có benchmark — dùng trend để evaluate. Team đề xuất target % để đưa vào dashboard?
3. **Platform ~4% đơn không đạt SLA tháng này (≈220 đơn)** — có cần drill-down không?
4. **Standard volume tháng 8–10/2025 rất thấp** (1–2K vs bình thường 14–72K) — có sự kiện gì không?

---

## Context Kỹ Thuật (Không Cần Đọc)

- Data source: `gea__silver.fact_order_fulfillment_performance FINAL`
- Platform: `is_platform = 1`, SLA = `floor(processing_day + first_scan_day) ≤ 3`
- Standard: `is_platform = 0`, SLA = `floor(processing_day + first_scan_day) ≤ 4`
- Period: 12 tháng gần nhất, grain tháng
- Platform data available từ Aug 2025 (Standard từ Mar 2025)

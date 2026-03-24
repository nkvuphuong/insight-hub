# Ops SLA — Tháng 2/2026: Cần Fix Gì Trước?

> Dùng để share với ops team trước buổi review. Dữ liệu: `gea__silver.fact_order_fulfillment_performance_by_product`, chỉ đơn có tracking data.

---

## Kết quả tổng quan

| Nhóm     | CA (California) | TX1 (Texas) |
|----------|-----------------|-------------|
| Platform | **84.1%** ⚠️    | 93.4% ✓     |
| Standard | 90.9% ✓         | 98.0% ✓     |

CA đang kéo SLA chung xuống. TX1 là chuẩn so sánh.

---

## Ưu tiên xử lý (theo impact)

### 🔴 Fix #1 — Platform CA: Poster (n=1,573, pass=84.1%)

**Vấn đề:** Carrier handoff chậm — avg_scan=1.44 ngày tại CA vs 0.72 ngày tại TX1 (xấp xỉ, tính theo data TX1 Sticker).

**Action:** Kiểm tra lịch carrier pickup tại CA. Có đơn bị tồn kho chờ scan không? So sánh carrier performance CA vs TX1.

---

### 🔴 Fix #2 — Platform TX1: Doormat (n=310, pass=82.3%)

**Vấn đề:** avg_tal=3.03 ngày (SLA ≤3) — vượt ngưỡng. Carrier handoff là chính: avg_scan=2.41 ngày, sản xuất chỉ 0.62 ngày.

**Action:** Doormat có kích thước lớn — carrier pickup có bị delay không? Cần package đặc biệt không làm chậm handoff?

---

### 🟡 Theo dõi — Platform: Sticker (n=2,958, pass=89.2%)

**Vấn đề:** Borderline (dưới 90% tham khảo). Volume cao nhất. avg_scan=1.50 ngày.

**Action:** Chưa cần escalate ngay nhưng cần giữ mắt — nếu tiếp tục giảm sang tháng 3 thì prioritize.

---

### ✅ Không cần lo ngay

| Platform   | Pass rate | Ghi chú              |
|------------|-----------|----------------------|
| Apparel    | 98.0%     | Ổn                   |
| Mug        | 95.5%     | Ổn                   |
| Tumbler    | 98.1%     | Ổn                   |
| Garden Flag| 99.0%     | Volume thấp (n=98)   |

Standard Poster (90.9%, n=2,266) — sát ngưỡng nhưng đạt. Theo dõi tháng tới.

---

## Nguyên nhân gốc rễ

> Carrier handoff là bottleneck chủ đạo — không phải khâu sản xuất.

Hầu hết sản phẩm có avg_production ≈ 0.6–1.3 ngày (tốt). Thời gian từ khi xuất kho đến carrier scan mới là nơi đơn bị tắc.

**Các câu hỏi cần ops trả lời:**
1. CA — tần suất carrier pickup hiện tại là bao nhiêu? Có thể tăng không?
2. Doormat — carrier nào đang handle? Có thể chuyển sang carrier có pickup linh hoạt hơn?
3. Sticker tháng 2 giảm so với tháng 1? (Cần check trend riêng nếu muốn)

---

*Nguồn: `ops_sla_drilldown` POC — Phuong, 2026-03-24*
*Dashboard đầy đủ: `reports/ops-sla-drilldown/exports/dashboard.png`*

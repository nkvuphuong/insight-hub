## 1. Discovery → Spec Confirmed [gate: done via explore session]

- [x] 1.1 Explore distinct values: `shipping_class`, `ordx_fulfill_locate`, `country_code` qua MCP
- [x] 1.2 Confirm SLA metric chính: TAL = paid → first scan (biz days)
- [x] 1.3 Confirm SLA thresholds: Platform ≤ 3 biz days, Standard ≤ 4 biz days
- [x] 1.4 Confirm grouping: Platform (shipping_class = 'Other') vs Standard (≠ 'Other') → revised sau: dùng presence trong v__usps_paided làm source of truth (xem D2)
- [x] 1.5 Confirm data sources: fact_ofp + v__usps_paided + v__usps_fulfilled_to_first_scan
- [x] 1.6 Confirm đơn vị: biz days, ceil(processing_day) để đồng bộ
- [x] 1.7 Update design.md với tất cả decisions

## 2. Setup [gate: Phuong confirm spec-confirmed]

- [x] 2.1 Tạo folder `reports/order-sla/queries/` và `reports/order-sla/changelog.md`
- [x] 2.2 Cập nhật bảng "Danh Sách Báo Cáo" trong `CLAUDE.md`

## 3. SQL — Viết và Verify qua MCP [gate: sql-verified]

- [x] 3.1 Viết `reports/order-sla/queries/sla_standard.sql` — Standard group: TAL pass rate theo tháng (output đủ cột để debug, viz chỉ dùng tal_pass_rate + MoM delta)
- [x] 3.2 Verify `sla_standard.sql` qua MCP — kiểm tra row count, pass rate range hợp lý
- [x] 3.3 Viết `reports/order-sla/queries/sla_platform.sql` — Platform group: JOIN fact_ofp + v__usps_paided, TAL pass rate theo tháng
- [x] 3.4 Verify `sla_platform.sql` qua MCP

## 4. POC Visualization [gate: poc-done]

Audience: BOD — ≤30s scan. 2 views thay vì 3 charts.

- [x] 4.1 Tạo `reports/order-sla/poc.ipynb` từ template — load CSVs vào DataFrames
- [x] 4.2 View 1 — Scorecard: pass rate tháng hiện tại + MoM delta (↑/↓) cho Platform và Standard
       — footnote: "(*) Chỉ tính đơn có tracking data" cho Standard
- [x] 4.3 View 2 — Trend: line chart TAL pass rate 12 tháng — Platform vs Standard (2 lines, TAL only)
- [x] 4.4 Tạo `reports/order-sla/export.py` — export PNGs cho 2 views
- [x] 4.5 Ghi `reports/order-sla/changelog.md` — entry v0.1 poc-done
- [x] 4.6 Ghi entry vào `docs/CHANGELOG.md`

## 5. Biz Validation [gate: biz-validated]

- [x] 5.1 Chuẩn bị summary cho BOD: "Platform và Standard đang đạt SLA bao nhiêu %? Trend đang tốt lên hay xấu đi?"
- [ ] 5.2 BOD review — thu thập feedback: số liệu có phản ánh đúng thực tế không? Team propose internal target %?
- [ ] 5.3 Ghi feedback từ BOD review vào `changelog.md`
- [ ] 5.4 Điều chỉnh chart nếu có feedback — re-export PNG

## 6. SQL Refactor [gate: sql-refactored — 2026-03-23 | depends: enrich-fact-ofp-platform]

Đơn giản hóa SQL sau khi `fact_order_fulfillment_performance` đã có `is_platform` và `first_scan_day` đúng.

- [x] 6.1 Rewrite `sla_standard.sql` — `WHERE is_platform = 0`, bỏ `LEFT ANTI JOIN v__usps_paided`
- [x] 6.2 Rewrite `sla_platform.sql` — `WHERE is_platform = 1 AND first_scan_day IS NOT NULL`, dùng `floor(processing_day + first_scan_day)` thay vì join `v__usps_paided_to_first_scan_days`
- [x] 6.3 Verify cả 2 queries qua MCP — Standard khớp v0.3 hoàn toàn; Platform counts khớp, pass_rate cao hơn +2–9% do formula thay đổi (expected)
- [x] 6.4 Update CSV cache (v0.4)
- [x] 6.5 Update `design.md` — D3 revised: unified fact source, bỏ join pattern cũ
- [x] 6.6 Ghi `changelog.md` v0.4

SQL sau refactor (simplified):

```sql
-- Standard: đơn GM mua label
SELECT ... FROM gea__silver.fact_order_fulfillment_performance FINAL
WHERE is_platform = 0
  AND paid_at_utc >= toStartOfMonth(now() - INTERVAL 12 MONTH)
  AND first_scan_day IS NOT NULL

-- Platform: USPS label by customer
SELECT ... FROM gea__silver.fact_order_fulfillment_performance FINAL
WHERE is_platform = 1
  AND paid_at_utc >= toStartOfMonth(now() - INTERVAL 12 MONTH)
```

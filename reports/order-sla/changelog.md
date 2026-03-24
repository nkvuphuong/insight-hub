# Changelog — order-sla

## v0.4 — 2026-03-23 — sql-refactored (unified fact source)

### Summary
Rewrite cả 2 SQL queries để dùng `is_platform` flag thay vì join `v__usps_paided_to_first_scan_days`. Unblock Gate 6 sau khi `enrich-fact-ofp-platform` hoàn tất.

### Design change
- **Standard:** Thay `LEFT ANTI JOIN v__usps_paided` → `WHERE is_platform = 0`. Đơn giản hơn, không còn dependency vào view phức tạp.
- **Platform:** Thay join `v__usps_paided_to_first_scan_days` → `WHERE is_platform = 1 AND first_scan_day IS NOT NULL`. Formula TAL đổi từ `business_days_exclude_payment` → `floor(processing_day + first_scan_day)` (unified với Standard).

### Verification
- **Standard:** Numbers khớp v0.3 hoàn toàn (±1–4 orders, ±0.1% pass rate) ✓
- **Platform:** total_orders khớp v0.3 (~±100 orders). Pass rate cao hơn +2–9% — expected do formula khác (`floor(sum)` vs `business_days_exclude_payment`). Trend direction nhất quán (Dec 2025 vẫn là đáy).

### Files updated
- `queries/sla_standard.sql` — `WHERE is_platform = 0`, bỏ LEFT ANTI JOIN, subquery pattern
- `queries/sla_platform.sql` — `WHERE is_platform = 1`, `floor(processing_day + first_scan_day)`
- `queries/sla_standard.csv` — re-cached v0.4
- `queries/sla_platform.csv` — re-cached v0.4
- `openspec/changes/order-sla/design.md` — D3 revised: unified fact source

---

## v0.3 — 2026-03-20 — poc-done (Standard TAL formula correction)

### Summary
Align Standard TAL về cùng convention với Platform: `floor(processing_day + first_scan_day)` thay vì `ceil(processing_day) + first_scan_day`.

### Design change
- **Root cause:** `ceil(processing_day)` overstates production time — processing 3.1 ngày bị round lên 4, dẫn đến Standard pass rate thấp hơn thực tế đáng kể.
- **Convention đúng (e-commerce SLA):** days elapsed, payment = Day 0 (không tính). Đây là convention của Platform (`business_days_exclude_payment`, floor-rounded integer).
- **Fix:** `floor(processing_day + first_scan_day)` — tổng fractional biz days rồi floor → integer days elapsed, đồng bộ 2 nhóm.

### Impact
Standard pass rate tăng ~10–30% tùy tháng. Dec 2025: 43.5% → 68.6%. Mar 2026: 84.2% → 96.2%.

### Files updated
- `queries/sla_standard.sql` — TAL formula: ceil+add → floor(sum)
- `queries/sla_standard.csv` — re-cached với formula mới
- `openspec/changes/order-sla/design.md` — D3, D4 updated

---

## v0.2 — 2026-03-20 — poc-done (data correction)

### Summary
Phát hiện và sửa Platform CSV sai do MCP partial result. Re-export PNGs với data đúng.

### Data correction
- **Root cause:** `SELECT count() FROM v__usps_paided_to_first_scan_days` trả 16,025 (partial shard scan) thay vì 143,562 (actual). Dẫn đến nhận định sai "Platform chỉ có data từ Feb 2026".
- **Thực tế:** Platform có ~25K–30K orders/tháng từ Aug 2025. Data đầy đủ 8 tháng (Aug 2025 – Mar 2026).
- **Fix:** Re-run Platform query với aggregate để verify count → cập nhật CSV → re-export PNG.

### Data findings (corrected)
- **Standard:** Pass rate dao động 43–93% trong 12 tháng. Đáy Dec 2025 (43.5%).
- **Platform:** Pass rate 80–92% hầu hết tháng. Đáy Dec 2025 (33.3%) — cùng pattern với Standard, likely holiday overload.
- **Dec 2025:** Cả 2 nhóm đều drop mạnh — tín hiệu rõ để BOD discuss.

### Caveat ghi nhận
`count()` trên `v__usps_paided_to_first_scan_days` không tin cậy — dùng `uniqExact()` hoặc aggregate query để verify row count (đã cập nhật vào design.md).

---

## v0.1 — 2026-03-20 — poc-done

### Summary
POC hoàn thành. 2 SQL queries verified qua MCP, 2 views implemented trong `poc.ipynb`.

### Design decisions ghi nhận
- **Platform definition thay đổi:** Không dùng `shipping_class = 'Other'` mà dùng presence trong `v__usps_paided_to_first_scan_days` làm source of truth. Lý do: `v__usps_paided` chứa cả Standard và Other shipping class.
- **Standard query:** Dùng `LEFT ANTI JOIN v__usps_paided` thay vì `shipping_class != 'Other'`.
- **Join pattern:** `FINAL + JOIN` trực tiếp gây timeout MCP trên bảng lớn → tách FINAL vào subquery.

### Files
- `queries/sla_standard.sql` — Standard group: LEFT ANTI JOIN v__usps_paided
- `queries/sla_platform.sql` — Platform group: v__usps_paided driving (~143K rows)
- `queries/sla_standard.csv` — Data cache (13 months)
- `queries/sla_platform.csv` — Data cache (8 months, Aug 2025 – Mar 2026)
- `poc.ipynb` — Scorecard + Trend views (Plotly)
- `export.py` — Export PNG: scorecard + trend
- `exports/order-sla-scorecard.png` — Standard 83.9% ▲7.4%, Platform 92.6% ▲6.3% (Mar 2026)
- `exports/order-sla-trend.png` — Trend 12 tháng, đáy Dec 2025 cả 2 nhóm

# Changelog

Mục lục thay đổi toàn dự án. Mỗi entry = 1 dòng tóm tắt + link đến detail (nếu có).

**Scope:** `[setup]` · `[schema]` · `[<report-folder>]`

**Quy tắc ghi index:**
- Tóm tắt ≤ 15 từ — trả lời "thay đổi gì", không cần "như thế nào"
- `[setup]`: không cần pointer (ít thay đổi, inline đủ)
- `[schema]`: pointer đến file schema cụ thể (hoặc thư mục nếu nhiều db cùng lúc)
- `[report]`: pointer đến `changelog.md` của báo cáo đó
- Nhiều thay đổi cùng ngày cùng scope → gộp nếu liên quan, tách nếu độc lập

---

## 2026-03

### Setup
- [2026-03-19] Migrate spec.md → openspec/changes/design.md, xóa reports/spec.md, update CLAUDE.md flow
- [2026-03-19] Migrate workflow sang OpenSpec: config.yaml, changes/order-performance/, gọn CLAUDE.md ~50%
- [2026-03-13] Khởi tạo dự án: thư mục, templates, CLAUDE.md
- [2026-03-16] Restructure: gom báo cáo vào `reports/`, cập nhật CLAUDE.md + README
- [2026-03-17] Thêm `_templates/schema_template.md`, flow explore schema vào CLAUDE.md
- [2026-03-17] Restructure CHANGELOG thành index + pointers, cập nhật quy tắc ghi trong CLAUDE.md
- [2026-03-17] Tạo docs/data-map.md — cross-DB context (domain map, entity map, join paths, lineage)

### Schema
- [2026-03-14] Document toàn bộ Silver/Bronze (100% databases) → [docs/schema/](./schema/)
- [2026-03-14] gea__silver: sửa descriptions cho processing_hour/day, first_scan_hour/day, shipping_hour/day → [gea__silver.md](./schema/gea__silver.md)
- [2026-03-17] gea_wms__bronze: explore 60 tables, WMS domain (mới) → [gea_wms__bronze.md](./schema/gea_wms__bronze.md)
- [2026-03-17] geadb__bronze: +2 tables (nh_creation_methods, nh_platforms), 57→59 → [geadb__bronze.md](./schema/geadb__bronze.md)
- [2026-03-17] gea__silver: bổ sung column detail cho 9 views → [gea__silver.md](./schema/gea__silver.md)
- [2026-03-19] geadb__bronze: +2 tables mới (nh_reality_tracking, nh_shipping_zones), 59→61 → [geadb__bronze.md](./schema/geadb__bronze.md)
- [2026-03-23] gea_silver: fix v_shipx_rate_comparison duplicate — SCD filter shipx phải ở WHERE, không ON → [gea_silver.md](./schema/gea_silver.md)
- [2026-03-24] gea__silver: +is_platform vào fact_ofp + fact_ofp_by_product; +8 tables mới (dict/dim); fact_order_v1/v3 không còn tồn tại → [gea__silver.md](./schema/gea__silver.md)

### Reports
- [2026-03-24] ops-sla-drilldown: poc-done (v0.1) — 4 charts, drill-down L1→L4, HB1/HB2 production bottleneck confirmed → [changelog](../reports/ops-sla-drilldown/changelog.md)
- [2026-03-23] order-sla: sql-refactored (v0.4) — unified is_platform flag, bỏ v__usps_paided join → [changelog](../reports/order-sla/changelog.md)
- [2026-03-24] enrich-fact-ofp-by-product: done — +is_platform + COALESCE USPS tracking timestamps cho fact_ofp_by_product → [tasks](../openspec/changes/enrich-fact-ofp-by-product/tasks.md)
- [2026-03-23] enrich-fact-ofp-platform: Step 2 done — +COALESCE first_scanned_at/delivered_at từ USPS tracking cho Platform → [design](../openspec/changes/enrich-fact-ofp-platform/design.md)
- [2026-03-23] enrich-fact-ofp-platform: Step 1 done — +is_platform (UInt64) vào fact_ofp + MV → [design](../openspec/changes/enrich-fact-ofp-platform/design.md)
- [2026-03-20] enrich-fact-ofp-platform: new change — redesign từ +platform_tal_days → unified is_platform từ nh_order_source → [design](../openspec/changes/enrich-fact-ofp-platform/design.md)
- [2026-03-20] order-sla: +Gate 6 sql-refactored (depends enrich-fact-ofp-platform) → [tasks](../openspec/changes/order-sla/tasks.md)
- [2026-03-20] order-sla: poc-done (v0.3) — align Standard TAL formula: floor(sum) vs ceil+add, +10–30% pass rate → [changelog](../reports/order-sla/changelog.md)
- [2026-03-20] order-sla: spec-confirmed → poc-done (v0.2) — Platform definition redesign, data correction (MCP partial count) → [changelog](../reports/order-sla/changelog.md)
- [2026-03-19] order-performance: v1.1 — redesign 2-metric framework (SLA Rate + Stacked), dashboard executive view → [changelog](../reports/order-performance/changelog.md)
- [2026-03-19] order-performance: biz-validated → v1.0 — SLA research, Chart 07, distribute → [changelog](../reports/order-performance/changelog.md)
- [2026-03-13..16] order-performance: spec → sql-verified → poc-done (v0.1→v0.18) → [changelog](../reports/order-performance/changelog.md)

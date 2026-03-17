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

### Reports
- [2026-03-13..16] order-performance: spec → sql-verified → poc-done (v0.1→v0.18) → [changelog](../reports/order-performance/changelog.md)

# Changelog

Lịch sử thay đổi toàn dự án Reports POC.

Format: `[YYYY-MM-DD] [report-folder] Mô tả thay đổi`

---

## 2026-03

- [2026-03-13] [setup] Khởi tạo dự án: cấu trúc thư mục, templates, CLAUDE.md
- [2026-03-13] [order-performance] Tạo spec ban đầu
- [2026-03-14] [schema] Explore và document gea_silver (41 tables): enriched views NH/SC, shipping rates, shipments, SLA tracker
- [2026-03-14] [schema] Document gea__silver_staging (7 tables): USPS SLA views. Confirm gea_wms__bronze + geadb__silver_staging empty — skip
- [2026-03-14] [schema] Hoàn tất toàn bộ schema exploration — 100% databases covered
- [2026-03-14] [order-performance] Data exploration + viết spec v0.2: xác định data source, metrics SLA, phương pháp percentile/CDF, phát hiện data gap Aug–Oct 2025
- [2026-03-14] [order-performance] spec v0.3→v0.5: restructure metrics framework, verify SQL qua MCP, phát hiện schema note về first_scan_day
- [2026-03-14] [order-performance] spec v0.6: re-verify column definitions, sửa metric formulas dùng processing_day + first_scan_day, thêm filter first_scan_day >= 0. 144 rows, 0 violations. sql-verified.
- [2026-03-14] [order-performance] poc.ipynb tạo ban đầu, sau đó restructure visualization: scope Jan–Feb 2026, CDF đúng format (X=days, Y=cumulative%), bỏ time-series. export.py viết lại hoàn toàn. Status → poc-done.
- [2026-03-14] [schema] Sửa gea__silver.md: correct descriptions cho processing_hour/day, first_scan_hour/day, shipping_hour/day (verified từ data)
- [2026-03-16] [order-performance] Đổi thuật ngữ "CDF" → "Distribution" trong spec/notebook/export — business-friendly language
- [2026-03-16] [setup] Restructure dự án: gom tất cả báo cáo vào `reports/` subfolder. Cập nhật CLAUDE.md + README.md. Xóa rule giữ `queries/*.csv`.

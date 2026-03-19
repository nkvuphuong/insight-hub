# Tasks: Order Performance — biz-validated → production

Current status: `poc-done`
Next gates: `biz-validated` → `production`

## Gate: poc-done → biz-validated

> Phuong confirms với Mr. Sang Do trước khi tiếp.

- [ ] **T1** — Phuong: Schedule review session với Mr. Sang Do để walk through POC charts
- [ ] **T2** — Phuong: Thu thập câu trả lời cho B1–B13 (xem proposal.md)
- [ ] **T3** — Claude: Cập nhật spec.md dựa trên câu trả lời (scope, SLA target, action owner)
- [ ] **T4** — Phuong: Confirm spec đã cập nhật → status = `biz-validated`

## Gate: biz-validated → production (Metabase)

> Chỉ bắt đầu sau khi T4 done.

- [ ] **T5** — Xác định scope production final (charts nào giữ, bỏ, thêm)
- [ ] **T6** — Nếu cần thêm/sửa chart: cập nhật spec → viết SQL → verify qua MCP → update queries/
- [ ] **T7** — Build questions trên Metabase theo `queries/main.sql` (time-series) hoặc snapshot queries
- [ ] **T8** — Phuong: QA Metabase dashboard — số liệu khớp POC?
- [ ] **T9** — Claude: Cập nhật spec.md: status → `production`, điền Metabase link
- [ ] **T10** — Claude: Ghi changelog.md (v1.0) + docs/CHANGELOG.md
- [ ] **T11** — Claude: Cập nhật bảng "Danh Sách Báo Cáo" trong CLAUDE.md

## Backlog (nếu scope expand sau biz-validated)

- SLA Compliance Rate — cần confirm SLA target (đề xuất: 5 biz days = 88.5% Standard US)
- Carrier dimension breakdown (thiếu data/dimension hiện tại)
- Weekly drill-down time-series
- Period comparison (MoM overlay)

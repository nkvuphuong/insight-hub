# Tasks: Order Performance — poc-done → production

Current status: `poc-done`
Gates: `poc-done` → `biz-validated` → `production`

---

## Gate 0: SLA Research (prerequisite cho biz-validated)

> Cần hoàn thành trước khi confirm biz-validated.

- [x] **T0a** — Research TikTok Shop SLA: paid → tracking active (bao nhiêu ngày cam kết với seller?)
- [x] **T0b** — Research SLA các sàn POD liên quan: Amazon, eBay, Etsy (priority theo volume GEA)
- [x] **T0c** — Claude: Update `design.md` với SLA target sau khi có số — thêm vào SLA Compliance Rate formula
- [x] **T0d** — Claude: Re-query MCP với SLA target mới, tính SLA Compliance Rate cho GEA (Standard US, Jan–Feb 2026)

## Gate 1: poc-done → biz-validated

> Phuong confirm với Mr. Sang Do sau khi có SLA research.

- [x] **T1** — Confirm: GEA đang đạt / không đạt SLA target TikTok Shop? Gap cụ thể?
      *(Self-confirmed by Phuong — pending Mr. Sang Do official confirmation. Data: 37.1% đạt SLA 2 BD)*
- [x] **T2** — Confirm: Action owner matrix phù hợp với org structure? (4 teams: Xưởng, Vận hành & PT, Leadership, CS & MKT)
- [x] **T3** — Phuong: Confirm biz-validated → status = `biz-validated`

## Gate 2: biz-validated → production

> Output: analysis report giao cho các team liên quan, không phải self-serve dashboard.

- [x] **T4** — Xác định format output: PNG/CSV cho presentation nhanh + Metabase cho ongoing monitoring
- [x] **T5** — Claude: Build SQL cho SLA Compliance Rate với target đã confirm (`queries/sla.sql`)
- [x] **T6** — Claude: Update `poc.ipynb` / `export.py` — thêm SLA compliance chart, gap visualization
- [ ] **T7** — Phuong: QA output — số liệu khớp POC? SLA gap rõ ràng?
- [ ] **T8** — Distribute analysis report đến 4 teams (format theo T4)
- [ ] **T9** — Claude: Ghi `reports/order-performance/changelog.md` (v1.0)
- [ ] **T10** — Claude: Ghi `docs/CHANGELOG.md`
- [ ] **T11** — Claude: Cập nhật bảng "Danh Sách Báo Cáo" trong CLAUDE.md

## Backlog (sau production nếu scope expand)

- Carrier breakdown — cần thêm dimension carrier vào data pipeline
- MoM trend comparison
- Extend SLA research sang CA, GB (markets GEA serve)

# Proposal: Order Performance — Production & Tracking SLA

## Requestor
Mr. Sang Do (COO) — via Phuong

## Business Audience
- Primary: BOD / leadership (executive overview)
- Secondary: Ops manager, warehouse leads (drill-down by facility)

## Key Question Being Answered

1. **GEA đang ở đâu so với SLA thị trường?** — cụ thể TikTok Shop trước, sau đó các sàn POD lớn khác (Amazon, eBay, Etsy, Shopify)
2. **Làm thế nào để cải thiện?** — xác định bottleneck, giao đúng team chịu trách nhiệm

## Current Status
`poc-done` — POC charts built and verified (Jan–Feb 2026 snapshot).
Đang chờ: SLA research → biz-validated confirmation.

## Output
**Không phải** self-serve dashboard cho stakeholder. Output là **analysis report** giao cho các team liên quan để phân tích và triển khai cải tiến.

## Success Criteria
1. Có SLA benchmark từ TikTok Shop (và các sàn POD liên quan)
2. Biết GEA đang ở đâu so với benchmark — tốt hay xấu, gap bao nhiêu
3. Xác định được bottleneck và giao đúng action owner

## Action Owners

| Metric xấu | Team chịu trách nhiệm | Hành động |
|---|---|---|
| Production Time ↑ | **Xưởng sản xuất** | Tối ưu sản xuất, đóng gói, bàn giao carrier |
| Tracking Lag ↑ (systemic) | **Vận hành & Phát triển** | Cải thiện background ops, handover process |
| Tracking Lag ↑ (carrier/vendor) | **Leadership cấp cao** | Làm việc với carrier partners, giải quyết bottleneck khách quan |
| Customer impact | **CS & MKT** | Hỗ trợ khách hàng xử lý khiếu nại về sản xuất/vận chuyển |

## Validation Questions (simplified)

| # | Câu hỏi | Status |
|---|---------|--------|
| V1 | TikTok Shop SLA target là bao nhiêu ngày (paid → tracking active)? | 🔲 Cần research |
| V2 | SLA các sàn POD khác (Amazon, eBay, Etsy)? | 🔲 Cần research |
| V3 | GEA đang đạt / không đạt SLA target? Gap cụ thể? | 🔲 Sau khi có V1 |
| V4 | Confirm action owner matrix phù hợp với org structure không? | 🔲 Chưa confirm |

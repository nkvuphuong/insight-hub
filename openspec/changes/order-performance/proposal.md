# Proposal: Order Performance — Production & Tracking SLA

## Requestor
Mr. Sang Do (COO) — via Phuong

## Business Audience
- Primary: BOD / leadership (executive overview)
- Secondary: Ops manager, warehouse leads (drill-down by facility)

## Key Question Being Answered
**Seller mất bao lâu từ lúc thanh toán đến khi hàng có tracking active?**

Broken into two components for internal monitoring:
- Production Time (paid → fulfilled) — xưởng performance
- Tracking Lag (fulfilled → first scan) — carrier performance

## Current Status
`poc-done` — POC charts built and verified (Jan–Feb 2026 snapshot). Awaiting business validation before Metabase.

## Success Criteria
1. Leadership can answer: "What is our typical Tracking Active Lead time?"
2. Ops can identify which facility/shipping class is underperforming
3. Dashboard actionable: clear owner when metrics degrade

## Pending Validation (biz-validated gate)

### Mục đích & audience
- B1: Monitor liên tục, review định kỳ, hay one-time?
- B2: Ngoài BOD, ai khác đọc? (Ops manager, warehouse lead?)

### Charts & scope
- B3: Cần filter tự chọn trên Metabase không?
- B4: Cần so sánh 2 period trên cùng 1 chart không?

### Định nghĩa "tốt/xấu" & SLA
- B5: P50 Active Lead = 2.38 biz days, Same-day Scan Rate 45% — ổn hay có vấn đề?
- B6: Có SLA cam kết với seller không?
- B7: Có ngưỡng escalate cụ thể không?

### Impact & actionability
- B8: Khi Production Time tăng / Tracking Lag cao: ai chịu trách nhiệm?
- B9: Tracking Lag — GM có thể tác động được không?
- B10: Sau khi xem dashboard, workflow tiếp theo là gì?

### Specific
- B11: POC có 7 charts — confirm scope production (giữ nguyên / bớt / bổ sung)?
- B12: Same-day Scan Rate 45% — vấn đề hay baseline?
- B13: Cần biết carrier cụ thể nào gây Tracking Lag cao không?

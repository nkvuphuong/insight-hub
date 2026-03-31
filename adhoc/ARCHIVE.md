# Adhoc Archive — Completed & Archived Requests

Tổng hợp các yêu cầu ad-hoc đã hoàn thành. Source of truth = **ClickUp task description + comments**, không cần quay lại git folder.

> **For AI agents:** Tra cứu quick info từ bảng này → ClickUp link để xem chi tiết implementation

---

## Q1 2026 (Archived)

| ID | Task | Requester | Status | Completion | ClickUp Link | Notes |
|---|---|---|---|---|---|---|
| BI-787 | Dopeskill Performance Report | Dopeskill seller (CS) | Done | 2026-03-26 | [BI-787](https://app.clickup.com/t/86ex1g2u1) | 4 queries: volume, processing time, shipping by service, worst cases drilldown |
| BI-789 | Tier Vol Report (Campaign) | CS & BD | Done | 2026-03-26 | [BI-789](https://app.clickup.com/t/86ex1jxdx) | Q1: tier sellers, Q2: standard tier product vol |
| BI-786 | Top 10 Mug Sellers (2024–2025) | CS & BD | Done | 2026-03-26 | [BI-786](https://app.clickup.com/t/86ex1f18e) | Year-over-year volume comparison, BD enterprise deal baseline |
| BI-791 | Replace/Refund Tickets (6mo) | Phương (CS) | Done | 2026-03-30 | [BI-791](https://app.clickup.com/t/86ex324yv) | Replace + Refund union, 6-month ticket export with reason mapping |
| BI-792 | Processing Time Report (duynguyen) | Phương Thảo (PD) | Done | 2026-03-31 | [BI-792](https://app.clickup.com/t/86ex3ay3q) | Pivot table (product × month, avg processing day) + detail raw list |

---

## How to Use This Archive

### For routine lookup:
1. Find request ID in table above
2. Click ClickUp link → read task description (= request scope) + comments (= technical details)
3. No need to access git folder

### For AI agents:
- **Searching by pattern:** grep this file for keyword (e.g., "mug", "processing time")
- **Fetching full details:** Use `clickup_get_task(task_id)` MCP tool with ID from table
- **Git reference:** Original git folder paths in archive (for context only, not primary source)

### For decision-making:
- "Is request X similar to past work?" → Check "Notes" column
- "Which team requested Y?" → "Requester" column
- "When was this last done?" → "Completion" date

---

## Why This Archive?

**Problem:** 5 ad-hoc requests = 5 git folders + 5 REPORT.md entries + maintenance burden
**Solution:**
1. **ClickUp** = single source of truth (description + technical comments)
2. **ARCHIVE.md** = quick index for lookup (AI agent friendly)
3. **Git folders** = archived → clean repo, searchability stays high via ClickUp

**For future agent:** If user asks "Did we ever do X?", search ARCHIVE.md first → ClickUp link gives full context without git.

---

## Adding New Archives (Future)

When closing an ad-hoc request:
1. Update ClickUp task description ✅ (done)
2. Add comment with technical summary ✅ (done)
3. Add tag `synced-to-clickup` (if available)
4. Add 1-line entry to this archive table
5. Optional: move git folder to `adhoc/archive/YYYY-QN/` if needed for storage cleanup

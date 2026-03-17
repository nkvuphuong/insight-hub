# [Tên Báo Cáo]

## Thông Tin Chung

| Field | Value |
|---|---|
| **Ngày tạo** | YYYY-MM-DD |
| **Người yêu cầu** | |
| **Owner** | |
| **Status** | `draft` |
| **Version** | v0.1 |
| **Metabase link** | (chưa có) |

## Mục Tiêu

> Mô tả ngắn gọn báo cáo này trả lời câu hỏi gì, phục vụ ai, dùng để quyết định gì.

## Dimensions

| Dimension | Mô tả | Ví dụ |
|---|---|---|
| | | |

## Metrics

| Metric | Công thức / Định nghĩa | Đơn vị |
|---|---|---|
| | | |

## Filters

- [ ] Date range (mặc định: ?)
- [ ] ...

## Granularity

- [ ] Daily
- [ ] Weekly
- [ ] Monthly

## SQL Draft

```sql
-- Main query
SELECT
    -- dimensions
    -- metrics
FROM
WHERE
GROUP BY
ORDER BY
```

## Notes / Edge Cases

-

---

## Business Questions (gate: poc-done → biz-validated)

> Copy section này vào spec của từng báo cáo. Xóa câu không liên quan, thêm câu specific cho report đó.
> Gate bắt buộc: **tất cả câu phải có status trước khi move lên production.**

### Mục đích & audience

| # | Câu hỏi | Status |
|---|---|---|
| B1 | Report dùng để làm gì: monitor liên tục, review định kỳ (weekly/monthly meeting), hay one-time analysis? | 🔲 |
| B2 | Ai đọc report này? Leadership (cần tổng quan) hay ops team (cần drill-down)? | 🔲 |

### Charts & scope

| # | Câu hỏi | Status |
|---|---|---|
| B3 | Cần filter tự chọn trên Metabase không (date range, dimension...)? Hay cố định scope? | 🔲 |
| B4 | Cần so sánh 2 period trên cùng 1 chart không (MoM, YoY)? | 🔲 |

### Định nghĩa "tốt/xấu" & SLA

| # | Câu hỏi | Status |
|---|---|---|
| B5 | Mức hiện tại (xem POC) — acceptable hay đang có vấn đề? | 🔲 |
| B6 | Có SLA cam kết với khách hàng không? Nếu có: bao nhiêu? | 🔲 |
| B7 | Có ngưỡng cụ thể nào mà khi vượt qua cần escalate không? | 🔲 |

### Impact & actionability

| # | Câu hỏi | Status |
|---|---|---|
| B8 | Khi số liệu xấu: ai chịu trách nhiệm xử lý, bằng cách nào? | 🔲 |
| B9 | Metric này GM có thể tác động được không, hay phụ thuộc bên ngoài? | 🔲 |
| B10 | Sau khi xem dashboard, workflow tiếp theo là gì? Ai làm gì, trong bao lâu? | 🔲 |

### [Thêm câu specific cho report này]

| # | Câu hỏi | Status |
|---|---|---|
| Bx | ... | 🔲 |

---

> **Changelog:** xem `changelog.md`

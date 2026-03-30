# BI-791 — Export ticket Replace/Refund 6 tháng

## Thông tin yêu cầu

| Field | Value |
|---|---|
| **ClickUp** | [BI-791](https://app.clickup.com/t/86ex324yv) |
| **Requester** | Phương (CS) |
| **Priority** | High |
| **Due** | 2026-03-30 |
| **Status** | In progress |

## Mô tả yêu cầu gốc

> Export tổng issue ticket replace/refund theo từng lý do trong vòng 6 tháng.

## Phạm vi

- **Loại:** Replace + Refund
- **Thời gian:** 2025-10-01 → 2026-03-30 (tính theo ngày phát sinh issue)
- **Output:** Raw list từng ticket (không aggregate)

## Định nghĩa

### Replace
- Nguồn: `geadb__bronze.nh_order` (đơn con)
- Điều kiện: `parent_id > 0` AND `ord_is_split = 0`
- Lý do: `nh_order_extra.ordx_type_error` (join qua parent order)
- Ngày issue: `ord_time` của đơn con (replace order)

### Refund
- Nguồn: `geadb__bronze.nh_order_refund`
- Lý do: `reason_id` → map theo bảng `nh_issue_category`
- Ngày issue: `created_time` (unix timestamp)

## Mapping lý do (grouped label)

### Replace (`ordx_type_error`)
| Raw ID | Label |
|---|---|
| 1, 2, 20 | Wrong size/type |
| 3 | Wrong print |
| 4 | Bad Print |
| 5 | Item Missing |
| 6 | Late Production |
| 7, 8, 19 | Shipping Problem |
| 9, 10, 11 | Another reason |
| 12–18, 21–26 | Item Damaged |

### Refund (`reason_id`)
| Raw ID | Label |
|---|---|
| 1, 4 | Bad Print |
| 2 | Item Damaged |
| 3 | Item Missing |
| 5, 7, 10 | Shipping Problem |
| 6 | Late Production |
| 8, 11 | Wrong size/type |
| 9, 13 | Wrong print |
| 14, 15, 17 | Another reason |
| 16 | Cancel by buyer |

_Source: `gea/cron/syncing/postgresql/syncing_issues.php` + `kernel/models/pgsql/reports/dim_issues.php`_

## Output columns

| Column | Mô tả |
|---|---|
| order_id | Order ID |
| type | `replace` hoặc `refund` |
| seller_id | cus_id của seller |
| seller_email | Email seller |
| issue_date | Ngày phát sinh issue |
| raw_reason_id | ID lý do gốc |
| reason_label | Nhóm lý do (grouped) |
| refund_amount | Số tiền refund (chỉ có với refund, 0 với replace) |
| workshop_code | Xưởng xử lý (ordx_fulfill_locate) |

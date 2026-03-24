## Audience

**Data team** — kỹ thuật, internal. Không hiển thị trực tiếp cho BOD.

## Why

`order-sla` hiện cần 2 query riêng biệt với 2 join pattern phức tạp để phân tách Platform vs Standard. Lý do: `fact_order_fulfillment_performance` không phân biệt được 2 nhóm — phải join với `v__usps_paided` để suy ra.

Nếu thêm 2 columns (`is_platform`, `platform_tal_days`) vào MV, `fact_ofp` sẽ tự chứa thông tin phân nhóm → `order-sla` (và các báo cáo tương lai) chỉ cần query 1 bảng.

## What Changes

- **Thêm 2 columns vào `gea__silver.fact_order_fulfillment_performance`:**
  - `is_platform` — flag phân biệt Platform (USPS label by customer) vs Standard
  - `platform_tal_days` — TAL pre-computed từ `v__usps_paided` (Platform only)
- **Rewrite MV** để populate 2 columns này qua LEFT JOIN với `v__usps_paided_to_first_scan_days`

## Impact

- **Tables thay đổi:** `gea__silver.fact_order_fulfillment_performance` (schema + MV)
- **Views/tables downstream bị ảnh hưởng:** Không — thêm columns là non-breaking
- **Báo cáo được unblock:** `order-sla` (Gate 6 — SQL refactor)
- **Không ảnh hưởng:** Existing queries trên `fact_ofp` — columns mới có DEFAULT, backward compatible

## Gates áp dụng

`discovery` → `spec-confirmed` → `sql-verified` → `production`

*(Bỏ `poc-done` và `biz-validated` — đây là infra change, không phải report)*

# Reports POC — Claude Context

Đây là workspace của Phuong để POC báo cáo trước khi đưa lên Metabase.

## Dự Án Là Gì

- Viết & verify SQL trên ClickHouse qua MCP trong Claude Code
- POC visualization bằng Python (Plotly interactive + Matplotlib static PNG) — **chỉ visualize, không transform**
- Lưu đặc tả, ý tưởng, changelog của từng báo cáo

## Stack


| Thành phần        | Công cụ                                                       |
| ----------------- | ------------------------------------------------------------- |
| Data Warehouse    | ClickHouse v25.0 (kết nối qua MCP trong Claude Code)          |
| Query             | SQL — ClickHouse dialect, xử lý **toàn bộ** logic tại đây     |
| Visualization POC | Python: Plotly (interactive), Matplotlib/Seaborn (static PNG) |
| Notebook          | Jupyter (`.ipynb`)                                            |
| Production BI     | Metabase                                                      |


## ClickHouse MCP — Defaults

Luôn dùng thông tin này, không cần hỏi lại:


| Field            | Value                                  |
| ---------------- | -------------------------------------- |
| **Organization** | DA's Organization                      |
| **Service**      | gea-data                               |
| **Service ID**   | `bf199f64-2a10-4ae7-bd03-56984eaf0158` |


**Business systems:**

| System | DB prefixes | Mô tả |
| --- | --- | --- |
| OMS | `geadb__*` | Order Management System |
| WMS | `gea_wms__*` | Warehouse Management System |
| FFM | `gea_ffm__*` | Fulfillment operations |
| POD | `gea_seller__*`, `gea_iam__*`, `gea_finance__*`, `gea_store__*`, `gea_studio__*`, `gea_shipping__*`, ... | Print-on-Demand platform |
| Integrated | `gea__*` (double underscore), `gea_silver`, `gea_gold` | Tổng hợp từ nhiều systems + data ngoài hệ thống |
| GMprint | *(coming soon)* | — |

**Schema cache:**

- `docs/schema.md` — **index** toàn bộ databases + system groupings, đọc file này trước
- `docs/data-map.md` — cross-DB context: entity map, join paths, lineage
- `docs/schema/<database>.md` — chi tiết columns từng database
- Chỉ gọi MCP explore khi database chưa có file schema hoặc cần refresh

## Workflow (OpenSpec)

Báo cáo được quản lý qua OpenSpec — artifacts nằm ở `openspec/changes/<name>/`.

Gates (cần Phuong confirm trước khi tiếp):
`discovery` → `draft` → `spec-confirmed` → `sql-verified` → `poc-done` → `biz-validated` → `production`

---

## Source of Truth

> Quy tắc tránh drift giữa các file trong cùng một báo cáo.


| File            | Source of truth cho                                 | Không lưu ở                        |
| --------------- | --------------------------------------------------- | ---------------------------------- |
| `design.md`     | Metric definitions, dimensions, filters, caveats    | Không nhân đôi sang file khác      |
| `queries/*.sql` | Toàn bộ SQL — logic cuối cùng đã verified           | Inline trong `design.md`           |
| `changelog.md`  | Lịch sử thay đổi của báo cáo                        | Inline trong `design.md`           |
| `exports/*.png` | PNG output cuối — overwrite khi re-export           | Không commit khi chưa final        |
| `queries/*.csv` | Data cache từ MCP — giữ để tái sử dụng, debug      | Không commit (xem `.gitignore`)    |

**CSV cache — khi nào cần re-query MCP:**
- Date range thay đổi
- Cần data mới (data đã refresh trên ClickHouse)
- Debug: số liệu trên chart trông bất thường
- `export.py` sẽ báo lỗi rõ ràng nếu CSV chưa có và hướng dẫn query nào cần chạy


**Áp dụng:**

- `spec.md` chỉ **tham chiếu** file SQL và changelog — không paste nội dung vào.
  - SQL section: `> Source of truth: queries/ — xem file SQL trực tiếp.`
  - Changelog section: `> Xem changelog.md`
- Mỗi khi SQL thay đổi → cập nhật file trong `queries/`, không cần sửa `spec.md`.
- Mỗi khi có thay đổi → ghi vào `changelog.md`, không ghi thêm vào `spec.md`.

---

## Workflow — Tóm tắt kỹ thuật

**Python KHÔNG làm:**

- Filter, join, aggregate, transform dữ liệu
- Business logic (tính toán metrics, handle edge cases)
- Bất kỳ tác vụ ETL/enrich nào

**Lý do:** Metabase chạy SQL thuần. Nếu logic nằm trong Python → không reproduce được trên Metabase.

## Cấu Trúc Thư Mục

```
reports/
├── CLAUDE.md                      # File này — đọc đầu tiên
├── README.md                      # Workflow + setup guide
├── requirements.txt               # Python deps
├── docs/
│   ├── schema.md                  # Index databases — đọc trước khi viết SQL
│   ├── schema/                    # Chi tiết schema từng database (1 file/db)
│   │   ├── gea_gold.md            # Gold: metrics, views cho BI
│   │   ├── gea_silver.md          # Silver: enriched views NH/SC + shipping rates
│   │   ├── gea__silver.md         # Silver: fact/dim tables
│   │   ├── gea__silver_staging.md # Silver staging: USPS SLA views
│   │   ├── geadb__silver.md       # Silver: fact_order_weight
│   │   ├── geadb__bronze.md       # Bronze: nh_order, nh_order_extra (core)
│   │   ├── gea__bronze.md         # Bronze: USPS tracking events
│   │   ├── gea_seller__bronze.md  # Bronze: sc_order, sc_order_line_item
│   │   ├── gea_finance__bronze.md # Bronze: fin_wallet_transaction
│   │   ├── gea_iam__bronze.md     # Bronze: iam_user, iam_team
│   │   ├── gea_store__bronze.md   # Bronze: store data
│   │   ├── gea_ffm__bronze.md     # Bronze: fulfillment
│   │   ├── gea_shipping__bronze.md
│   │   ├── gea_studio__bronze.md
│   │   ├── gea_integration__bronze.md
│   │   ├── gea_inventory__bronze.md
│   │   └── gea_oms_integration__bronze.md
│   └── CHANGELOG.md               # Changelog tổng hợp toàn dự án
├── _templates/
│   ├── spec_template.md           # Template đặc tả báo cáo
│   └── poc_template.ipynb         # Template notebook POC
├── openspec/
│   ├── config.yaml                # Project context + rules cho OpenSpec
│   └── changes/
│       └── <report-name>/
│           ├── proposal.md        # What & why — audience, scope, gates
│           ├── design.md          # Technical spec — metrics, SQL, caveats ⭐ đọc trước khi viết SQL
│           └── tasks.md           # Next steps theo lifecycle gates
└── reports/                       # Tất cả báo cáo — 1 subfolder per báo cáo
    └── <report-name>/             # kebab-case
        ├── changelog.md           # Changelog của báo cáo này
        ├── queries/
        │   ├── main.sql           # Query chính — verified qua MCP
        │   └── *.sql              # Sub-queries nếu cần
        ├── poc.ipynb              # Notebook: chạy query → visualize (không transform)
        └── export.py              # Script xuất PNG/CSV
```

## Quy Ước SQL — ClickHouse v25.0

### Ưu tiên xử lý trong SQL

- Mọi filter, aggregation, join, metric calculation → trong SQL
- Python chỉ nhận kết quả cuối, không chạm vào data logic

### ClickHouse-specific cần nhớ

- **Date functions**: `toStartOfMonth()`, `toStartOfWeek()`, `toDate()`, `formatDateTime()`
- **Aggregation**: `sumIf()`, `countIf()`, `uniqExact()`, `groupArray()`
- **Array**: `arrayJoin()`, `arrayMap()`, `arrayFilter()`
- **Conditional**: `if()`, `multiIf()`, `CASE WHEN`
- **Window**: `lagInFrame()`, `leadInFrame()`, `runningAccumulate()` — cần `ROWS BETWEEN`
- **Data types**: dùng `Nullable(T)` cẩn thận — nhiều functions không nhận NULL tự động
- **MergeTree family**: hiểu partition key khi viết WHERE để tận dụng pruning
- **FINAL keyword**: cần thiết với `ReplacingMergeTree` / `CollapsingMergeTree` để dedup
- **DateTime vs Date**: ClickHouse phân biệt rõ — cast đúng type tránh implicit conversion chậm
- **LowCardinality**: cột string low-cardinality (status, category) thường được wrap — query nhanh hơn
- CTE dùng `WITH ... AS (SELECT ...)` — standard, không dùng temp table

### Patterns

```sql
-- Đúng: toàn bộ logic trong SQL, Python chỉ nhận df này
WITH
    base AS (
        SELECT
            toStartOfMonth(created_at) AS month,
            status,
            sumIf(amount, status = 'completed') AS revenue,
            countIf(id, status = 'cancelled') AS cancelled_count
        FROM orders
        WHERE created_at >= toDate('2025-01-01')
        GROUP BY month, status
    )
SELECT * FROM base ORDER BY month
```

## Danh Sách Báo Cáo


| Folder                        | Tên               | Status   |
| ----------------------------- | ----------------- | -------- |
| `reports/order-sla/`          | Order SLA         | poc-done (v0.2)      |


*(Cập nhật bảng này mỗi khi thêm báo cáo mới)*

## Hướng Dẫn Claude

### Quy tắc ghi CHANGELOG (áp dụng cho mọi loại thay đổi)

**Sau mỗi session làm việc, luôn ghi vào `docs/CHANGELOG.md`** — bất kể là schema, setup, hay báo cáo.

`docs/CHANGELOG.md` là **index** — mỗi entry = 1 dòng tóm tắt ≤ 15 từ + pointer đến detail (nếu có). Detail nằm ở file sẵn có, không tạo file mới.

| Scope | Detail nằm ở | Có pointer không |
|---|---|---|
| `[setup]` | Không có file riêng — ghi inline ngắn là đủ | Không |
| `[schema]` | `docs/schema/<db>.md` | Có |
| `[<report>]` | `reports/<name>/changelog.md` | Có |

**Ví dụ:**
```
### Setup
- [2026-03-17] Thêm schema_template.md, flow explore schema vào CLAUDE.md

### Schema
- [2026-03-17] gea_wms__bronze: explore 60 tables, WMS domain (mới) → [gea_wms__bronze.md](../schema/gea_wms__bronze.md)

### Reports
- [2026-03-13..16] order-performance: spec → poc-done (v0.1→v0.18) → [changelog](../../reports/order-performance/changelog.md)
```

### Khi làm việc với báo cáo hiện có

1. Đọc `openspec/changes/<name>/design.md` — source of truth cho metrics, SQL, filters, caveats
   - Nếu change đã archive: đọc từ `openspec/archive/<name>/design.md`
2. Đọc `openspec/changes/<name>/tasks.md` — xác định next steps và gate hiện tại
3. Không nhảy cóc gate — cần Phuong confirm trước khi tiếp
4. Chạy SQL qua MCP để verify trước khi lưu vào `reports/<name>/queries/`
5. Ghi lại mọi thay đổi vào `reports/<name>/changelog.md`
6. Ghi entry tương ứng vào `docs/CHANGELOG.md`

### Khi tạo báo cáo mới

Dùng `/opsx:propose` — Claude sẽ tạo artifacts tự động.

Nếu tạo thủ công:
1. Chạy `openspec new change "<report-name>"` để tạo change folder + artifacts
2. Điền `openspec/changes/<name>/proposal.md` — audience, key question, success criteria
3. Điền `openspec/changes/<name>/design.md` — metrics, data source, SQL approach (dùng `_templates/spec_template.md` làm reference)
4. Điền `openspec/changes/<name>/tasks.md` — checklist theo lifecycle gates
5. Tạo `reports/<name>/` với: `queries/`, `changelog.md`, `poc.ipynb` (copy từ `_templates/poc_template.ipynb`)
6. **Cập nhật bảng "Danh Sách Báo Cáo" trong file CLAUDE.md này**

### Khi viết SQL

1. **Đọc `openspec/changes/<name>/design.md`** — xác định table, columns, metric formulas, filters, caveats
2. **Đọc `docs/schema.md`** — xác định database nào cần dùng
3. **Đọc `docs/data-map.md`** — nếu query join nhiều database: xem entity map + join paths
4. **Đọc `docs/schema/<database>.md`** — xem đúng tên columns, types
5. **Chỉ gọi MCP list/explore schema** khi database chưa có file trong `docs/schema/` hoặc cần refresh
6. Xử lý **toàn bộ** logic trong SQL — không để lại gì cho Python
7. Dùng CTE cho query phức tạp
8. Chú ý ClickHouse-specific syntax (xem mục Quy Ước SQL bên trên)
9. Verify qua MCP (`run_select_query`) trước khi lưu file
10. **Nếu dùng join path mới chưa có trong `docs/data-map.md`** → cập nhật Section 3 sau khi verify thành công

### Khi explore / refresh schema một database

Dùng khi: database chưa có file trong `docs/schema/` hoặc Phuong báo đã có thêm tables.

**Bước 1 — List tables qua MCP**

```
mcp__clickhouse_cloud__list_tables(serviceId, database)
```

Kết quả thường rất lớn (>100KB) → sẽ được save vào file tạm tự động.

**Bước 2 — Parse + viết schema file**

Dùng `general-purpose` agent đọc file tạm (theo chunks nếu cần) và viết `docs/schema/<database>.md`.
**Format:** theo `_templates/schema_template.md` — đọc file đó, copy, điền placeholder.

**Bước 3 — Lấy row counts**

Chạy một query duy nhất:

```sql
SELECT name, total_rows
FROM system.tables
WHERE database = '<database>'
  AND name NOT LIKE '%__raw'
  AND name NOT LIKE '%__mv_to_latest'
ORDER BY total_rows DESC
```

Điền vào Quick Reference và per-table header.

**Bước 4 — Cập nhật index**

Sửa `docs/schema.md`: cập nhật dòng của database đó (tables count, link file, status → Done).

**Bước 5 — Ghi CHANGELOG**

Thêm 1 dòng index vào section `### Schema` trong `docs/CHANGELOG.md` — tóm tắt ≤ 15 từ + pointer đến file schema vừa tạo/cập nhật. Xem quy tắc đầy đủ ở mục "Quy tắc ghi CHANGELOG".

### Khi tạo visualization (Python)

- Input: DataFrame từ query đã hoàn chỉnh — **không transform thêm**
- Plotly cho POC demo (interactive)
- Matplotlib/Seaborn cho export PNG gửi sếp
- Template: `_templates/poc_template.ipynb`


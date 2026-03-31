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
│       ├── <report-name>/
│       │   ├── proposal.md        # What & why — audience, scope, gates
│       │   ├── design.md          # Technical decisions + SQL approach (⭐ đọc trước viết SQL)
│       │   ├── tasks.md           # Next steps theo lifecycle gates
│       │   └── specs/             # Capability requirements (formal spec per capability)
│       │       └── <capability>.md
│       └── archive/               # Completed changes (keep for reference)
│           └── <date-name>/       # Full artifacts maintained
├── adhoc/                         # Yêu cầu ad-hoc từ CS/BD — one-off, không recurring
│   ├── _template/                 # Template cho request mới
│   │   ├── request.md             # Ai yêu cầu, deadline, mô tả
│   │   └── query.sql              # SQL template + common patterns
│   ├── .gitignore                 # Ignore output/ (chứa data khách hàng)
│   └── YYYY-MM-DD-<name>/        # Mỗi request 1 folder, date prefix
│       ├── request.md             # Context yêu cầu
│       ├── query.sql              # Query chính
│       └── output/                # CSV/Excel export (gitignored)
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
- **JOIN type mismatch**: ClickHouse không tự cast signed/unsigned trong JOIN ON — luôn kiểm tra type của join key ở cả 2 bảng trước khi viết JOIN, cast tường minh nếu khác type (ví dụ: `toInt64(ord_id)` khi join Int64 với UInt64)
- **Test CTE trước khi tạo MV**: trước khi chạy `CREATE MATERIALIZED VIEW`, copy phần `AS (SELECT ...)` ra chạy thử standalone để đảm bảo không có lỗi syntax hay type — tránh trường hợp DROP xong mới phát hiện lỗi
- **Nullable DateTime filter**: filter trên `Nullable(DateTime('UTC'))` column bằng `toDate(col) >= '...'` — **không** dùng `col >= toDateTime('...', 'UTC')` vì implicit cast fail âm thầm trả về 0 rows

### MCP ClickHouse — Debug Protocol

`"completed with no output"` từ MCP có nghĩa là **0 rows HOẶC timeout âm thầm** — không phân biệt được từ response. Luôn verify trước khi kết luận.

**Khi gặp "no output" trên query phức tạp:**

1. **Verify từng nguồn riêng** — test filter trên từng bảng độc lập trước khi UNION/JOIN:
   ```sql
   SELECT count() FROM table_v1 WHERE seller_email = '...' -- có data không?
   SELECT count() FROM table_v3 WHERE seller_email = '...' -- có data không?
   ```

2. **Verify join key khớp** — lấy vài IDs từ source rồi check thủ công trong target:
   ```sql
   SELECT DISTINCT order_id FROM source_table WHERE ... LIMIT 5
   -- rồi:
   SELECT * FROM fact_table WHERE order_id IN (id1, id2, id3)
   ```

3. **Tăng timeout** cho query nhiều FINAL + JOIN trên bảng >1M rows: dùng `timeoutSeconds = 300`

4. **Kết luận "no data" chỉ khi** `SELECT count()` trên bảng gốc với filter đơn giản trả về 0

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
| `reports/ops-sla-drilldown/`  | Ops SLA Drilldown | spec-confirmed       |


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

1. Đọc `openspec/changes/<name>/design.md` — technical decisions, metrics, SQL approach, caveats
   - Nếu change đã archive: đọc từ `openspec/archive/<name>/design.md`
2. Nếu cần formal requirement definition: đọc `openspec/changes/<name>/specs/<capability>.md`
   - **Distinction:** design.md = implementation decisions (D1, D2, ...); specs/ = capability requirements (SHALL, scenarios)
   - Nhiều change không cần specs/ — chỉ khi có formal requirement docs cần separate từ design
3. Đọc `openspec/changes/<name>/tasks.md` — xác định next steps và gate hiện tại
4. Không nhảy cóc gate — cần Phuong confirm trước khi tiếp
5. Chạy SQL qua MCP để verify trước khi lưu vào `reports/<name>/queries/`
6. Ghi lại mọi thay đổi vào `reports/<name>/changelog.md`
7. Ghi entry tương ứng vào `docs/CHANGELOG.md`

### Khi tạo báo cáo mới

Dùng `/opsx:propose` — Claude sẽ tạo artifacts tự động.

Nếu tạo thủ công:
1. Chạy `openspec new change "<report-name>"` để tạo change folder + artifacts
2. Điền `openspec/changes/<name>/proposal.md` — audience, key question, success criteria
3. Điền `openspec/changes/<name>/design.md` — metrics, data source, SQL approach (dùng `_templates/spec_template.md` làm reference)
4. Điền `openspec/changes/<name>/tasks.md` — checklist theo lifecycle gates
5. Tạo `reports/<name>/` với: `queries/`, `changelog.md`, `poc.ipynb` (copy từ `_templates/poc_template.ipynb`)
6. **Cập nhật bảng "Danh Sách Báo Cáo" trong file CLAUDE.md này**

### Khi xử lý yêu cầu ad-hoc (CS/BD)

> Yêu cầu one-off từ CS/BD: export data cho khách hàng cụ thể, list top customers, v.v.
> Không cần OpenSpec flow. Ưu tiên tốc độ.

#### Step 0 — Xác định scope từ ClickUp task
1. Đọc ClickUp task description → requester, deadline, exact ask
2. Confirm output format: **CSV / Excel / PDF?** (trả lời requester nếu không rõ)
3. Estimate: "Bao lâu xong?" để set expectation

#### Step 1–6 — Thực hiện
1. Tạo folder `adhoc/YYYY-MM-DD-<tên-ngắn>/` (copy từ `adhoc/_template/`)
2. Điền `request.md` — paste message gốc, ghi scope + data source + output columns (xem template)
3. Viết query:
   - **Single query:** `query.sql` (nếu báo cáo nhỏ, ~50 lines)
   - **Multi-query:** `q1_name.sql`, `q2_name.sql`, `q3_*.sql` (nếu báo cáo lớn có nhiều phần, ví dụ BI-787 có 4 queries)
4. Verify query qua MCP (`run_select_query`) trước khi save
5. **Export output:**
   - **CSV:** Trực tiếp từ MCP query result hoặc `pandas.to_csv()`
   - **Excel:** Dùng `openpyxl` + `export.py` nếu cần formatting/pivot (ví dụ BI-792)
   - **PDF:** Matplotlib figure nếu cần visualize
6. Gửi file cho người yêu cầu
7. **Cập nhật `adhoc/REPORT.md`** — thêm 1 dòng vào Request Log + update Summary counts + đánh giá recurring candidate

#### Step 7 — Sync & Commit
1. **Task description update:** Copy request.md scope + data source → ClickUp task description
2. **Technical comment:** Add comment với queries + join paths + key notes
3. **Commit message:**
   ```
   feat(adhoc): BI-XXX <tên-báo-cáo> — <tóm-tắt>

   - Details of what was implemented
   - Key technical notes if any

   Co-Authored-By: Claude Haiku 4.5 <noreply@anthropic.com>
   ```
   Ví dụ: `feat(adhoc): BI-792 processing time report — duynguyen02169 Q1/2026, pivot summary + detail list`
4. **ARCHIVE.md:** Add 1-line entry: `| BI-XXX | Task | Requester | Done | 2026-03-31 | [link](url) | Notes |`

#### Common join paths for ad-hoc

**OMS orders + fulfillment:**
```
geadb__bronze.nh_order (order_id, cus_id, seller_id, ord_time)
  ↓ (optional enrichment)
geadb__bronze.nh_customer (cus_id → seller_email)
  ↓ (for metrics)
gea__silver.fact_order_fulfillment_performance_by_product FINAL (order_id)
```

**POD orders + fulfillment:**
```
gea__silver.fact_order_line_v3 (order_id, seller_email, product_type)
  ↓ (for metrics)
gea__silver.fact_order_fulfillment_performance_by_product FINAL (order_id, toUInt64 cast)
```

**Seller-specific reports (V1+V3 unified):**
```
WITH seller_orders AS (
    SELECT DISTINCT toUInt64(order_id) FROM gea__silver.fact_order_line_v1 WHERE seller_email = '...'
    UNION DISTINCT
    SELECT DISTINCT toUInt64(order_id) FROM gea__silver.fact_order_line_v3 WHERE seller_email = '...'
)
SELECT ... FROM seller_orders
INNER JOIN gea__silver.fact_order_fulfillment_performance_by_product FINAL ON ...
```
**Note:** Type cast `toUInt64()` vì fact_order_line.order_id là Int64, fact table là UInt64

**Tier/Product classification (POD):**
```
gea_seller__bronze.gm_team_price_tier FINAL (tier_id, team_id)
  ↓
gea_seller__bronze.sc_order (team_id)
  ↓
sc_order_line_item (item_quantity, variant_name → product type)
  ↓ (join to gm_product for structured type)
gm_product → gm_product_type (product_type_id)
```

#### ClickHouse-specific (critical for ad-hoc)

- **FINAL keyword:** Bắt buộc cho ReplacingMergeTree/CollapsingMergeTree tables (`nh_order`, `nh_order_refund`, `nh_order_extra`, `gm_team_price_tier`)
- **Nullable DateTime filter:** Dùng `toDate(col) >= '2026-01-01'` NOT `col >= toDateTime('2026-01-01', 'UTC')` trên `Nullable(DateTime('UTC'))` columns — implicit cast sẽ fail âm thầm
- **Type casting in JOIN:** Explicit `toUInt64()` / `toInt64()` trước khi JOIN — không rely implicit conversion (ví dụ fact_order_line.order_id: Int64 → fact_ofp.order_id: UInt64)
- **Timeout:** Query phức tạp (nhiều FINAL + JOIN bảng >1M rows) → set `timeoutSeconds = 300` (default 120s)
- **"completed with no output" ambiguity:** = 0 rows HOẶC timeout âm thầm, không phân biệt. Verify bằng `SELECT count(*) FROM table WHERE filter` trước khi kết luận "no data"
- **MCP token expiration:** Nếu gặp lỗi auth mid-session → dùng `/mcp` command để re-auth

#### Common patterns / lookup table

| Scenario | Tables | Join Key | Type Note |
|---|---|---|---|
| Get seller email from order | `nh_order` → `nh_customer` | cus_id | OMS customer |
| Get seller email from POD order | `sc_order` → `iam_user` (via team_id) | team_id → default_team_id | POD team lookup |
| Get fulfillment metrics | `fact_order_fulfillment_performance_by_product FINAL` | order_id | Requires FINAL |
| Filter by product type | `sc_order_line_item` → variant_name pattern OR `gm_product_type` | variant_name ILIKE OR product_type_id | Prefer explicit join to gm_product_type |
| Get tier assignment | `gm_team_price_tier FINAL` | team_id → tier_id | Requires FINAL |
| Get shipping service | `sc_order_shipment` | order_id | Nullable columns — handle NULL |

### Khi ad-hoc request hoàn thành — Sync & Archive

> Giải pháp duy trì traceability mà không phải quay lại git khi cần lookup sau này.

**Bước 1 — Sync request details lên ClickUp:**
- Cập nhật task description = `request.md` scope + data source (đầy đủ)
- Tạo comment = technical implementation summary (queries, join paths, key notes)
- Add tag `synced-to-clickup` (nếu có)

**Bước 2 — Update `adhoc/ARCHIVE.md`:**
- Thêm 1 dòng vào bảng tương ứng quarter (Q1, Q2, v.v.)
- Columns: ID | Task | Requester | Status | Completion date | ClickUp link | Notes

**Bước 3 — Optional git cleanup (storage):**
- Nếu folder ad-hoc > 10 request/quarter → move sang `adhoc/archive/YYYY-QN/` (backup)
- **Cảnh báo:** KHÔNG xóa output/ chứa data khách hàng — lưu ở external storage nếu cần

**Lợi ích:**
- **Source of truth:** ClickUp = description + comments (tất cả context)
- **Quick lookup:** ARCHIVE.md index → ClickUp link → full details (AI agent friendly)
- **Repo clean:** Git chỉ giữ template + summary, không chứa data chi tiết

**Ví dụ khi tra cứu sau này:**
> "Chúng ta có bao giờ làm report processing time cho seller nào không?"
- Mở `adhoc/ARCHIVE.md` → grep "processing time" → tìm thấy BI-792 → click ClickUp → xem scope + queries → adapt cho request mới

### Khi viết SQL — Recurring Reports (OpenSpec flow)

> Dành cho báo cáo recurring (trong `reports/`), không phải ad-hoc.

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

**Khác với ad-hoc:** Recurring reports có design.md spec → follow exact metrics, không tự sáng tạo logic.

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


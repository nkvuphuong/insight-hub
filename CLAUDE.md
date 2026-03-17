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


**Schema cache:**

- `docs/schema.md` — **index** toàn bộ databases, đọc file này trước
- `docs/schema/<database>.md` — chi tiết columns từng database
- Chỉ gọi MCP explore khi database chưa có file schema hoặc cần refresh

## Phương Pháp — Spec-Driven Development

> **Spec là source of truth.** Không viết SQL trước khi spec được Phuong confirm. Không đưa lên Metabase khi chưa qua đủ các giai đoạn.

### Lifecycle báo cáo

```
[discovery*] → [draft] → [spec-confirmed] → [sql-verified] → [poc-done] → [biz-validated] → [production]
                                                                                   ↑
                                                                          * discovery bắt buộc
                                                                            nếu yêu cầu mờ
```


| Status           | Ý nghĩa                                  | Gate — cần Phuong confirm trước khi tiếp                                              |
| ---------------- | ---------------------------------------- | ------------------------------------------------------------------------------------- |
| `discovery`      | Làm rõ yêu cầu business *(nếu cần)*     | ✅ Câu hỏi business được trả lời → có thể viết spec                                   |
| `draft`          | Spec đang viết                           | ✅ Confirm spec: dimensions, metrics, filters                                          |
| `spec-confirmed` | Spec OK, bắt đầu SQL                     | ✅ Confirm kết quả query (row count, metrics hợp lý)                                  |
| `sql-verified`   | SQL đúng, bắt đầu POC                    | ✅ Approve visualization                                                               |
| `poc-done`       | POC xong, chờ business validation        | ✅ Business validation: charts đúng nhu cầu? Actionable? Ai là action owner?          |
| `biz-validated`  | POC được confirm là đúng hướng           | ✅ Approve scope final trước khi build Metabase                                        |
| `production`     | Đang chạy trên Metabase                  | —                                                                                     |


### Giai đoạn 0 — DISCOVERY: Làm Rõ Yêu Cầu *(chỉ khi yêu cầu ban đầu còn mờ)*

Khi nào cần discovery: yêu cầu chỉ có 1–2 câu, chưa rõ mục đích sử dụng, chưa có SLA target, hoặc chưa xác định được action owner.

Claude làm — đặt câu hỏi cho Phuong để hỏi lại stakeholder:

**Về mục đích & audience**
- Report dùng để làm gì: monitor liên tục, review định kỳ, hay one-time analysis?
- Ai đọc: leadership (cần tổng quan) hay ops team (cần drill-down)?

**Về định nghĩa "tốt/xấu"**
- Mức nào là acceptable? Có SLA cam kết với khách hàng không?
- Có benchmark để so sánh (ngành, competitor, target nội bộ) không?

**Về charts & scope**
- Cần chart nào cụ thể? Breakdown theo dimension nào?
- Cần so sánh period không (MoM, YoY)?

**Về impact & actionability**
- Dashboard này giúp đưa ra quyết định gì?
- Khi số liệu xấu: ai chịu trách nhiệm xử lý, bằng cách nào?
- Có workflow/playbook sẵn chưa, hay cần xây song song?

**→ DỪNG. Chờ Phuong tổng hợp câu trả lời từ stakeholder trước khi viết spec.**

### Giai đoạn 1 — DRAFT: Viết Spec

Claude làm:

1. Đọc `docs/schema.md` → xác định tables liên quan
2. Đọc `docs/schema/<database>.md` → hiểu columns, types, caveats
3. Điền đầy đủ `spec.md`: mục tiêu, dimensions (tên column thực tế), metrics (công thức cụ thể), filters + defaults, granularity, edge cases
4. Ghi `changelog.md`: `v0.1 — Tạo spec ban đầu`

**→ DỪNG. Chờ Phuong confirm spec trước khi viết SQL.**

### Giai đoạn 2 — SQL: Viết & Verify

Claude làm:

1. Viết SQL theo đúng spec đã confirm — toàn bộ logic trong SQL
2. Chạy qua MCP (`run_select_query`) để verify
3. Kiểm tra: row count hợp lý? Metrics khớp định nghĩa? Edge cases handled?
4. Nếu cần sửa logic → cập nhật spec trước, rồi mới sửa SQL
5. Lưu vào `queries/main.sql`
6. Cập nhật `spec.md` status → `sql-verified`, ghi `changelog.md`

**→ DỪNG. Chờ Phuong confirm kết quả query.**

### Giai đoạn 3 — POC: Visualize

Claude làm:

1. Copy `_templates/poc_template.ipynb` → `reports/<report-name>/poc.ipynb`
2. DataFrame từ query đã verified — **không transform thêm**
3. Plotly cho POC demo (interactive), Matplotlib/Seaborn cho export PNG
4. **Giữ `queries/*.csv` làm cache** — tái sử dụng khi re-export mà data chưa thay đổi. Chỉ xóa/re-query khi cần refresh data (date range đổi, data mới, debug bất thường)
5. Cập nhật status → `poc-done`, ghi `changelog.md`

**→ DỪNG. Chờ Phuong approve visualization.**

### Giai đoạn 4 — PRODUCTION

Claude làm:

1. Cập nhật `spec.md`: status → `production`, điền Metabase link
2. Ghi `changelog.md` + `docs/changelogs/CHANGELOG.md`
3. Cập nhật bảng "Danh Sách Báo Cáo" trong `CLAUDE.md`

---

## Source of Truth

> Quy tắc tránh drift giữa các file trong cùng một báo cáo.


| File            | Source of truth cho                                 | Không lưu ở                   |
| --------------- | --------------------------------------------------- | ----------------------------- |
| `queries/*.sql` | Toàn bộ SQL — logic cuối cùng đã verified           | Inline trong `spec.md`        |
| `changelog.md`  | Lịch sử thay đổi của báo cáo                        | Inline trong `spec.md`        |
| `spec.md`       | Định nghĩa metric, dimensions, filters, phương pháp | Không nhân đôi sang file khác |
| `exports/*.png` | PNG output cuối — overwrite khi re-export           | Không commit khi chưa final   |
| `queries/*.csv` | Data cache từ MCP — giữ để tái sử dụng, debug      | Không commit (xem `.gitignore`) |

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

## Versioning

### Format changelog.md

```markdown
| Ngày | Version | Thay đổi |
|---|---|---|
| 2026-03-14 | v0.1 | Tạo spec ban đầu |
| 2026-03-14 | v0.2 | Confirm dimensions + metrics sau review |
| 2026-03-15 | v0.3 | Viết SQL draft, verify qua MCP |
| 2026-03-15 | v1.0 | SQL verified, POC done — ready for Metabase |
| 2026-03-16 | v1.0.1 | Sửa filter date range theo yêu cầu |
```

Mốc version:

- `v0.x` — draft/đang phát triển, chưa production
- `v1.0` — SQL verified + POC done, sẵn sàng Metabase
- `v1.x` — đang production, patch nhỏ không thay đổi logic chính
- `v2.0` — breaking change: thay đổi metric definition hoặc thêm dimension lớn

### Điều Claude KHÔNG tự làm (luôn confirm với Phuong trước)

- Thay đổi định nghĩa metric đã confirm trong spec
- Sửa SQL sau khi đã `sql-verified` nếu ảnh hưởng kết quả
- Đổi status sang `production`

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
│   └── changelogs/
│       └── CHANGELOG.md           # Changelog tổng hợp toàn dự án
├── _templates/
│   ├── spec_template.md           # Template đặc tả báo cáo
│   └── poc_template.ipynb         # Template notebook POC
└── reports/                       # Tất cả báo cáo — 1 subfolder per báo cáo
    └── <report-name>/             # kebab-case
        ├── spec.md                # Đặc tả báo cáo
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
| `reports/order-performance/`  | Order Performance | poc-done |


*(Cập nhật bảng này mỗi khi thêm báo cáo mới)*

## Hướng Dẫn Claude

### Khi làm việc với báo cáo hiện có

1. Đọc `reports/<report-name>/spec.md` — xác định status hiện tại, làm việc đúng giai đoạn
2. Không nhảy cóc giai đoạn — spec chưa confirmed thì không viết SQL
3. Chạy SQL qua MCP để verify trước khi lưu vào `queries/`
4. Ghi lại mọi thay đổi vào `reports/<report-name>/changelog.md` với đúng version

### Khi tạo báo cáo mới

1. Tạo folder mới trong `reports/` theo kebab-case
2. Copy từ `_templates/spec_template.md` → `reports/<report-name>/spec.md`
3. Copy từ `_templates/poc_template.ipynb` → `reports/<report-name>/poc.ipynb`
4. Tạo `reports/<report-name>/changelog.md` rỗng
5. Tạo folder `reports/<report-name>/queries/`
6. **Cập nhật bảng "Danh Sách Báo Cáo" trong file CLAUDE.md này**

### Khi viết SQL

1. **Đọc `docs/schema.md`** — xác định database/table nào cần dùng
2. **Đọc `docs/schema/<database>.md`** — xem đúng tên columns, types trước khi viết
3. **Chỉ gọi MCP list/explore schema** khi database chưa có file trong `docs/schema/` hoặc cần refresh (xem flow bên dưới)
4. Kiểm tra spec: dimensions, metrics, filters cần gì
5. Xử lý **toàn bộ** logic trong SQL — không để lại gì cho Python
6. Dùng CTE cho query phức tạp
7. Chú ý ClickHouse-specific syntax (xem mục Quy Ước SQL bên trên)
8. Verify qua MCP (`run_select_query`) trước khi lưu file

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

**Lưu ý format:** xem hướng dẫn trong `_templates/schema_template.md`.

### Khi tạo visualization (Python)

- Input: DataFrame từ query đã hoàn chỉnh — **không transform thêm**
- Plotly cho POC demo (interactive)
- Matplotlib/Seaborn cho export PNG gửi sếp
- Template: `_templates/poc_template.ipynb`


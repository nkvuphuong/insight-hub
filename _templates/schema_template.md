# Schema: <database_name>

**Layer:** Bronze (raw CDC từ <source system>) <!-- Bronze / Silver / Gold -->
**Last updated:** YYYY-MM-DD
**Tables:** N (excl. schema_migrations) <!-- đếm không tính schema_migrations và internal variants -->

> **Engine:** Tất cả tables dùng `SharedMergeTree` — không cần `FINAL`
> <!-- Nếu SharedReplacingMergeTree → "luôn thêm FINAL để dedup" -->
>
> **CDC metadata columns** (có trên tất cả `<prefix>_*` tables):
> - `_processed_at` `DateTime64(3,'UTC')` — thời điểm CDC ingest vào ClickHouse
> - `_action` `String` — CDC action: `insert` / `update` / `delete`
> - `_timestamp` `DateTime64(3,'UTC')` — timestamp từ CDC event
> <!-- Bỏ block này nếu không có CDC (e.g. Gold layer) -->

---

## Quick Reference

<!-- Nhóm theo domain/category, sort by rows DESC trong mỗi nhóm -->

### <Category 1>

| Table | Rows | Mô tả |
|---|---|---|
| `table_a` | ~NNN | Mô tả ngắn |
| `table_b` | ~NNN | Mô tả ngắn |

### <Category 2>

| Table | Rows | Mô tả |
|---|---|---|
| `table_c` | ~NNN | Mô tả ngắn |
| `table_d` | 0 | Empty |

---

<!-- ============================================================
     TABLE SECTIONS — một section per table, theo thứ tự alphabet
     ============================================================ -->

## `table_a`

> Engine: SharedMergeTree | Rows: ~NNN

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `code` | Nullable(String) | |
| `name` | Nullable(String) | |
| `status` | Nullable(String) | |
| `created_at` | Nullable(String) | |
| `updated_at` | Nullable(String) | |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

## `table_b`

> Engine: SharedMergeTree | Rows: ~NNN

| Column | Type | Ghi chú |
|---|---|---|
| `id` | Int64 | PK |
| `_processed_at` | DateTime64(3, 'UTC') | CDC ingest time |
| `_action` | String | insert / update / delete |
| `_timestamp` | DateTime64(3, 'UTC') | CDC event time |

---

<!--
HƯỚNG DẪN ĐIỀN TEMPLATE
========================

1. HEADER
   - <database_name>: tên database ClickHouse
   - Layer: Bronze / Silver / Gold
   - Tables: đếm từ kết quả system.tables (trừ schema_migrations và *__raw, *__mv_to_latest)
   - Engine note: SharedMergeTree (không cần FINAL) hoặc SharedReplacingMergeTree (cần FINAL)

2. QUICK REFERENCE
   - Rows: lấy từ query:
       SELECT name, total_rows FROM system.tables
       WHERE database = '<db>'
         AND name NOT LIKE '%__raw'
         AND name NOT LIKE '%__mv_to_latest'
       ORDER BY total_rows DESC
   - Nhóm theo domain (Inventory, Orders, Users...) — không flat list
   - Sort by rows DESC trong mỗi nhóm

3. TABLE SECTIONS
   - Thứ tự: alphabet
   - Dùng ## (h2), backtick quanh tên table
   - Blockquote: engine + rows
   - Columns: lấy từ list_tables MCP — KHÔNG tự đoán
   - Ghi chú: chỉ điền cho columns không tự giải thích được từ tên:
       id        → PK
       *_amount, *_price, *_fee → đơn vị (cents? dollars?)
       *_at CDC  → CDC ingest time / CDC event time
       code dạng riêng (or_code, po_code...) → giải thích viết tắt

4. SILVER / GOLD — khác biệt so với Bronze
   - Silver: thêm section "Tổng quan domain" (bảng domain → tables → ghi chú)
             thêm section "Convention" (v_* là live view, mv_* skip, đơn vị tiền...)
             column table dùng "Mô tả" thay vì "Ghi chú"
   - Gold: không có CDC block, engine thường ghi kèm ORDER BY / PARTITION BY

5. BỎ QUA (không document)
   - schema_migrations
   - *__raw (CDC raw internal)
   - *__mv_to_latest (MaterializedView internal)
-->

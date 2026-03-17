# Schema: geadb__silver

**Layer:** Silver (fact tables, enriched/transformed từ geadb__bronze)
**Last updated:** 2026-03-13
**Tables:** 3

---

## `fact_order_weight` 🔵

> Engine: SharedMergeTree | PARTITION BY toYYYYMM(paid_at_la) | ORDER BY (paid_at_la, order_weight_lb_bucket, order_weight_label)
> Rows: ~32.9M | Fact table order weight theo timezone LA


| Column                 | Type                            | Ghi chú                               |
| ---------------------- | ------------------------------- | ------------------------------------- |
| order_id               | UInt64                          | FK → nh_order                         |
| order_weight_oz        | Float32                         | weight in ounces                      |
| order_weight_lb_bucket | String                          | 'At least 1 lb' / 'Less than 1 lb'    |
| order_weight_label     | String                          | e.g. '1 oz', '2 ozs', '1 lb', '2 lbs' |
| paid_at_la             | DateTime('America/Los_Angeles') | payment time, LA timezone             |


---

## `mv_fact_order_weight` 🔮 (internal)

> Engine: MaterializedView → fact_order_weight
> Source: geadb__bronze.nh_order_weight JOIN nh_order
> Filter: ord_deleted=0, order_weight≠0, ord_payment_datetime≠0


| Column                 | Type                            | Ghi chú |
| ---------------------- | ------------------------------- | ------- |
| order_id               | Int32                           |         |
| order_weight_oz        | Float32                         |         |
| order_weight_lb_bucket | String                          |         |
| order_weight_label     | String                          |         |
| paid_at_la             | DateTime('America/Los_Angeles') |         |


---

## `dim_order_team_id` 🔄

> Engine: SharedReplacingMergeTree (version: created_at) | PARTITION BY toYYYYMM(created_at) | ORDER BY order_id
> Rows: 0 (empty)


| Column     | Type                 | Ghi chú     |
| ---------- | -------------------- | ----------- |
| vendor_ref | String               |             |
| order_id   | String               |             |
| cus_id     | String               | customer ID |
| team_id    | String               |             |
| store_id   | String               |             |
| created_at | DateTime64(3, 'UTC') |             |
| updated_at | DateTime64(3, 'UTC') |             |



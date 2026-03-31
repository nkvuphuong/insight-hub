# Adhoc Report Log

Tổng hợp tất cả yêu cầu ad-hoc từ các team nội bộ.
Dùng để phân tích nhu cầu, tần suất lặp lại, và xác định candidates cho recurring reports.

---

## Summary


| Metric           | Value   |
| ---------------- | ------- |
| Tổng số requests | 5       |
| Requesters       | CS, BD, PD |
| Period           | 2026-03 |


---

## Request Log


| Date       | ID     | Folder                                                        | Requester | Team    | Subject                                                                                          | Data Source                                     | Output            | Status      |
| ---------- | ------ | ------------------------------------------------------------- | --------- | ------- | ------------------------------------------------------------------------------------------------ | ----------------------------------------------- | ----------------- | ----------- |
| 2026-03-26 | BI-787 | [2026-03-26-dopeskill-report](./2026-03-26-dopeskill-report/) | CS        | CS      | Export report vol + processing + shipping time cho khách Dopeskill                               | V1+V3 (nh_order + sc_order), fact_ofp           | PDF summary + CSV | Done        |
| 2026-03-26 | BI-789 | [2026-03-26-tier-vol-report](./2026-03-26-tier-vol-report/)   | CS, BD    | CS / BD | Danh sách sellers theo tier (Gold/Platinum/Diamond) + vol by product type cho promotion outreach | sc_order + gm_product_type + gm_team_price_tier | CSV               | In progress |
| 2026-03-26 | BI-786 | [2026-03-26-top-mug-sellers](./2026-03-26-top-mug-sellers/)   | CS, BD    | CS / BD | Top 10 sellers theo mug volume — 2024 vs 2025, làm cơ sở offer giá enterprise                    | V1+V3 (nh_order + sc_order), gm_product_type    | CSV               | Done        |
| 2026-03-30 | BI-791 | [2026-03-30-replace-refund-tickets](./2026-03-30-replace-refund-tickets/) | Phương | CS | Export raw list ticket replace/refund 6 tháng (Oct 2025–Mar 2026) theo lý do | nh_order + nh_order_refund + nh_order_extra | CSV | In progress |
| 2026-03-31 | BI-792 | [2026-03-31-processing-time-duynguyen](./2026-03-31-processing-time-duynguyen/) | Phương Thảo | PD | Processing time report Q1 2026 cho seller duynguyen02169 (7 product types) — summary matrix + detail list | fact_order_fulfillment_performance_by_product + fact_order_line_v3 | Excel | Done |


---

## Phân tích theo Dimension

### Theo Biz Domain

Biz domain = mảng nghiệp vụ mà request phục vụ.

| Biz Domain | Requests | IDs | Mô tả |
| --- | --- | --- | --- |
| Seller Performance | 3 | BI-786, BI-789, BI-792 | Vol by product, tier segmentation, processing time — BD/CS/PD outreach |
| Customer SLA | 2 | BI-787, BI-791 | Processing + shipping time, replace/refund tracking — seller review |

### Theo Data Object

Data object = entity chính mà request xoay quanh.

| Data Object | Requests | IDs | Ghi chú |
| --- | --- | --- | --- |
| Orders | 5 | BI-787, BI-786, BI-789, BI-791, BI-792 | Base của tất cả requests |
| Products | 3 | BI-786, BI-789, BI-792 | Filter/group theo product type (Mug, Apparel, Blanket...) |
| Processing/Shipping time | 3 | BI-787, BI-791, BI-792 | Processing days, shipping SLA, replace/refund timeline |
| Sellers / Tiers | 3 | BI-786, BI-789, BI-792 | Seller email, tier assignment, seller-specific analysis |
| Refund/Replace issues | 1 | BI-791 | Replace/refund reason mapping + tracking |

### Theo Team

| Team | Requests | IDs |
| --- | --- | --- |
| CS | 4 | BI-787, BI-789, BI-786, BI-791 |
| BD | 2 | BI-789, BI-786 |
| PD | 1 | BI-792 |

### Theo Data Source

| Source | Requests | IDs | Ghi chú |
| --- | --- | --- | --- |
| V1+V3 (unified) | 3 | BI-787, BI-786, BI-792 | Cần UNION logic để tránh overlap |
| V3 only (sc_order) | 1 | BI-789 | Tier là khái niệm V3 |
| fact_ofp / fact_order_fulfillment_performance | 2 | BI-787, BI-792 | Processing/shipping time |
| geadb__bronze (OMS) | 1 | BI-791 | Replace/refund từ nh_order + nh_order_refund |
| gea__silver (integrated) | 2 | BI-792, BI-787 | Enriched order views + fact tables |

### Theo Subject / Pattern

| Pattern | Requests | IDs | Recurring candidate? |
| --- | --- | --- | --- |
| Volume by product type | 2 | BI-789, BI-786 | ✅ Cao — có thể thành Metabase report |
| Processing/shipping time analysis | 2 | BI-787, BI-792 | ✅ Medium-Cao — tùy SLA review + seller performance review cycle |
| Seller segmentation by tier | 1 | BI-789 | ✅ Cao — liên quan pricing/promotion cycle |
| Replace/Refund tracking by reason | 1 | BI-791 | ⚠️ Medium — theo support escalation + quality monitoring |


---

## Recurring Candidates

Requests có khả năng lặp lại → nên cân nhắc đưa lên Metabase:

1. **Vol by product type per tier** (BI-789) — mỗi lần promotion/pricing review
2. **Top sellers by product** (BI-786) — quarterly, khi BD làm enterprise deal
3. **Customer SLA report** (BI-787) — theo yêu cầu từng seller lớn / quarterly review
4. **Processing time analysis by seller** (BI-792) — monthly/quarterly performance review (có thể parameterize bằng seller_email)
5. **Replace/Refund report by reason** (BI-791) — monthly quality monitoring + support escalation tracking


# Dopeskill — Export report cho khách hàng

## Thông tin yêu cầu


| Field         | Value      |
| ------------- | ---------- |
| ClickUp Task  | `BI-787` · [link](https://app.clickup.com/t/86ex1g2u1) |
| Người yêu cầu | CS         |
| Team          | CS         |
| Ngày yêu cầu  | 2026-03-26 |
| Deadline      | ASAP       |
| Output format | CSV        |


## Mô tả

> anh Phương hỗ trợ export list report cho khách dopeskill [touch@dopeskillbrand.com](mailto:touch@dopeskillbrand.com) giúp em nha. Thông tin cần có: Tổng lượng đơn trong 2 quý, tính đến thời điểm hiện tại; Processing time; Shipping time các đơn hàng - shipping time trung bình trong mỗi tháng (nếu tách ra được theo từng shipping service thì càng tốt)

## Thông tin khách hàng / đối tượng


| Field             | Value                                                       |
| ----------------- | ----------------------------------------------------------- |
| Tên               | dopeskill                                                   |
| Email             | [touch@dopeskillbrand.com](mailto:touch@dopeskillbrand.com) |
| ID trong hệ thống | OMS: `cus_id = 11677`; POD: `team_id = '0Px0QS0P3YI'`       |


## Data cần xuất

- Query 1: Volume (orders + units) by month — Q4 2025 + Q1 2026
- Query 2: Processing time by month
- Query 3: Shipping time trung bình by month by shipping service

## Ghi chú

- V1/V2 (nh_order) + V3 (sc_order NOT LIKE 'TW-%') để exclude overlap
- V3 orders (sau 2026-03-18) chưa có trong fact_ofp → bỏ qua processing/shipping cho khoảng này
- sc_order_shipment KHÔNG có data cho dopeskill → dùng nh_tracking_shipments cho carrier/service
- Shipping service detail: trk_carrier + trk_service từ nh_tracking_shipments


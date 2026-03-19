# Reports POC Workspace

Workspace để POC báo cáo phân tích trước khi đưa lên Metabase.

## Workflow

```
1. Viết spec      →  spec.md: mục tiêu, dimensions, metrics, filters
2. SQL via MCP    →  viết & chạy SQL trực tiếp qua Claude Code MCP, không cần Python
3. Python visual  →  poc.ipynb: nhận kết quả query → Plotly / Matplotlib (không transform)
4. Submit         →  tạo báo cáo Metabase từ SQL đã verified, cập nhật spec status → "live"
```

### Nguyên tắc quan trọng

**Toàn bộ logic xử lý dữ liệu nằm trong SQL.**
Python chỉ làm một việc: vẽ chart từ DataFrame đã sẵn sàng.

Lý do: Metabase chạy SQL thuần — bất kỳ transform nào trong Python đều không thể reproduce trên Metabase.

## Cách Dùng ClickHouse qua MCP

Claude Code kết nối ClickHouse trực tiếp qua MCP. Để verify SQL:
1. Viết query trong Claude Code
2. Yêu cầu Claude chạy qua MCP và xem kết quả
3. Khi query đúng → lưu vào `reports/<report-name>/queries/main.sql`

Không cần cấu hình connection string trong Python cho bước verify SQL.

## Setup Python (chỉ cho visualization)

```bash
python -m venv .venv
source .venv/bin/activate

pip install -r requirements.txt
```

Notebook nhận data từ CSV export của MCP — không kết nối ClickHouse trực tiếp:

```python
import pandas as pd

# Load kết quả đã export từ MCP
df = pd.read_csv('queries/result.csv')

# Từ đây: chỉ vẽ, không transform df
```

Để export CSV từ MCP: yêu cầu Claude chạy query và save kết quả vào `queries/result.csv`.

## Workflow (OpenSpec Commands)

| Lệnh | Khi nào dùng |
|------|-------------|
| `/opsx:propose` | Tạo change mới (báo cáo mới hoặc thay đổi lớn) |
| `/opsx:apply` | Implement tasks từ change |
| `/opsx:archive` | Lưu trữ change đã hoàn thành |
| `/opsx:explore` | Khám phá ý tưởng trước khi commit vào change |

Gates: `discovery` → `draft` → `spec-confirmed` → `sql-verified` → `poc-done` → `biz-validated` → `production`

## Tạo Báo Cáo Mới

Dùng `/opsx:propose` để tạo change — Claude sẽ tạo artifacts và folder structure tự động.

Hoặc thủ công:

```bash
mkdir -p reports/<report-name>/queries
cp _templates/spec_template.md reports/<report-name>/spec.md
cp _templates/poc_template.ipynb reports/<report-name>/poc.ipynb
touch reports/<report-name>/changelog.md
# Cập nhật bảng báo cáo trong CLAUDE.md
```

## ClickHouse v25.0 — Lưu Ý Syntax

| Pattern | Đúng |
|---|---|
| Date truncate | `toStartOfMonth(dt)`, `toStartOfWeek(dt)` |
| Conditional agg | `sumIf(amount, status='done')`, `countIf(id, x > 0)` |
| Distinct count | `uniqExact(user_id)` |
| Null-safe | kiểm tra `Nullable(T)` — nhiều functions cần `assumeNotNull()` |
| Dedup table | thêm `FINAL` với `ReplacingMergeTree` |
| Window func | `lagInFrame() OVER (ORDER BY dt ROWS BETWEEN ...)` |

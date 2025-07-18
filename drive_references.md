# Google Drive File References for Plus Paid Analytics

## Quick Reference Patterns

### 1. **File ID Extraction**
From any Google Drive URL, extract the file ID:
- **URL**: `https://drive.google.com/file/d/1ABC123DEF456GHI789JKL/view`
- **File ID**: `1ABC123DEF456GHI789JKL`

### 2. **Common Reference Formats**

#### In SQL Comments:
```sql
-- Data Source: Google Drive
-- File: WBR_Revenue_Data_2024.xlsx
-- ID: 1ABC123DEF456GHI789JKL
-- Link: https://drive.google.com/file/d/1ABC123DEF456GHI789JKL/view
-- Last Updated: 2024-01-15
```

#### In Python Scripts:
```python
# Google Drive file references
DRIVE_FILES = {
    "wbr_revenue": "1ABC123DEF456GHI789JKL",
    "qbr_template": "2XYZ789ABC123DEF456GHI", 
    "dlv_reference": "3DEF456GHI789JKL123ABC"
}
```

#### In Documentation:
```markdown
## Data Sources
- **WBR Revenue Data**: [Google Drive](https://drive.google.com/file/d/1ABC123DEF456GHI789JKL/view) (ID: `1ABC123DEF456GHI789JKL`)
- **QBR Template**: [Google Drive](https://drive.google.com/file/d/2XYZ789ABC123DEF456GHI/view) (ID: `2XYZ789ABC123DEF456GHI`)
```

## 3. **Team-Specific References**

### WBR (Weekly Business Review)
- **Revenue Data**: `1ABC123DEF456GHI789JKL`
- **Lead Metrics**: `2XYZ789ABC123DEF456GHI`
- **Spend Data**: `3DEF456GHI789JKL123ABC`

### QBR (Quarterly Business Review)
- **Template**: `4GHI789JKL123ABC456DEF`
- **Historical Data**: `5JKL123ABC456DEF789GHI`

### DLV (Dollar Lead Value)
- **Reference Tables**: `6ABC456DEF789GHI123JKL`
- **Attribution Data**: `7DEF789GHI123JKL456ABC`

## 4. **Best Practices**

### File Naming Convention
```
{Report_Type}_{Data_Type}_{YYYY-MM-DD}.{extension}
Examples:
- WBR_Revenue_2024-01-15.xlsx
- QBR_Template_2024-Q1.pptx
- DLV_Reference_2024-01-15.csv
```

### Documentation Standards
- Always include both file ID and direct link
- Note last update date
- Specify file format and size if relevant
- Add brief description of contents

### Access Permissions
- Ensure team members have appropriate access
- Use shared drives for team-wide access
- Set up automated backups for critical files

## 5. **Integration Examples**

### Python Script Integration
```python
import pandas as pd
from google_drive_reference_example import load_csv_from_drive

# Load WBR data from Google Drive
wbr_data = load_csv_from_drive("1ABC123DEF456GHI789JKL")
print(f"Loaded {len(wbr_data)} rows from WBR data")
```

### SQL Query Integration
```sql
-- Reference external data from Google Drive
-- File: WBR_Revenue_Data_2024.xlsx
-- ID: 1ABC123DEF456GHI789JKL

WITH external_data AS (
  SELECT * FROM `external_table`  -- Replace with actual external table
  WHERE source_file = '1ABC123DEF456GHI789JKL'
)
SELECT 
  l.*,
  e.revenue_forecast
FROM `shopify-dw.sales.sales_leads` l
LEFT JOIN external_data e ON l.lead_id = e.lead_id
```

## 6. **Troubleshooting**

### Common Issues
1. **Permission Denied**: Check file sharing settings
2. **File Not Found**: Verify file ID is correct
3. **API Quota Exceeded**: Implement rate limiting
4. **Authentication Issues**: Refresh credentials

### File ID Validation
- File IDs are typically 33 characters long
- Contain alphanumeric characters and hyphens
- Can be extracted from any Google Drive URL

---

**Note**: Replace all example file IDs with actual IDs from your team's Google Drive files. 
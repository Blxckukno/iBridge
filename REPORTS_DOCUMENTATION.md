# iBridge Ticketing System - Reporting Feature Documentation

## Overview
The iBridge Ticketing System now includes a comprehensive reporting feature that generates professional Excel reports similar to the "Daily Impacts Report" format. This feature allows you to create detailed ticket reports for any custom timeframe.

## Features

### 1. **Excel Report Generation**
- Professional formatting matching the Daily Impacts Report template
- All columns from the original format:
  - Date & Date Received
  - Reference Number (REQ format)
  - Duty Manager (assigned user)
  - Priority (1-3 scale)
  - SLA tracking (1=met, 2=breached)
  - Status (Open, In Progress, Resolved)
  - Application/Category
  - Time tracking (Down time, Up time, Elapsed time)
  - Business Impact & Technical Description
  - Resolution details and Root Cause Analysis
  - Month Reported

### 2. **Flexible Date Range Selection**
- Quick presets: Today, Yesterday, This Week, This Month, Last 30 Days
- Custom date range selection
- Automatically validates date ranges

### 3. **Multiple Export Formats**
- **Excel (.xlsx)**: Full formatted report with styling
- **CSV**: Simple comma-separated format for data import
- **JSON**: Raw data for API integration

### 4. **Statistics Preview**
Before generating reports, view comprehensive statistics:
- Total tickets in date range
- Resolution rate and average resolution time
- Breakdown by status (Open, In Progress, Resolved, Closed)
- Breakdown by priority (Low, Medium, High, Critical)
- Breakdown by category

## How to Use

### Accessing Reports
1. **From Dashboard**: Click the "Reports" button in the action buttons section
2. **Direct URL**: Navigate to `TicketingSystem/frontend/reports.html`

### Generating a Report

#### Step 1: Select Date Range
Choose from quick presets or set custom dates:
```
Quick Presets:
- Today: Current day only
- Yesterday: Previous day
- This Week: From Sunday to today
- This Month: From 1st of current month to today
- Last 30 Days: Previous 30 days
```

Or manually enter:
- Start Date: Beginning of report period
- End Date: End of report period

#### Step 2: Preview Statistics (Optional)
Click **"Preview Statistics"** to see:
- Total ticket count
- Resolution metrics
- Category/Priority/Status breakdowns

This helps verify the date range before generating the full report.

#### Step 3: Generate Report
Choose your export format:
- **Download Excel Report**: Professional formatted .xlsx file
- **Download CSV**: Simple comma-separated values
- **JSON API**: Use for programmatic access

#### Step 4: Open/Analyze Report
The report will download automatically. Open in:
- Microsoft Excel
- Google Sheets
- LibreOffice Calc
- Any spreadsheet application

## Report Structure

### Excel Report Columns
| Column | Description | Example |
|--------|-------------|---------|
| Date | Ticket creation date | 15/01/2025 |
| Date Received | Same as creation date | 15/01/2025 |
| Reference Number | Unique ticket ID | REQ000000000001 |
| Duty Manager | Assigned technician | admin |
| Priority | 1=High/Critical, 2=Medium, 3=Low | 1 |
| SLA | 1=Met, 2=Breached | 1 |
| Inbridge/IT/MTN | Service provider | MTN |
| Repeat | Recurring issue flag | No |
| Status | Current ticket state | Resolved |
| I/A/N/T | Classification (Incident/Accident/Near miss/Theft) | A |
| Application | Category or system | Network |
| Reported By | Ticket creator | employee |
| Time Down | Issue start time | 09:15 |
| Time Up | Resolution time | 11:30 |
| Elapsed Time | Resolution duration | 02h15mins |
| Time experienced by business | Business impact duration | 02h15mins |
| Business Impact | High-level description | Users unable to access... |
| Technical Description | Detailed issue description | Network connectivity issue... |
| Resolved - Immediate Action | First response | Escalated to iBridge... |
| Resolved - By / Root Cause | Root cause explanation | Escalated to iBridge... |
| Root Cause Identified? | Y/N flag | Y |
| RCA Request | RCA status | Escalated to iBridge... |
| Month Reported | Report month | January 2025 |

### Styling
The Excel report includes:
- **Yellow header row** with bold text
- **Borders** on all cells
- **Wrapped text** for long descriptions
- **Frozen header row** for easy scrolling
- **Auto-sized columns** for readability

## API Endpoints

### 1. Generate Excel Report
```http
GET /api/reports/tickets?start_date=2025-01-01&end_date=2025-01-31&format=excel
Authorization: Bearer <jwt_token>
```

**Response**: Excel file download

**Parameters**:
- `start_date` (required): YYYY-MM-DD format
- `end_date` (required): YYYY-MM-DD format
- `format` (optional): "excel" or "json" (default: "excel")

### 2. Generate CSV Report
```http
GET /api/reports/tickets/csv?start_date=2025-01-01&end_date=2025-01-31
Authorization: Bearer <jwt_token>
```

**Response**: CSV file download

### 3. Get Statistics Preview
```http
GET /api/reports/statistics?start_date=2025-01-01&end_date=2025-01-31
Authorization: Bearer <jwt_token>
```

**Response**: JSON object with statistics
```json
{
  "date_range": {
    "start": "2025-01-01",
    "end": "2025-01-31"
  },
  "total_tickets": 45,
  "resolved_tickets": 32,
  "resolution_rate": 71.11,
  "avg_resolution_time_hours": 12.5,
  "status_breakdown": {
    "open": 5,
    "in-progress": 8,
    "resolved": 25,
    "closed": 7
  },
  "priority_breakdown": {
    "low": 10,
    "medium": 20,
    "high": 12,
    "critical": 3
  },
  "category_breakdown": {
    "Network": 15,
    "Hardware": 10,
    "Software": 12,
    "Security": 8
  }
}
```

## Technical Details

### Backend Components
1. **reports.py**: Report generation module
   - `generate_report_data()`: Processes tickets into report format
   - `create_excel_report()`: Builds Excel file with openpyxl
   - `calculate_time_metrics()`: Calculates duration metrics

2. **app.py**: Flask application
   - Registers reports blueprint
   - Provides authentication

### Frontend Components
1. **reports.html**: Report generation interface
   - Date range selection
   - Statistics preview
   - Export buttons

2. **professional-dashboard.html**: Added "Reports" button

### Dependencies
- **openpyxl**: Excel file generation
- **Flask**: Web framework
- **Flask-JWT-Extended**: Authentication
- **SQLAlchemy**: Database queries

## SLA Calculation Logic

```python
Priority Levels:
- High/Critical: 4 hours (240 minutes)
- Medium: 8 hours (480 minutes)
- Low: 24 hours (1440 minutes)

SLA Status:
- 1 = Within SLA (resolved within time limit)
- 2 = Breached SLA (exceeded time limit)
```

## Customization

### Modifying Report Format
Edit `backend/reports.py`:

```python
# Change column headers
headers = [
    'Custom Column 1',
    'Custom Column 2',
    # ... add/remove columns
]

# Modify data mapping
row = {
    'custom_field': ticket.custom_attribute,
    # ... add custom fields
}
```

### Changing SLA Thresholds
Edit SLA limits in `calculate_time_metrics()`:

```python
sla_limits = {
    'high': 240,      # 4 hours
    'critical': 240,  # 4 hours
    'medium': 480,    # 8 hours
    'low': 1440       # 24 hours
}
```

## Troubleshooting

### Issue: "Not authenticated" error
**Solution**: Make sure you're logged in before accessing reports

### Issue: No tickets in date range
**Solution**: 
1. Verify tickets exist in database
2. Expand date range
3. Check date format (YYYY-MM-DD)

### Issue: Excel file won't open
**Solution**: 
1. Ensure you have Excel or compatible software
2. Check file wasn't corrupted during download
3. Try CSV format instead

### Issue: Statistics not loading
**Solution**:
1. Check network connection
2. Verify backend server is running on http://127.0.0.1:5000
3. Check browser console for errors

## Testing

### Test with Sample Data
Run the sample tickets script:
```bash
cd backend
python add_sample_tickets.py
```

This creates 15 diverse tickets over a 60-day period with various:
- Priorities (low, medium, high, critical)
- Statuses (open, in-progress, resolved, closed)
- Categories (Network, Hardware, Software, etc.)
- Resolution times (1-48 hours)

### Manual Testing Checklist
- [ ] Login to dashboard
- [ ] Navigate to Reports page
- [ ] Select "Last 30 Days" preset
- [ ] Click "Preview Statistics"
- [ ] Verify statistics display correctly
- [ ] Click "Download Excel Report"
- [ ] Open downloaded Excel file
- [ ] Verify formatting matches template
- [ ] Check all columns are populated
- [ ] Test custom date range
- [ ] Download CSV format
- [ ] Test with no tickets in range

## Future Enhancements

Potential improvements:
1. **Scheduled Reports**: Automatic daily/weekly reports via email
2. **Chart Visualization**: Add graphs to Excel reports
3. **PDF Export**: Generate PDF reports
4. **Report Templates**: Multiple report formats
5. **Custom Filters**: Filter by category, priority, assignee
6. **Trend Analysis**: Compare periods over time
7. **Email Reports**: Send reports directly to stakeholders
8. **Report History**: Track generated reports
9. **Advanced Analytics**: Machine learning insights

## Support

For issues or questions:
- Check troubleshooting section above
- Review API documentation
- Contact system administrator
- Check backend logs for errors

## Version History

**v1.0.0** (Current)
- Initial release
- Excel report generation
- CSV export
- Statistics preview
- Date range selection
- SLA tracking
- Complete Daily Impacts Report format

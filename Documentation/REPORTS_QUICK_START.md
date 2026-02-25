# iBridge Ticketing Reports - Quick Start Guide

## 🚀 Getting Started

### 1. Access Reports
- Open Dashboard: `TicketingSystem/frontend/professional-dashboard.html`
- Click **"Reports"** button (chart icon)
- Or direct: `TicketingSystem/frontend/reports.html`

### 2. Generate Your First Report

**Option A: Quick Preset**
```
1. Click "Last 30 Days" button
2. Click "Download Excel Report"
3. Open the downloaded .xlsx file
```

**Option B: Custom Date Range**
```
1. Select Start Date (e.g., 2025-01-01)
2. Select End Date (e.g., 2025-01-31)
3. Click "Preview Statistics" (optional)
4. Click "Download Excel Report"
```

## 📊 What You Get

### Excel Report Includes:
✅ All ticket details in Daily Impacts Report format
✅ Professional yellow-header formatting
✅ Time tracking (down time, up time, elapsed)
✅ SLA compliance tracking
✅ Root cause analysis fields
✅ Business impact descriptions
✅ Auto-sized columns and frozen headers

### Statistics Preview Shows:
- Total tickets in date range
- Resolution rate percentage
- Average resolution time
- Breakdown by status/priority/category

## 🎯 Common Use Cases

### Daily Report
```
Preset: "Today"
Purpose: End-of-day summary
Audience: Team leads, duty managers
```

### Weekly Review
```
Preset: "This Week"
Purpose: Weekly team meeting
Audience: Department managers
```

### Monthly Performance
```
Preset: "This Month"
Purpose: Performance metrics
Audience: Executive team
```

### Incident Analysis
```
Custom: Select incident date range
Purpose: Post-incident review
Audience: Technical team
```

## 🔧 API Quick Reference

### Excel Download
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
  "http://127.0.0.1:5000/api/reports/tickets?start_date=2025-01-01&end_date=2025-01-31&format=excel" \
  -o report.xlsx
```

### Statistics JSON
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
  "http://127.0.0.1:5000/api/reports/statistics?start_date=2025-01-01&end_date=2025-01-31"
```

### CSV Export
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
  "http://127.0.0.1:5000/api/reports/tickets/csv?start_date=2025-01-01&end_date=2025-01-31" \
  -o report.csv
```

## ⚡ Tips & Tricks

### 1. Best Practices
- Preview statistics before generating large reports
- Use presets for common date ranges
- Export to CSV for data analysis in other tools
- Schedule regular report generation

### 2. Performance
- Large date ranges (>90 days) may take longer
- Preview statistics first for very large datasets
- Use CSV for faster exports of large data

### 3. Analysis
- Import CSV into Excel for pivot tables
- Use filters on Excel reports for specific categories
- Compare reports across different time periods
- Track SLA compliance trends

## 🐛 Quick Fixes

### Problem: Can't access reports
✅ Solution: Login first (admin/admin123)

### Problem: No tickets in report
✅ Solution: Expand date range or check ticket dates

### Problem: Download not starting
✅ Solution: Check if backend is running (http://127.0.0.1:5000)

### Problem: Excel won't open
✅ Solution: Try CSV format or check Excel installation

## 📞 Need Help?

1. Check full documentation: `REPORTS_DOCUMENTATION.md`
2. Verify backend is running: Navigate to http://127.0.0.1:5000
3. Check browser console (F12) for errors
4. Review backend logs in terminal

## 🎉 Sample Workflow

**Morning Dashboard Review:**
```
1. Login to dashboard
2. Click "Reports"
3. Select "Yesterday"
4. Click "Preview Statistics"
5. Review: How many tickets? How many resolved?
6. Download Excel if needed for meeting
```

**End of Week Report:**
```
1. Friday afternoon: Click "Reports"
2. Select "This Week"
3. Download Excel Report
4. Email to team leads
5. Use statistics for weekly meeting
```

**Monthly Management Report:**
```
1. First of month: Click "Reports"
2. Select last month's date range
3. Preview statistics
4. Download Excel for management review
5. Include in monthly KPI report
```

---

## Server Commands

### Start Backend
```powershell
cd 'c:\Users\Lwandile Gasela\iBridge\backend'
& 'C:/Users/Lwandile Gasela/iBridge/.venv/Scripts/python.exe' app.py
```

### Add Test Data
```powershell
cd 'c:\Users\Lwandile Gasela\iBridge\backend'
& 'C:/Users/Lwandile Gasela/iBridge/.venv/Scripts/python.exe' add_sample_tickets.py
```

### Stop Backend
```powershell
$process = Get-Process python -ErrorAction SilentlyContinue | Where-Object {$_.Path -like '*iBridge\.venv*'}
if ($process) { Stop-Process -Id $process.Id -Force }
```

---

**Current Status:**
- ✅ Backend running on http://127.0.0.1:5000
- ✅ 19 tickets in database (Sept-Oct 2025)
- ✅ Reports feature fully operational
- ✅ Login: admin/admin123 or employee/employee123

**Quick Test:**
1. Open: http://127.0.0.1:5000/../TicketingSystem/frontend/reports.html
2. Login if prompted
3. Click "Last 30 Days"
4. Click "Download Excel Report"
5. Enjoy! 🎊

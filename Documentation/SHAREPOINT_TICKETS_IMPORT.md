# SharePoint Ticket Import

Your Staff Portal dashboard now reads ticket data from:

- `Website/data/sharepoint-tickets.json`

Use this workflow to sync your current SharePoint list.

## 1) Export tickets from SharePoint

From your list:

- `https://ibridgecoza.sharepoint.com/sites/iBridgeITSupport/Lists/Tickets/AllItems.aspx`

Use **Export to Excel / CSV** and save the file locally.

## 2) Convert CSV to portal JSON

Run from project root:

```powershell
powershell -ExecutionPolicy Bypass -File AutomationScripts\import-sharepoint-tickets.ps1 -CsvPath "C:\path\to\Tickets.csv"
```

Optional custom output path:

```powershell
powershell -ExecutionPolicy Bypass -File AutomationScripts\import-sharepoint-tickets.ps1 -CsvPath "C:\path\to\Tickets.csv" -OutputPath "Website\data\sharepoint-tickets.json"
```

## 3) Refresh portal

- Open/reload: `Website/TicketingSystem/frontend/professional-dashboard.html`
- Hard refresh: `Ctrl+F5`

The dashboard will update:

- Active Tickets count
- Recent Ticket Activity list

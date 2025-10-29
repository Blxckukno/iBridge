#!/usr/bin/env python3
"""
iBridge Ticketing System - Report Generation Module
Generates detailed impact reports similar to Excel format
"""

from datetime import datetime, timedelta
from flask import Blueprint, request, jsonify, send_file
from flask_jwt_extended import jwt_required, get_jwt_identity
import io
import csv
from openpyxl import Workbook
from openpyxl.styles import PatternFill, Font, Alignment, Border, Side
from openpyxl.utils import get_column_letter

reports_bp = Blueprint('reports', __name__)

def calculate_time_metrics(ticket):
    """Calculate time-related metrics for a ticket"""
    created_at = ticket.created_at
    resolved_at = ticket.resolved_at
    
    time_down = None
    time_up = None
    elapsed_time = None
    time_experienced = None
    
    if resolved_at and created_at:
        elapsed_time = resolved_at - created_at
        elapsed_minutes = int(elapsed_time.total_seconds() / 60)
        
        # Format as HH:MM
        hours = elapsed_minutes // 60
        minutes = elapsed_minutes % 60
        elapsed_time_str = f"{hours:02d}h{minutes:02d}mins"
        
        # For demonstration, using same times
        # In production, these would be tracked separately
        time_down = created_at.strftime('%H:%M')
        time_up = resolved_at.strftime('%H:%M')
        time_experienced = elapsed_time_str
        
        return {
            'time_down': time_down,
            'time_up': time_up,
            'elapsed_time': elapsed_minutes,
            'elapsed_time_formatted': elapsed_time_str,
            'time_experienced': elapsed_time_str
        }
    
    return {
        'time_down': None,
        'time_up': None,
        'elapsed_time': None,
        'elapsed_time_formatted': None,
        'time_experienced': None
    }

def generate_report_data(tickets, start_date, end_date):
    """Generate report data from tickets"""
    report_data = []
    
    for ticket in tickets:
        time_metrics = calculate_time_metrics(ticket)
        
        # Get assigned user info
        assigned_to = ticket.assigned_to_user if hasattr(ticket, 'assigned_to_user') else None
        duty_manager = assigned_to.username if assigned_to else 'Unassigned'
        
        # Get created by user info
        created_by = ticket.created_by_user if hasattr(ticket, 'created_by_user') else None
        reported_by = created_by.username if created_by else 'Unknown'
        
        # Map priority
        priority_map = {'low': 3, 'medium': 2, 'high': 1, 'critical': 1}
        priority = priority_map.get(ticket.priority.lower(), 1) if ticket.priority else 1
        
        # Map status
        status_map = {
            'open': 'Open',
            'in-progress': 'In Progress',
            'resolved': 'Resolved',
            'closed': 'Resolved'
        }
        status = status_map.get(ticket.status.lower(), ticket.status)
        
        # SLA calculation (1 = within SLA, more = breached)
        sla = 1  # Default within SLA
        if time_metrics['elapsed_time']:
            # High priority should be resolved within 4 hours (240 mins)
            # Medium within 8 hours, Low within 24 hours
            sla_limits = {'high': 240, 'critical': 240, 'medium': 480, 'low': 1440}
            limit = sla_limits.get(ticket.priority.lower(), 480)
            if time_metrics['elapsed_time'] > limit:
                sla = 2  # Breached
        
        row = {
            'date': ticket.created_at.strftime('%d/%m/%Y'),
            'date_received': ticket.created_at.strftime('%d/%m/%Y'),
            'reference_number': f"REQ{str(ticket.id).zfill(12)}",
            'duty_manager': duty_manager,
            'priority': priority,
            'sla': sla,
            'inbridge_it_mtn': 'MTN',  # Default value, can be customized
            'repeat': 'No',  # Can be calculated based on similar issues
            'status': status,
            'i_a_n_t': 'A',  # Incident/Accident/Near miss/Theft classification
            'application': ticket.category or 'General',
            'reported_by': reported_by,
            'time_down': time_metrics['time_down'],
            'time_up': time_metrics['time_up'],
            'elapsed_time': time_metrics['elapsed_time_formatted'],
            'time_experienced': time_metrics['time_experienced'],
            'business_impact': ticket.description[:100] if ticket.description else '',
            'technical_description': ticket.description if ticket.description else '',
            'resolved_immediate_action': 'Escalated to iBridge Escalations for assistance',
            'resolved_by_root_cause': 'Escalated to iBridge Escalations for assistance',
            'root_cause_identified': 'Y' if status == 'Resolved' else 'N',
            'rca_request': 'Escalated to iBridge Escalations for RCA',
            'month_reported': ticket.created_at.strftime('%B %Y')
        }
        
        report_data.append(row)
    
    return report_data

def create_excel_report(report_data, start_date, end_date):
    """Create Excel report with formatting similar to the template"""
    wb = Workbook()
    ws = wb.active
    ws.title = "Daily Impacts Report"
    
    # Define column headers matching the template
    headers = [
        'Date', 'Date Received', 'Reference Number', 'Duty Manager', 'Priority', 'SLA',
        'Inbridge/IT/MTN', 'Repeat', 'Status', 'I/A/N/T', 'Application', 'Reported By',
        'Time Down', 'Time Up', 'Elapsed Time (minutes)', 'Time experienced by the business',
        'Business Impact', 'Technical Description', 'Resolved - Immediate Action',
        'Resolved - By / Root Cause Identified?', 'Root Cause Identified? Y/N',
        'RCA Request', 'Month Reported'
    ]
    
    # Header styling - Yellow background
    header_fill = PatternFill(start_color='FFFF00', end_color='FFFF00', fill_type='solid')
    header_font = Font(bold=True, size=10)
    header_alignment = Alignment(horizontal='center', vertical='center', wrap_text=True)
    border = Border(
        left=Side(style='thin'),
        right=Side(style='thin'),
        top=Side(style='thin'),
        bottom=Side(style='thin')
    )
    
    # Write headers
    for col_num, header in enumerate(headers, 1):
        cell = ws.cell(row=1, column=col_num)
        cell.value = header
        cell.fill = header_fill
        cell.font = header_font
        cell.alignment = header_alignment
        cell.border = border
    
    # Write data rows
    for row_num, data in enumerate(report_data, 2):
        ws.cell(row=row_num, column=1, value=data['date'])
        ws.cell(row=row_num, column=2, value=data['date_received'])
        ws.cell(row=row_num, column=3, value=data['reference_number'])
        ws.cell(row=row_num, column=4, value=data['duty_manager'])
        ws.cell(row=row_num, column=5, value=data['priority'])
        ws.cell(row=row_num, column=6, value=data['sla'])
        ws.cell(row=row_num, column=7, value=data['inbridge_it_mtn'])
        ws.cell(row=row_num, column=8, value=data['repeat'])
        ws.cell(row=row_num, column=9, value=data['status'])
        ws.cell(row=row_num, column=10, value=data['i_a_n_t'])
        ws.cell(row=row_num, column=11, value=data['application'])
        ws.cell(row=row_num, column=12, value=data['reported_by'])
        ws.cell(row=row_num, column=13, value=data['time_down'])
        ws.cell(row=row_num, column=14, value=data['time_up'])
        ws.cell(row=row_num, column=15, value=data['elapsed_time'])
        ws.cell(row=row_num, column=16, value=data['time_experienced'])
        ws.cell(row=row_num, column=17, value=data['business_impact'])
        ws.cell(row=row_num, column=18, value=data['technical_description'])
        ws.cell(row=row_num, column=19, value=data['resolved_immediate_action'])
        ws.cell(row=row_num, column=20, value=data['resolved_by_root_cause'])
        ws.cell(row=row_num, column=21, value=data['root_cause_identified'])
        ws.cell(row=row_num, column=22, value=data['rca_request'])
        ws.cell(row=row_num, column=23, value=data['month_reported'])
        
        # Apply borders to all cells
        for col_num in range(1, len(headers) + 1):
            ws.cell(row=row_num, column=col_num).border = border
            ws.cell(row=row_num, column=col_num).alignment = Alignment(vertical='top', wrap_text=True)
    
    # Adjust column widths
    column_widths = {
        'A': 12, 'B': 12, 'C': 18, 'D': 15, 'E': 8, 'F': 6,
        'G': 12, 'H': 8, 'I': 10, 'J': 8, 'K': 15, 'L': 15,
        'M': 10, 'N': 10, 'O': 12, 'P': 12, 'Q': 30, 'R': 30,
        'S': 25, 'T': 25, 'U': 12, 'V': 20, 'W': 15
    }
    
    for col, width in column_widths.items():
        ws.column_dimensions[col].width = width
    
    # Set row height for header
    ws.row_dimensions[1].height = 30
    
    # Freeze the header row
    ws.freeze_panes = 'A2'
    
    return wb

@reports_bp.route('/api/reports/tickets', methods=['GET'])
@jwt_required()
def generate_ticket_report():
    """Generate ticket report for specified date range"""
    try:
        from app import Ticket, User
        
        # Get date range from query parameters
        start_date_str = request.args.get('start_date')
        end_date_str = request.args.get('end_date')
        format_type = request.args.get('format', 'excel')  # excel or json
        
        # Parse dates or use defaults
        if start_date_str:
            start_date = datetime.strptime(start_date_str, '%Y-%m-%d')
        else:
            # Default to last 30 days
            start_date = datetime.utcnow() - timedelta(days=30)
        
        if end_date_str:
            end_date = datetime.strptime(end_date_str, '%Y-%m-%d')
        else:
            end_date = datetime.utcnow()
        
        # Add end of day to end_date
        end_date = end_date.replace(hour=23, minute=59, second=59)
        
        # Query tickets in date range
        from sqlalchemy.orm import joinedload
        tickets = Ticket.query.options(
            joinedload(Ticket.created_by_user),
            joinedload(Ticket.assigned_to_user)
        ).filter(
            Ticket.created_at >= start_date,
            Ticket.created_at <= end_date
        ).order_by(Ticket.created_at.asc()).all()
        
        if not tickets:
            return jsonify({
                'message': 'No tickets found in the specified date range',
                'start_date': start_date.strftime('%Y-%m-%d'),
                'end_date': end_date.strftime('%Y-%m-%d'),
                'count': 0
            }), 200
        
        # Generate report data
        report_data = generate_report_data(tickets, start_date, end_date)
        
        # Return based on format
        if format_type == 'json':
            return jsonify({
                'start_date': start_date.strftime('%Y-%m-%d'),
                'end_date': end_date.strftime('%Y-%m-%d'),
                'total_tickets': len(report_data),
                'data': report_data
            }), 200
        
        elif format_type == 'excel':
            # Create Excel file
            wb = create_excel_report(report_data, start_date, end_date)
            
            # Save to BytesIO
            output = io.BytesIO()
            wb.save(output)
            output.seek(0)
            
            # Generate filename
            filename = f"iBridge_Daily_Impacts_Report_{start_date.strftime('%Y%m%d')}-{end_date.strftime('%Y%m%d')}.xlsx"
            
            return send_file(
                output,
                mimetype='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                as_attachment=True,
                download_name=filename
            )
        
        else:
            return jsonify({'error': 'Invalid format type. Use "excel" or "json"'}), 400
            
    except Exception as e:
        return jsonify({'error': 'Report generation failed', 'details': str(e)}), 500

@reports_bp.route('/api/reports/tickets/csv', methods=['GET'])
@jwt_required()
def generate_ticket_report_csv():
    """Generate ticket report in CSV format"""
    try:
        from app import Ticket, User
        
        # Get date range
        start_date_str = request.args.get('start_date')
        end_date_str = request.args.get('end_date')
        
        if start_date_str:
            start_date = datetime.strptime(start_date_str, '%Y-%m-%d')
        else:
            start_date = datetime.utcnow() - timedelta(days=30)
        
        if end_date_str:
            end_date = datetime.strptime(end_date_str, '%Y-%m-%d')
        else:
            end_date = datetime.utcnow()
        
        end_date = end_date.replace(hour=23, minute=59, second=59)
        
        # Query tickets
        from sqlalchemy.orm import joinedload
        tickets = Ticket.query.options(
            joinedload(Ticket.created_by_user),
            joinedload(Ticket.assigned_to_user)
        ).filter(
            Ticket.created_at >= start_date,
            Ticket.created_at <= end_date
        ).order_by(Ticket.created_at.asc()).all()
        
        # Generate report data
        report_data = generate_report_data(tickets, start_date, end_date)
        
        # Create CSV
        output = io.StringIO()
        if report_data:
            writer = csv.DictWriter(output, fieldnames=report_data[0].keys())
            writer.writeheader()
            writer.writerows(report_data)
        
        # Convert to bytes
        csv_output = io.BytesIO()
        csv_output.write(output.getvalue().encode('utf-8'))
        csv_output.seek(0)
        
        filename = f"iBridge_Tickets_Report_{start_date.strftime('%Y%m%d')}-{end_date.strftime('%Y%m%d')}.csv"
        
        return send_file(
            csv_output,
            mimetype='text/csv',
            as_attachment=True,
            download_name=filename
        )
        
    except Exception as e:
        return jsonify({'error': 'CSV generation failed', 'details': str(e)}), 500

@reports_bp.route('/api/reports/statistics', methods=['GET'])
@jwt_required()
def get_report_statistics():
    """Get statistics for report preview"""
    try:
        from app import Ticket
        from sqlalchemy import func
        
        # Get date range
        start_date_str = request.args.get('start_date')
        end_date_str = request.args.get('end_date')
        
        if start_date_str:
            start_date = datetime.strptime(start_date_str, '%Y-%m-%d')
        else:
            start_date = datetime.utcnow() - timedelta(days=30)
        
        if end_date_str:
            end_date = datetime.strptime(end_date_str, '%Y-%m-%d')
        else:
            end_date = datetime.utcnow()
        
        end_date = end_date.replace(hour=23, minute=59, second=59)
        
        # Get statistics
        base_query = Ticket.query.filter(
            Ticket.created_at >= start_date,
            Ticket.created_at <= end_date
        )
        
        total_tickets = base_query.count()
        
        # By status
        status_breakdown = base_query.with_entities(
            Ticket.status,
            func.count(Ticket.id)
        ).group_by(Ticket.status).all()
        
        # By priority
        priority_breakdown = base_query.with_entities(
            Ticket.priority,
            func.count(Ticket.id)
        ).group_by(Ticket.priority).all()
        
        # By category
        category_breakdown = base_query.with_entities(
            Ticket.category,
            func.count(Ticket.id)
        ).group_by(Ticket.category).all()
        
        # Average resolution time
        resolved_tickets = base_query.filter(Ticket.resolved_at.isnot(None)).all()
        avg_resolution_time = None
        if resolved_tickets:
            total_time = sum([
                (t.resolved_at - t.created_at).total_seconds() / 3600 
                for t in resolved_tickets
            ])
            avg_resolution_time = round(total_time / len(resolved_tickets), 2)
        
        return jsonify({
            'date_range': {
                'start': start_date.strftime('%Y-%m-%d'),
                'end': end_date.strftime('%Y-%m-%d')
            },
            'total_tickets': total_tickets,
            'status_breakdown': {status: count for status, count in status_breakdown},
            'priority_breakdown': {priority: count for priority, count in priority_breakdown},
            'category_breakdown': {category or 'Uncategorized': count for category, count in category_breakdown},
            'avg_resolution_time_hours': avg_resolution_time,
            'resolved_tickets': len(resolved_tickets),
            'resolution_rate': round((len(resolved_tickets) / total_tickets * 100), 2) if total_tickets > 0 else 0
        }), 200
        
    except Exception as e:
        return jsonify({'error': 'Statistics generation failed', 'details': str(e)}), 500

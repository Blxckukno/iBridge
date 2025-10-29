#!/usr/bin/env python3
"""
Add sample tickets for testing report generation
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app import app, db, Ticket, User
from datetime import datetime, timedelta
import random

def add_sample_tickets():
    with app.app_context():
        # Get or create users
        admin = User.query.filter_by(username='admin').first()
        employee = User.query.filter_by(username='employee').first()
        
        if not admin or not employee:
            print("Error: Users not found. Run init_db first.")
            return
        
        # Sample ticket data
        titles = [
            "Network connectivity issue in office",
            "Printer not working on 3rd floor",
            "Email server slow response",
            "VPN connection dropping frequently",
            "Software installation request - Photoshop",
            "Password reset for user account",
            "Database backup failed",
            "Website loading slowly",
            "Mobile app crash on login",
            "Security alert - suspicious activity",
            "Hardware replacement - monitor",
            "File server access denied",
            "Video conferencing audio issues",
            "System performance degradation",
            "License renewal required"
        ]
        
        descriptions = [
            "Users unable to access shared drives and network resources",
            "Printer showing offline status, needs immediate attention",
            "Email delivery delayed by several hours",
            "VPN disconnects every 10-15 minutes, affecting remote work",
            "Design team requires Photoshop for new project",
            "User forgot password and cannot access system",
            "Automated backup job failed with error code 500",
            "Homepage takes 30+ seconds to load",
            "App crashes immediately after entering credentials",
            "Multiple failed login attempts detected from unknown IP",
            "Monitor flickering and displaying artifacts",
            "User cannot access department folder, permission issue",
            "Audio cuts out during Teams meetings",
            "Server response time increased to 5+ seconds",
            "Software license expires in 7 days"
        ]
        
        categories = ['Network', 'Hardware', 'Software', 'Security', 'Email', 'Database', 'Web']
        priorities = ['low', 'medium', 'high', 'critical']
        statuses = ['open', 'in-progress', 'resolved', 'closed']
        
        # Create tickets over the past 60 days
        tickets_created = 0
        base_date = datetime.utcnow() - timedelta(days=60)
        
        for i in range(len(titles)):
            # Randomize creation date within last 60 days
            days_offset = random.randint(0, 59)
            hours_offset = random.randint(0, 23)
            minutes_offset = random.randint(0, 59)
            
            created_at = base_date + timedelta(
                days=days_offset,
                hours=hours_offset,
                minutes=minutes_offset
            )
            
            # Assign random properties
            priority = random.choice(priorities)
            status = random.choice(statuses)
            category = random.choice(categories)
            created_by = random.choice([admin.id, employee.id])
            assigned_to = random.choice([admin.id, employee.id]) if random.random() > 0.3 else None
            
            # Calculate resolved_at for resolved/closed tickets
            resolved_at = None
            if status in ['resolved', 'closed']:
                # Resolve within 1-48 hours after creation
                resolution_hours = random.randint(1, 48)
                resolved_at = created_at + timedelta(hours=resolution_hours)
            
            # Check if ticket already exists
            existing = Ticket.query.filter_by(title=titles[i]).first()
            if existing:
                print(f"Skipping existing ticket: {titles[i]}")
                continue
            
            ticket = Ticket(
                title=titles[i],
                description=descriptions[i],
                priority=priority,
                status=status,
                category=category,
                created_by=created_by,
                assigned_to=assigned_to,
                created_at=created_at,
                updated_at=created_at,
                resolved_at=resolved_at
            )
            
            db.session.add(ticket)
            tickets_created += 1
            print(f"Created: {titles[i]} - {status} ({priority}) - {created_at.strftime('%Y-%m-%d')}")
        
        db.session.commit()
        print(f"\n✅ Successfully created {tickets_created} sample tickets!")
        print(f"📊 Total tickets in database: {Ticket.query.count()}")
        
        # Show date range
        earliest = Ticket.query.order_by(Ticket.created_at.asc()).first()
        latest = Ticket.query.order_by(Ticket.created_at.desc()).first()
        if earliest and latest:
            print(f"📅 Date range: {earliest.created_at.strftime('%Y-%m-%d')} to {latest.created_at.strftime('%Y-%m-%d')}")

if __name__ == '__main__':
    add_sample_tickets()

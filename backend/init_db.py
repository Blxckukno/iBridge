#!/usr/bin/env python3
"""
iBridge Database Initialization Script
Creates SQLite database and populates with test data
"""

import os
import sys
from datetime import datetime, timedelta

# Add current directory to Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app import app, db, User, Ticket, Course, UserProgress
from werkzeug.security import generate_password_hash

def create_database():
    """Create database tables"""
    print("Creating database tables...")
    
    with app.app_context():
        # Drop all tables first (fresh start)
        db.drop_all()
        
        # Create all tables
        db.create_all()
        
        print("✅ Database tables created successfully!")

def create_test_users():
    """Create test users for the system"""
    print("\nCreating test users...")
    
    users_data = [
        {
            'username': 'admin',
            'email': 'admin@ibridge.co.za',
            'password': 'admin123',
            'role': 'admin'
        },
        {
            'username': 'johndoe',
            'email': 'john.doe@ibridge.co.za',
            'password': 'password123',
            'role': 'employee'
        },
        {
            'username': 'jansmith',
            'email': 'jane.smith@ibridge.co.za',
            'password': 'password123',
            'role': 'employee'
        },
        {
            'username': 'mikejohnson',
            'email': 'mike.johnson@ibridge.co.za',
            'password': 'password123',
            'role': 'employee'
        }
    ]
    
    with app.app_context():
        for user_data in users_data:
            # Check if user already exists
            existing_user = User.query.filter_by(email=user_data['email']).first()
            if existing_user:
                print(f"   User {user_data['username']} already exists, skipping...")
                continue
            
            user = User(
                username=user_data['username'],
                email=user_data['email'],
                password_hash=generate_password_hash(user_data['password']),
                role=user_data['role'],
                department='IT',  # Default department
                is_active=True
            )
            
            db.session.add(user)
            print(f"   ✅ Created user: {user_data['username']} ({user_data['email']})")
        
        db.session.commit()
        print("✅ Test users created successfully!")

def create_test_courses():
    """Create test courses for the LMS"""
    print("\nCreating test courses...")
    
    courses_data = [
        {
            'title': 'Web Development Fundamentals',
            'description': 'Learn HTML, CSS, JavaScript, and modern web development practices from scratch.',
            'category': 'Technology',
            'level': 'Beginner',
            'duration': 40,
            'modules': [
                {'title': 'HTML Basics', 'duration': '45 min', 'order': 1},
                {'title': 'CSS Styling', 'duration': '60 min', 'order': 2},
                {'title': 'JavaScript Fundamentals', 'duration': '90 min', 'order': 3},
                {'title': 'JavaScript Functions', 'duration': '75 min', 'order': 4},
                {'title': 'DOM Manipulation', 'duration': '80 min', 'order': 5},
                {'title': 'Event Handling', 'duration': '70 min', 'order': 6},
                {'title': 'Final Project', 'duration': '120 min', 'order': 7}
            ]
        },
        {
            'title': 'Data Science & Analytics',
            'description': 'Master data analysis, visualization, and machine learning with Python and R.',
            'category': 'Data Science',
            'level': 'Intermediate',
            'duration': 60,
            'modules': [
                {'title': 'Introduction to Data Science', 'duration': '50 min', 'order': 1},
                {'title': 'Python for Data Analysis', 'duration': '85 min', 'order': 2},
                {'title': 'Data Visualization with Python', 'duration': '95 min', 'order': 3},
                {'title': 'Statistical Analysis', 'duration': '100 min', 'order': 4},
                {'title': 'Machine Learning Basics', 'duration': '120 min', 'order': 5},
                {'title': 'Advanced ML Algorithms', 'duration': '110 min', 'order': 6},
                {'title': 'Capstone Project', 'duration': '180 min', 'order': 7}
            ]
        },
        {
            'title': 'Cybersecurity Essentials',
            'description': 'Learn to protect systems and networks from digital attacks and security threats.',
            'category': 'Security',
            'level': 'Advanced',
            'duration': 35,
            'modules': [
                {'title': 'Security Fundamentals', 'duration': '40 min', 'order': 1},
                {'title': 'Network Security', 'duration': '65 min', 'order': 2},
                {'title': 'Threat Detection', 'duration': '70 min', 'order': 3},
                {'title': 'Incident Response', 'duration': '55 min', 'order': 4},
                {'title': 'Security Tools', 'duration': '80 min', 'order': 5},
                {'title': 'Best Practices', 'duration': '45 min', 'order': 6},
                {'title': 'Final Assessment', 'duration': '60 min', 'order': 7}
            ]
        }
    ]
    
    with app.app_context():
        for course_data in courses_data:
            # Check if course already exists
            existing_course = Course.query.filter_by(title=course_data['title']).first()
            if existing_course:
                print(f"   Course '{course_data['title']}' already exists, skipping...")
                continue
            
            course = Course(
                title=course_data['title'],
                description=course_data['description'],
                category=course_data['category'],
                difficulty=course_data['level'].lower(),
                duration_hours=course_data['duration'],
                instructor='iBridge Training Team',
                is_active=True
            )
            
            db.session.add(course)
            print(f"   ✅ Created course: {course_data['title']}")
        
        db.session.commit()
        print("✅ Test courses created successfully!")

def create_test_tickets():
    """Create test tickets for the ticketing system"""
    print("\nCreating test tickets...")
    
    with app.app_context():
        # Get users for ticket assignment
        users = User.query.all()
        if not users:
            print("   No users found, skipping ticket creation...")
            return
        
        tickets_data = [
            {
                'title': 'Email server not responding',
                'description': 'Unable to send or receive emails since this morning. Need urgent assistance.',
                'priority': 'high',
                'category': 'technical',
                'status': 'open'
            },
            {
                'title': 'Password reset request',
                'description': 'Need to reset my password for the main system. Lost access after recent update.',
                'priority': 'medium',
                'category': 'account',
                'status': 'in-progress'
            },
            {
                'title': 'Software installation help',
                'description': 'Need assistance installing the new project management software.',
                'priority': 'low',
                'category': 'technical',
                'status': 'resolved'
            },
            {
                'title': 'Network connectivity issue',
                'description': 'Intermittent network connectivity in the main office area.',
                'priority': 'high',
                'category': 'technical',
                'status': 'open'
            }
        ]
        
        for i, ticket_data in enumerate(tickets_data):
            user = users[i % len(users)]  # Cycle through users
            
            ticket = Ticket(
                title=ticket_data['title'],
                description=ticket_data['description'],
                priority=ticket_data['priority'],
                category=ticket_data['category'],
                status=ticket_data['status'],
                created_by=user.id,
                assigned_to=user.id if ticket_data['status'] in ['in-progress', 'resolved'] else None,
                created_at=datetime.utcnow() - timedelta(hours=i*2),  # Stagger creation times
                resolved_at=datetime.utcnow() - timedelta(hours=1) if ticket_data['status'] == 'resolved' else None
            )
            
            db.session.add(ticket)
            print(f"   ✅ Created ticket: {ticket_data['title']}")
        
        db.session.commit()
        print("✅ Test tickets created successfully!")

def create_test_enrollments():
    """Create test enrollments for courses"""
    print("\nCreating test enrollments...")
    
    with app.app_context():
        users = User.query.filter(User.role == 'employee').all()
        courses = Course.query.all()
        
        if not users or not courses:
            print("   No users or courses found, skipping enrollment creation...")
            return
        
        # Create some sample enrollments with progress
        enrollments_data = [
            {'user_idx': 0, 'course_idx': 0, 'progress': 65},  # John Doe - Web Dev (65%)
            {'user_idx': 0, 'course_idx': 1, 'progress': 0},   # John Doe - Data Science (not started)
            {'user_idx': 1, 'course_idx': 1, 'progress': 32},  # Jane Smith - Data Science (32%)
            {'user_idx': 1, 'course_idx': 2, 'progress': 0},   # Jane Smith - Cybersecurity (not started)
            {'user_idx': 2, 'course_idx': 2, 'progress': 89},  # Mike Johnson - Cybersecurity (89%)
        ]
        
        for enrollment_data in enrollments_data:
            if (enrollment_data['user_idx'] < len(users) and 
                enrollment_data['course_idx'] < len(courses)):
                
                user = users[enrollment_data['user_idx']]
                course = courses[enrollment_data['course_idx']]
                
                # Check if enrollment already exists
                existing = UserProgress.query.filter_by(
                    user_id=user.id, 
                    course_id=course.id
                ).first()
                
                if existing:
                    print(f"   Enrollment {user.username} -> {course.title} already exists, skipping...")
                    continue
                
                progress = UserProgress(
                    user_id=user.id,
                    course_id=course.id,
                    progress_percentage=enrollment_data['progress'],
                    completed=enrollment_data['progress'] >= 100,
                    started_at=datetime.utcnow() - timedelta(days=30),
                    completed_at=datetime.utcnow() - timedelta(days=1) if enrollment_data['progress'] >= 100 else None
                )
                
                db.session.add(progress)
                print(f"   ✅ Enrolled {user.username} in {course.title} ({enrollment_data['progress']}%)")
        
        db.session.commit()
        print("✅ Test enrollments created successfully!")

def main():
    """Main initialization function"""
    print("🚀 Initializing iBridge Database...")
    print("=" * 50)
    
    try:
        # Create database tables
        create_database()
        
        # Create test data
        create_test_users()
        create_test_courses()
        create_test_tickets()
        create_test_enrollments()
        
        print("\n" + "=" * 50)
        print("✅ Database initialization completed successfully!")
        print("\n📊 Test Data Summary:")
        
        with app.app_context():
            user_count = User.query.count()
            course_count = Course.query.count()
            ticket_count = Ticket.query.count()
            enrollment_count = UserProgress.query.count()
            
            print(f"   👥 Users: {user_count}")
            print(f"   📚 Courses: {course_count}")
            print(f"   🎫 Tickets: {ticket_count}")
            print(f"   📝 Enrollments: {enrollment_count}")
        
        print("\n🔐 Test Login Credentials:")
        print("   Admin: admin@ibridge.co.za / admin123")
        print("   User: john.doe@ibridge.co.za / password123")
        print("   User: jane.smith@ibridge.co.za / password123")
        print("   User: mike.johnson@ibridge.co.za / password123")
        
        print("\n🚀 Next Steps:")
        print("   1. Run: python app.py")
        print("   2. Visit: http://localhost:5000")
        print("   3. Test authentication and features!")
        
    except Exception as e:
        print(f"\n❌ Error during initialization: {str(e)}")
        import traceback
        traceback.print_exc()
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())
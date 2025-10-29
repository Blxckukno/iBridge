#!/usr/bin/env python3
"""
Enhanced iBridge LMS Backend API
Enterprise-grade Learning Management System
"""

import os
import json
from datetime import datetime, timedelta
from flask import Flask, request, jsonify, session
from flask_sqlalchemy import SQLAlchemy
from flask_jwt_extended import JWTManager, jwt_required, create_access_token, get_jwt_identity, get_jwt
from flask_cors import CORS
from werkzeug.security import generate_password_hash, check_password_hash
from werkzeug.utils import secure_filename
import secrets

# Import enhanced models
from models import (
    db, User, Course, Enrollment, Assessment, AssessmentAttempt, 
    Group, GroupMember, Badge, UserBadge, Notification, Assignment, ActivityLog
)

# Initialize Flask app
app = Flask(__name__)

# Configuration
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', secrets.token_hex(32))
app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get('DATABASE_URL', 'sqlite:///ibridge_lms.db')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['JWT_SECRET_KEY'] = os.environ.get('JWT_SECRET_KEY', secrets.token_hex(32))
app.config['JWT_ACCESS_TOKEN_EXPIRES'] = timedelta(hours=24)
app.config['UPLOAD_FOLDER'] = 'uploads'
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB max file size

# Initialize extensions
db.init_app(app)
jwt = JWTManager(app)
CORS(app, origins=['http://localhost:3000', 'http://127.0.0.1:5500', 'http://localhost:5500'])

# Create upload directory
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)

# JWT Error Handlers
@jwt.expired_token_loader
def expired_token_callback(jwt_header, jwt_payload):
    return jsonify({'error': 'Token has expired'}), 401

@jwt.invalid_token_loader
def invalid_token_callback(error):
    return jsonify({'error': 'Invalid token'}), 401

# Utility Functions
def log_activity(user_id, activity_type, activity_data=None, course_id=None):
    """Log user activity for analytics"""
    try:
        activity = ActivityLog(
            user_id=user_id,
            activity_type=activity_type,
            activity_data=json.dumps(activity_data) if activity_data else None,
            course_id=course_id,
            ip_address=request.remote_addr,
            user_agent=request.headers.get('User-Agent')
        )
        db.session.add(activity)
        db.session.commit()
    except Exception as e:
        app.logger.error(f"Failed to log activity: {str(e)}")

def check_role_permission(required_roles):
    """Decorator to check user role permissions"""
    def decorator(f):
        def wrapper(*args, **kwargs):
            user_id = get_jwt_identity()
            user = User.query.get(user_id)
            
            if not user or user.role not in required_roles:
                return jsonify({'error': 'Insufficient permissions'}), 403
            
            return f(*args, **kwargs, current_user=user)
        wrapper.__name__ = f.__name__
        return wrapper
    return decorator

# ============ AUTHENTICATION ROUTES ============

@app.route('/api/register', methods=['POST'])
def register():
    try:
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['username', 'email', 'password']
        for field in required_fields:
            if not data.get(field):
                return jsonify({'error': f'{field} is required'}), 400
        
        # Check if user already exists
        if User.query.filter_by(username=data['username']).first():
            return jsonify({'error': 'Username already exists'}), 409
        
        if User.query.filter_by(email=data['email']).first():
            return jsonify({'error': 'Email already exists'}), 409
        
        # Create new user
        user = User(
            username=data['username'],
            email=data['email'],
            role=data.get('role', 'learner'),
            department=data.get('department'),
            branch=data.get('branch', 'iBridge'),
            lob=data.get('lob'),
            first_name=data.get('first_name'),
            last_name=data.get('last_name')
        )
        user.set_password(data['password'])
        
        db.session.add(user)
        db.session.commit()
        
        # Log registration activity
        log_activity(user.id, 'user_registration')
        
        return jsonify({
            'message': 'User registered successfully',
            'user': user.to_dict()
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Registration failed', 'details': str(e)}), 500

@app.route('/api/login', methods=['POST'])
def login():
    try:
        data = request.get_json()
        
        if not data.get('email') or not data.get('password'):
            return jsonify({'error': 'Email and password are required'}), 400
        
        user = User.query.filter_by(email=data['email']).first()
        
        if not user or not user.check_password(data['password']):
            return jsonify({'error': 'Invalid credentials'}), 401
        
        if not user.is_active:
            return jsonify({'error': 'Account is deactivated'}), 401
        
        if user.is_sleeping:
            return jsonify({'error': 'Account is in sleep mode'}), 401
        
        # Update login tracking
        user.record_login()
        
        # Create JWT token
        access_token = create_access_token(
            identity=user.id,
            additional_claims={'role': user.role, 'username': user.username}
        )
        
        # Log login activity
        log_activity(user.id, 'user_login')
        
        return jsonify({
            'access_token': access_token,
            'user': user.to_dict()
        }), 200
        
    except Exception as e:
        return jsonify({'error': 'Login failed', 'details': str(e)}), 500

@app.route('/api/logout', methods=['POST'])
@jwt_required()
def logout():
    user_id = get_jwt_identity()
    log_activity(user_id, 'user_logout')
    return jsonify({'message': 'Logged out successfully'}), 200

# ============ USER MANAGEMENT ROUTES ============

@app.route('/api/profile', methods=['GET'])
@jwt_required()
def get_profile():
    user_id = get_jwt_identity()
    user = User.query.get(user_id)
    
    if not user:
        return jsonify({'error': 'User not found'}), 404
    
    return jsonify(user.to_dict()), 200

@app.route('/api/profile', methods=['PUT'])
@jwt_required()
def update_profile():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        data = request.get_json()
        
        # Update allowed fields
        allowed_fields = ['first_name', 'last_name', 'bio', 'department', 'lob']
        for field in allowed_fields:
            if field in data:
                setattr(user, field, data[field])
        
        db.session.commit()
        
        log_activity(user_id, 'profile_update')
        
        return jsonify({
            'message': 'Profile updated successfully',
            'user': user.to_dict()
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Profile update failed', 'details': str(e)}), 500

@app.route('/api/users', methods=['GET'])
@jwt_required()
@check_role_permission(['admin', 'instructor'])
def get_users(current_user):
    try:
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 20, type=int)
        role_filter = request.args.get('role')
        department_filter = request.args.get('department')
        status_filter = request.args.get('status', 'active')
        
        query = User.query
        
        # Apply filters
        if role_filter:
            query = query.filter(User.role == role_filter)
        if department_filter:
            query = query.filter(User.department == department_filter)
        if status_filter == 'active':
            query = query.filter(User.is_active == True, User.is_sleeping == False)
        elif status_filter == 'inactive':
            query = query.filter(User.is_active == False)
        elif status_filter == 'sleeping':
            query = query.filter(User.is_sleeping == True)
        
        users = query.paginate(
            page=page, per_page=per_page, error_out=False
        )
        
        return jsonify({
            'users': [user.to_dict() for user in users.items],
            'total': users.total,
            'pages': users.pages,
            'current_page': page
        }), 200
        
    except Exception as e:
        return jsonify({'error': 'Failed to fetch users', 'details': str(e)}), 500

@app.route('/api/users/<int:user_id>/sleep', methods=['POST'])
@jwt_required()
@check_role_permission(['admin'])
def put_user_to_sleep(user_id, current_user):
    try:
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        data = request.get_json()
        sleep_duration_days = data.get('duration_days', 30)
        
        user.is_sleeping = True
        user.sleep_start_date = datetime.utcnow()
        user.sleep_end_date = datetime.utcnow() + timedelta(days=sleep_duration_days)
        
        db.session.commit()
        
        log_activity(current_user.id, 'user_sleep_mode', {'target_user_id': user_id})
        
        return jsonify({'message': 'User put to sleep mode'}), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Failed to put user to sleep', 'details': str(e)}), 500

@app.route('/api/users/<int:user_id>/wake', methods=['POST'])
@jwt_required()
@check_role_permission(['admin'])
def wake_user(user_id, current_user):
    try:
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        user.is_sleeping = False
        user.sleep_start_date = None
        user.sleep_end_date = None
        
        db.session.commit()
        
        log_activity(current_user.id, 'user_wake_up', {'target_user_id': user_id})
        
        return jsonify({'message': 'User awakened successfully'}), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Failed to wake user', 'details': str(e)}), 500

# ============ COURSE MANAGEMENT ROUTES ============

@app.route('/api/courses', methods=['GET'])
@jwt_required()
def get_courses():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        category = request.args.get('category')
        department = request.args.get('department')
        lob = request.args.get('lob')
        include_stats = request.args.get('include_stats', 'false').lower() == 'true'
        
        query = Course.query.filter(Course.is_active == True)
        
        # Apply filters
        if category:
            query = query.filter(Course.category == category)
        if department:
            query = query.filter(Course.department == department)
        if lob:
            query = query.filter(Course.lob == lob)
        
        # Role-based filtering
        if user.role == 'learner':
            query = query.filter(Course.is_published == True)
        
        courses = query.all()
        
        # Get user's enrollments for this course list
        enrolled_course_ids = []
        if user.role == 'learner':
            enrollments = Enrollment.query.filter(
                Enrollment.user_id == user_id,
                Enrollment.course_id.in_([c.id for c in courses])
            ).all()
            enrolled_course_ids = [e.course_id for e in enrollments]
        
        courses_data = []
        for course in courses:
            course_dict = course.to_dict(include_stats=include_stats)
            if user.role == 'learner':
                course_dict['is_enrolled'] = course.id in enrolled_course_ids
            courses_data.append(course_dict)
        
        return jsonify(courses_data), 200
        
    except Exception as e:
        return jsonify({'error': 'Failed to fetch courses', 'details': str(e)}), 500

@app.route('/api/courses', methods=['POST'])
@jwt_required()
@check_role_permission(['admin', 'instructor'])
def create_course(current_user):
    try:
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['title', 'description']
        for field in required_fields:
            if not data.get(field):
                return jsonify({'error': f'{field} is required'}), 400
        
        course = Course(
            title=data['title'],
            description=data['description'],
            category=data.get('category'),
            department=data.get('department'),
            lob=data.get('lob'),
            instructor=current_user.get_full_name(),
            instructor_id=current_user.id,
            duration_hours=data.get('duration_hours', 1),
            difficulty=data.get('difficulty', 'beginner'),
            learning_objectives=data.get('learning_objectives'),
            enrollment_type=data.get('enrollment_type', 'open')
        )
        
        # Set prerequisites and modules if provided
        if data.get('prerequisites'):
            course.set_prerequisites(data['prerequisites'])
        if data.get('modules'):
            course.set_modules(data['modules'])
        
        db.session.add(course)
        db.session.commit()
        
        log_activity(current_user.id, 'course_create', {'course_id': course.id})
        
        return jsonify({
            'message': 'Course created successfully',
            'course': course.to_dict()
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Course creation failed', 'details': str(e)}), 500

@app.route('/api/courses/<int:course_id>/enroll', methods=['POST'])
@jwt_required()
def enroll_in_course(course_id):
    try:
        user_id = get_jwt_identity()
        
        # Check if course exists and is available
        course = Course.query.get(course_id)
        if not course or not course.is_active or not course.is_published:
            return jsonify({'error': 'Course not available'}), 404
        
        # Check if already enrolled
        existing_enrollment = Enrollment.query.filter_by(
            user_id=user_id, course_id=course_id
        ).first()
        
        if existing_enrollment:
            return jsonify({'error': 'Already enrolled in this course'}), 409
        
        # Create enrollment
        enrollment = Enrollment(
            user_id=user_id,
            course_id=course_id,
            enrollment_type='self'
        )
        
        db.session.add(enrollment)
        db.session.commit()
        
        log_activity(user_id, 'course_enroll', {'course_id': course_id})
        
        return jsonify({
            'message': 'Enrolled successfully',
            'enrollment': enrollment.to_dict()
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Enrollment failed', 'details': str(e)}), 500

@app.route('/api/courses/<int:course_id>/access', methods=['POST'])
@jwt_required()
def access_course(course_id):
    """Activate enrollment when user first accesses course"""
    try:
        user_id = get_jwt_identity()
        
        enrollment = Enrollment.query.filter_by(
            user_id=user_id, course_id=course_id
        ).first()
        
        if not enrollment:
            return jsonify({'error': 'Not enrolled in this course'}), 403
        
        # Activate enrollment if inactive
        enrollment.activate_enrollment()
        
        log_activity(user_id, 'course_access', {'course_id': course_id})
        
        return jsonify({
            'message': 'Course accessed',
            'enrollment': enrollment.to_dict()
        }), 200
        
    except Exception as e:
        return jsonify({'error': 'Course access failed', 'details': str(e)}), 500

@app.route('/api/enrollments', methods=['GET'])
@jwt_required()
def get_user_enrollments():
    try:
        user_id = get_jwt_identity()
        status_filter = request.args.get('status')
        
        query = Enrollment.query.filter(Enrollment.user_id == user_id)
        
        if status_filter:
            query = query.filter(Enrollment.status == status_filter)
        
        enrollments = query.all()
        
        enrollments_data = []
        for enrollment in enrollments:
            enrollment_dict = enrollment.to_dict()
            # Add course information
            course = Course.query.get(enrollment.course_id)
            if course:
                enrollment_dict['course'] = course.to_dict()
            enrollments_data.append(enrollment_dict)
        
        return jsonify(enrollments_data), 200
        
    except Exception as e:
        return jsonify({'error': 'Failed to fetch enrollments', 'details': str(e)}), 500

# ============ ASSESSMENT ROUTES ============

@app.route('/api/courses/<int:course_id>/assessments', methods=['GET'])
@jwt_required()
def get_course_assessments(course_id):
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        # Check if user has access to course
        if user.role == 'learner':
            enrollment = Enrollment.query.filter_by(
                user_id=user_id, course_id=course_id
            ).first()
            if not enrollment:
                return jsonify({'error': 'Not enrolled in this course'}), 403
        
        assessments = Assessment.query.filter_by(
            course_id=course_id, is_active=True
        ).all()
        
        assessments_data = []
        for assessment in assessments:
            assessment_dict = assessment.to_dict()
            
            # Add user attempt information for learners
            if user.role == 'learner':
                attempts = AssessmentAttempt.query.filter_by(
                    user_id=user_id, assessment_id=assessment.id
                ).order_by(AssessmentAttempt.attempt_number.desc()).all()
                
                assessment_dict['user_attempts'] = len(attempts)
                assessment_dict['max_attempts_reached'] = len(attempts) >= assessment.max_attempts
                
                if attempts:
                    best_attempt = max(attempts, key=lambda x: x.score or 0)
                    assessment_dict['best_score'] = best_attempt.score
                    assessment_dict['passed'] = best_attempt.passed
            
            assessments_data.append(assessment_dict)
        
        return jsonify(assessments_data), 200
        
    except Exception as e:
        return jsonify({'error': 'Failed to fetch assessments', 'details': str(e)}), 500

@app.route('/api/assessments', methods=['POST'])
@jwt_required()
@check_role_permission(['admin', 'instructor'])
def create_assessment(current_user):
    try:
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['course_id', 'title']
        for field in required_fields:
            if not data.get(field):
                return jsonify({'error': f'{field} is required'}), 400
        
        assessment = Assessment(
            course_id=data['course_id'],
            title=data['title'],
            description=data.get('description'),
            assessment_type=data.get('assessment_type', 'quiz'),
            total_questions=data.get('total_questions', 20),
            pass_mark=data.get('pass_mark', 60.0),
            time_limit_minutes=data.get('time_limit_minutes', 20),
            max_attempts=data.get('max_attempts', 3),
            randomize_questions=data.get('randomize_questions', True),
            show_results=data.get('show_results', True),
            allow_review=data.get('allow_review', True),
            created_by=current_user.id
        )
        
        # Set questions if provided
        if data.get('questions'):
            assessment.set_questions(data['questions'])
        
        db.session.add(assessment)
        db.session.commit()
        
        log_activity(current_user.id, 'assessment_create', {'assessment_id': assessment.id})
        
        return jsonify({
            'message': 'Assessment created successfully',
            'assessment': assessment.to_dict()
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Assessment creation failed', 'details': str(e)}), 500

# ============ ANALYTICS & REPORTING ROUTES ============

@app.route('/api/analytics/dashboard', methods=['GET'])
@jwt_required()
@check_role_permission(['admin', 'instructor'])
def get_analytics_dashboard(current_user):
    try:
        # Active users (logged in within last 7 days)
        week_ago = datetime.utcnow() - timedelta(days=7)
        active_users = User.query.filter(
            User.last_activity >= week_ago,
            User.is_active == True,
            User.is_sleeping == False
        ).count()
        
        # Total enrollments
        total_enrollments = Enrollment.query.count()
        active_enrollments = Enrollment.query.filter(
            Enrollment.status.in_(['active', 'completed'])
        ).count()
        
        # Course statistics
        total_courses = Course.query.filter(Course.is_active == True).count()
        published_courses = Course.query.filter(
            Course.is_active == True, Course.is_published == True
        ).count()
        
        # Completion rate
        completed_enrollments = Enrollment.query.filter(
            Enrollment.status == 'completed'
        ).count()
        completion_rate = (completed_enrollments / total_enrollments * 100) if total_enrollments > 0 else 0
        
        # Groups
        active_groups = Group.query.filter(Group.is_active == True).count()
        
        # Recent activity
        recent_activities = ActivityLog.query.order_by(
            ActivityLog.timestamp.desc()
        ).limit(10).all()
        
        return jsonify({
            'overview': {
                'active_users': active_users,
                'total_enrollments': total_enrollments,
                'active_enrollments': active_enrollments,
                'total_courses': total_courses,
                'published_courses': published_courses,
                'completion_rate': round(completion_rate, 2),
                'active_groups': active_groups
            },
            'recent_activities': [activity.to_dict() for activity in recent_activities]
        }), 200
        
    except Exception as e:
        return jsonify({'error': 'Failed to fetch analytics', 'details': str(e)}), 500

@app.route('/api/analytics/participation', methods=['GET'])
@jwt_required()
@check_role_permission(['admin', 'instructor'])
def get_participation_analytics(current_user):
    try:
        days = request.args.get('days', 30, type=int)
        start_date = datetime.utcnow() - timedelta(days=days)
        
        # Daily active users
        daily_activities = db.session.query(
            db.func.date(ActivityLog.timestamp).label('date'),
            db.func.count(db.func.distinct(ActivityLog.user_id)).label('active_users')
        ).filter(
            ActivityLog.timestamp >= start_date
        ).group_by(
            db.func.date(ActivityLog.timestamp)
        ).order_by('date').all()
        
        # Course completion trends
        course_completions = db.session.query(
            db.func.date(Enrollment.completed_at).label('date'),
            db.func.count(Enrollment.id).label('completions')
        ).filter(
            Enrollment.completed_at >= start_date,
            Enrollment.status == 'completed'
        ).group_by(
            db.func.date(Enrollment.completed_at)
        ).order_by('date').all()
        
        # Time spent analysis
        time_analysis = db.session.query(
            db.func.sum(Enrollment.time_spent_minutes).label('total_minutes'),
            db.func.avg(Enrollment.time_spent_minutes).label('avg_minutes'),
            db.func.count(Enrollment.id).label('active_enrollments')
        ).filter(
            Enrollment.last_accessed >= start_date,
            Enrollment.status.in_(['active', 'completed'])
        ).first()
        
        return jsonify({
            'daily_active_users': [
                {'date': str(activity.date), 'active_users': activity.active_users}
                for activity in daily_activities
            ],
            'course_completions': [
                {'date': str(completion.date), 'completions': completion.completions}
                for completion in course_completions
            ],
            'time_analysis': {
                'total_hours': round((time_analysis.total_minutes or 0) / 60, 2),
                'average_minutes_per_session': round(time_analysis.avg_minutes or 0, 2),
                'active_enrollments': time_analysis.active_enrollments or 0
            }
        }), 200
        
    except Exception as e:
        return jsonify({'error': 'Failed to fetch participation analytics', 'details': str(e)}), 500

# ============ GROUP MANAGEMENT ROUTES ============

@app.route('/api/groups', methods=['GET'])
@jwt_required()
@check_role_permission(['admin', 'instructor'])
def get_groups(current_user):
    try:
        groups = Group.query.filter(Group.is_active == True).all()
        return jsonify([group.to_dict() for group in groups]), 200
    except Exception as e:
        return jsonify({'error': 'Failed to fetch groups', 'details': str(e)}), 500

@app.route('/api/groups', methods=['POST'])
@jwt_required()
@check_role_permission(['admin'])
def create_group(current_user):
    try:
        data = request.get_json()
        
        if not data.get('name'):
            return jsonify({'error': 'Group name is required'}), 400
        
        group = Group(
            name=data['name'],
            description=data.get('description'),
            group_type=data.get('group_type', 'team'),
            parent_group_id=data.get('parent_group_id'),
            created_by=current_user.id
        )
        
        db.session.add(group)
        db.session.commit()
        
        log_activity(current_user.id, 'group_create', {'group_id': group.id})
        
        return jsonify({
            'message': 'Group created successfully',
            'group': group.to_dict()
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Group creation failed', 'details': str(e)}), 500

# ============ NOTIFICATION ROUTES ============

@app.route('/api/notifications', methods=['GET'])
@jwt_required()
def get_notifications():
    try:
        user_id = get_jwt_identity()
        
        notifications = Notification.query.filter(
            Notification.user_id == user_id
        ).order_by(
            Notification.created_at.desc()
        ).limit(50).all()
        
        return jsonify([notification.to_dict() for notification in notifications]), 200
        
    except Exception as e:
        return jsonify({'error': 'Failed to fetch notifications', 'details': str(e)}), 500

@app.route('/api/notifications/<int:notification_id>/read', methods=['POST'])
@jwt_required()
def mark_notification_read(notification_id):
    try:
        user_id = get_jwt_identity()
        
        notification = Notification.query.filter_by(
            id=notification_id, user_id=user_id
        ).first()
        
        if not notification:
            return jsonify({'error': 'Notification not found'}), 404
        
        notification.mark_as_read()
        
        return jsonify({'message': 'Notification marked as read'}), 200
        
    except Exception as e:
        return jsonify({'error': 'Failed to mark notification as read', 'details': str(e)}), 500

# ============ ERROR HANDLERS ============

@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Resource not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    db.session.rollback()
    return jsonify({'error': 'Internal server error'}), 500

# ============ APPLICATION STARTUP ============

def create_sample_data():
    """Create sample data for testing"""
    try:
        # Create sample badges
        badges_data = [
            {'name': 'First Steps', 'description': 'Completed first course', 'badge_type': 'achievement', 'points_value': 50},
            {'name': 'Quiz Master', 'description': 'Passed 5 assessments', 'badge_type': 'skill', 'points_value': 100},
            {'name': 'Streak Champion', 'description': '7-day learning streak', 'badge_type': 'achievement', 'points_value': 75}
        ]
        
        for badge_data in badges_data:
            if not Badge.query.filter_by(name=badge_data['name']).first():
                badge = Badge(**badge_data)
                db.session.add(badge)
        
        # Create sample groups
        groups_data = [
            {'name': 'IT Department', 'group_type': 'department'},
            {'name': 'Sales Team', 'group_type': 'team'},
            {'name': 'Customer Service', 'group_type': 'lob'}
        ]
        
        for group_data in groups_data:
            if not Group.query.filter_by(name=group_data['name']).first():
                group = Group(**group_data)
                db.session.add(group)
        
        db.session.commit()
        print("Sample data created successfully!")
        
    except Exception as e:
        db.session.rollback()
        print(f"Error creating sample data: {str(e)}")

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
        create_sample_data()
        
        print("\n🚀 iBridge Enterprise LMS Backend Starting...")
        print("📊 Features Enabled:")
        print("   ✅ Role-based Access Control (Admin/Instructor/Learner)")
        print("   ✅ Advanced Course Management & Assignments")
        print("   ✅ Assessment Engine with Timer & Grading")
        print("   ✅ Analytics & Participation Tracking")
        print("   ✅ User Sleep Mode & Activity Monitoring")
        print("   ✅ Gamification (Points, Badges, Streaks)")
        print("   ✅ Group & Organizational Management")
        print("   ✅ Notification System")
        print("   ✅ Comprehensive Reporting")
        print("\n🔐 API Endpoints Available:")
        print("   📝 Authentication: /api/login, /api/register")
        print("   👤 User Management: /api/users, /api/profile")
        print("   📚 Course Management: /api/courses, /api/enrollments")
        print("   📝 Assessments: /api/assessments")
        print("   📊 Analytics: /api/analytics/dashboard")
        print("   👥 Groups: /api/groups")
        print("   🔔 Notifications: /api/notifications")
        print(f"\n🌐 Server running on: http://127.0.0.1:5000")
        print("🎯 Ready for enterprise LMS operations!")
    
    app.run(debug=True, host='0.0.0.0', port=5000)
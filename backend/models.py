#!/usr/bin/env python3
"""
Enhanced iBridge LMS Database Models
Supports enterprise-grade learning management features
"""

from datetime import datetime, timedelta
from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import generate_password_hash, check_password_hash
import json

db = SQLAlchemy()

# User Model with enhanced enterprise features
class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(128))
    
    # Role and Department Management
    role = db.Column(db.String(20), default='learner')  # admin, instructor, learner
    department = db.Column(db.String(50))
    branch = db.Column(db.String(50), default='iBridge')
    lob = db.Column(db.String(50))  # Line of Business
    
    # Personal Information
    first_name = db.Column(db.String(50))
    last_name = db.Column(db.String(50))
    bio = db.Column(db.Text)
    avatar_url = db.Column(db.String(255))
    
    # Account Status Management
    is_active = db.Column(db.Boolean, default=True)
    is_sleeping = db.Column(db.Boolean, default=False)  # Long-term leave
    sleep_start_date = db.Column(db.DateTime)
    sleep_end_date = db.Column(db.DateTime)
    
    # Activity Tracking
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    last_login = db.Column(db.DateTime)
    last_activity = db.Column(db.DateTime)
    login_count = db.Column(db.Integer, default=0)
    
    # Gamification
    points = db.Column(db.Integer, default=0)
    level = db.Column(db.Integer, default=1)
    streak_days = db.Column(db.Integer, default=0)
    last_streak_date = db.Column(db.Date)
    
    # Relationships
    enrollments = db.relationship('Enrollment', backref='user', lazy='dynamic')
    assignments = db.relationship('Assignment', backref='user', lazy='dynamic')
    badges = db.relationship('UserBadge', backref='user', lazy='dynamic')
    
    def set_password(self, password):
        self.password_hash = generate_password_hash(password)
    
    def check_password(self, password):
        return check_password_hash(self.password_hash, password)
    
    def get_full_name(self):
        if self.first_name and self.last_name:
            return f"{self.first_name} {self.last_name}"
        return self.username
    
    def update_activity(self):
        self.last_activity = datetime.utcnow()
        db.session.commit()
    
    def record_login(self):
        self.last_login = datetime.utcnow()
        self.login_count += 1
        self.update_streak()
        db.session.commit()
    
    def update_streak(self):
        today = datetime.utcnow().date()
        if self.last_streak_date:
            if self.last_streak_date == today - timedelta(days=1):
                self.streak_days += 1
            elif self.last_streak_date != today:
                self.streak_days = 1
        else:
            self.streak_days = 1
        self.last_streak_date = today
    
    def add_points(self, points):
        self.points += points
        # Level up logic (every 1000 points = 1 level)
        new_level = (self.points // 1000) + 1
        if new_level > self.level:
            self.level = new_level
        db.session.commit()
    
    def to_dict(self):
        return {
            'id': self.id,
            'username': self.username,
            'email': self.email,
            'role': self.role,
            'department': self.department,
            'branch': self.branch,
            'lob': self.lob,
            'first_name': self.first_name,
            'last_name': self.last_name,
            'full_name': self.get_full_name(),
            'bio': self.bio,
            'avatar_url': self.avatar_url,
            'is_active': self.is_active,
            'is_sleeping': self.is_sleeping,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'last_login': self.last_login.isoformat() if self.last_login else None,
            'last_activity': self.last_activity.isoformat() if self.last_activity else None,
            'login_count': self.login_count,
            'points': self.points,
            'level': self.level,
            'streak_days': self.streak_days
        }

# Enhanced Course Model
class Course(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text)
    category = db.Column(db.String(50))
    department = db.Column(db.String(50))
    lob = db.Column(db.String(50))  # Line of Business
    
    # Course Details
    instructor = db.Column(db.String(100))
    instructor_id = db.Column(db.Integer, db.ForeignKey('user.id'))
    duration_hours = db.Column(db.Integer)
    difficulty = db.Column(db.String(20))  # beginner, intermediate, advanced
    prerequisites = db.Column(db.Text)  # JSON string of prerequisite course IDs
    
    # Course Content Structure
    modules = db.Column(db.Text)  # JSON string of modules/lessons
    learning_objectives = db.Column(db.Text)
    
    # Status and Visibility
    is_active = db.Column(db.Boolean, default=True)
    is_published = db.Column(db.Boolean, default=False)
    enrollment_type = db.Column(db.String(20), default='open')  # open, assigned, closed
    
    # Tracking
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    enrollments = db.relationship('Enrollment', backref='course', lazy='dynamic')
    assessments = db.relationship('Assessment', backref='course', lazy='dynamic')
    
    def get_prerequisites(self):
        if self.prerequisites:
            return json.loads(self.prerequisites)
        return []
    
    def set_prerequisites(self, prereq_list):
        self.prerequisites = json.dumps(prereq_list)
    
    def get_modules(self):
        if self.modules:
            return json.loads(self.modules)
        return []
    
    def set_modules(self, modules_list):
        self.modules = json.dumps(modules_list)
    
    def get_enrollment_count(self):
        return self.enrollments.filter_by(status='active').count()
    
    def get_completion_rate(self):
        total_enrollments = self.enrollments.count()
        if total_enrollments == 0:
            return 0
        completed = self.enrollments.filter_by(status='completed').count()
        return (completed / total_enrollments) * 100
    
    def to_dict(self, include_stats=False):
        data = {
            'id': self.id,
            'title': self.title,
            'description': self.description,
            'category': self.category,
            'department': self.department,
            'lob': self.lob,
            'instructor': self.instructor,
            'instructor_id': self.instructor_id,
            'duration_hours': self.duration_hours,
            'difficulty': self.difficulty,
            'prerequisites': self.get_prerequisites(),
            'modules': self.get_modules(),
            'learning_objectives': self.learning_objectives,
            'is_active': self.is_active,
            'is_published': self.is_published,
            'enrollment_type': self.enrollment_type,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat()
        }
        
        if include_stats:
            data['enrollment_count'] = self.get_enrollment_count()
            data['completion_rate'] = self.get_completion_rate()
        
        return data

# Enhanced Enrollment Model
class Enrollment(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    course_id = db.Column(db.Integer, db.ForeignKey('course.id'), nullable=False)
    
    # Enrollment Details
    status = db.Column(db.String(20), default='inactive')  # inactive, active, completed, withdrawn
    enrollment_type = db.Column(db.String(20), default='self')  # self, assigned, mandatory
    assigned_by = db.Column(db.Integer, db.ForeignKey('user.id'))
    
    # Progress Tracking
    progress_percentage = db.Column(db.Float, default=0.0)
    current_module = db.Column(db.Integer, default=0)
    time_spent_minutes = db.Column(db.Integer, default=0)
    
    # Dates
    enrolled_at = db.Column(db.DateTime, default=datetime.utcnow)
    started_at = db.Column(db.DateTime)  # When user first clicked on course
    completed_at = db.Column(db.DateTime)
    due_date = db.Column(db.DateTime)
    last_accessed = db.Column(db.DateTime)
    
    # Performance
    final_score = db.Column(db.Float)
    attempts = db.Column(db.Integer, default=0)
    
    def activate_enrollment(self):
        """Activate enrollment when user first accesses course"""
        if self.status == 'inactive':
            self.status = 'active'
            self.started_at = datetime.utcnow()
            db.session.commit()
    
    def update_progress(self, percentage, time_spent=0):
        self.progress_percentage = percentage
        self.time_spent_minutes += time_spent
        self.last_accessed = datetime.utcnow()
        
        if percentage >= 100 and self.status != 'completed':
            self.status = 'completed'
            self.completed_at = datetime.utcnow()
            # Award points to user
            self.user.add_points(100)  # Base completion points
        
        db.session.commit()
    
    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'course_id': self.course_id,
            'status': self.status,
            'enrollment_type': self.enrollment_type,
            'assigned_by': self.assigned_by,
            'progress_percentage': self.progress_percentage,
            'current_module': self.current_module,
            'time_spent_minutes': self.time_spent_minutes,
            'enrolled_at': self.enrolled_at.isoformat(),
            'started_at': self.started_at.isoformat() if self.started_at else None,
            'completed_at': self.completed_at.isoformat() if self.completed_at else None,
            'due_date': self.due_date.isoformat() if self.due_date else None,
            'last_accessed': self.last_accessed.isoformat() if self.last_accessed else None,
            'final_score': self.final_score,
            'attempts': self.attempts
        }

# Assessment System
class Assessment(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    course_id = db.Column(db.Integer, db.ForeignKey('course.id'), nullable=False)
    title = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text)
    
    # Assessment Settings
    assessment_type = db.Column(db.String(20), default='quiz')  # quiz, assignment, project
    questions = db.Column(db.Text)  # JSON string of questions
    total_questions = db.Column(db.Integer, default=20)
    pass_mark = db.Column(db.Float, default=60.0)  # Percentage
    time_limit_minutes = db.Column(db.Integer, default=20)
    max_attempts = db.Column(db.Integer, default=3)
    
    # Settings
    is_active = db.Column(db.Boolean, default=True)
    randomize_questions = db.Column(db.Boolean, default=True)
    show_results = db.Column(db.Boolean, default=True)
    allow_review = db.Column(db.Boolean, default=True)
    
    # Tracking
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    created_by = db.Column(db.Integer, db.ForeignKey('user.id'))
    
    def get_questions(self):
        if self.questions:
            return json.loads(self.questions)
        return []
    
    def set_questions(self, questions_list):
        self.questions = json.dumps(questions_list)
        self.total_questions = len(questions_list)
    
    def to_dict(self):
        return {
            'id': self.id,
            'course_id': self.course_id,
            'title': self.title,
            'description': self.description,
            'assessment_type': self.assessment_type,
            'questions': self.get_questions(),
            'total_questions': self.total_questions,
            'pass_mark': self.pass_mark,
            'time_limit_minutes': self.time_limit_minutes,
            'max_attempts': self.max_attempts,
            'is_active': self.is_active,
            'randomize_questions': self.randomize_questions,
            'show_results': self.show_results,
            'allow_review': self.allow_review,
            'created_at': self.created_at.isoformat()
        }

# User Assessment Attempts
class AssessmentAttempt(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    assessment_id = db.Column(db.Integer, db.ForeignKey('assessment.id'), nullable=False)
    
    # Attempt Details
    attempt_number = db.Column(db.Integer, nullable=False)
    status = db.Column(db.String(20), default='in_progress')  # in_progress, completed, abandoned
    
    # Results
    score = db.Column(db.Float)  # Percentage score
    correct_answers = db.Column(db.Integer, default=0)
    total_questions = db.Column(db.Integer)
    passed = db.Column(db.Boolean, default=False)
    
    # Timing
    started_at = db.Column(db.DateTime, default=datetime.utcnow)
    completed_at = db.Column(db.DateTime)
    time_taken_minutes = db.Column(db.Integer)
    
    # Responses
    responses = db.Column(db.Text)  # JSON string of user responses
    
    user = db.relationship('User', backref='assessment_attempts')
    assessment = db.relationship('Assessment', backref='attempts')
    
    def complete_attempt(self, responses_dict, score):
        self.status = 'completed'
        self.completed_at = datetime.utcnow()
        self.responses = json.dumps(responses_dict)
        self.score = score
        self.passed = score >= self.assessment.pass_mark
        
        # Calculate time taken
        if self.started_at and self.completed_at:
            time_diff = self.completed_at - self.started_at
            self.time_taken_minutes = int(time_diff.total_seconds() / 60)
        
        # Award points for passing
        if self.passed:
            self.user.add_points(50)  # Assessment completion points
        
        db.session.commit()
    
    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'assessment_id': self.assessment_id,
            'attempt_number': self.attempt_number,
            'status': self.status,
            'score': self.score,
            'correct_answers': self.correct_answers,
            'total_questions': self.total_questions,
            'passed': self.passed,
            'started_at': self.started_at.isoformat(),
            'completed_at': self.completed_at.isoformat() if self.completed_at else None,
            'time_taken_minutes': self.time_taken_minutes
        }

# Groups for Team/LOB Management
class Group(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text)
    group_type = db.Column(db.String(20), default='team')  # team, lob, department, branch
    
    # Hierarchy
    parent_group_id = db.Column(db.Integer, db.ForeignKey('group.id'))
    
    # Settings
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    created_by = db.Column(db.Integer, db.ForeignKey('user.id'))
    
    # Relationships
    members = db.relationship('GroupMember', backref='group', lazy='dynamic')
    
    def get_member_count(self):
        return self.members.filter_by(is_active=True).count()
    
    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'description': self.description,
            'group_type': self.group_type,
            'parent_group_id': self.parent_group_id,
            'is_active': self.is_active,
            'created_at': self.created_at.isoformat(),
            'member_count': self.get_member_count()
        }

# Group Membership
class GroupMember(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    group_id = db.Column(db.Integer, db.ForeignKey('group.id'), nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    
    role = db.Column(db.String(20), default='member')  # member, admin, leader
    is_active = db.Column(db.Boolean, default=True)
    joined_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    user = db.relationship('User', backref='group_memberships')

# Badges and Achievements
class Badge(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text)
    icon_url = db.Column(db.String(255))
    badge_type = db.Column(db.String(20), default='achievement')  # achievement, skill, completion
    
    # Criteria
    criteria = db.Column(db.Text)  # JSON string of earning criteria
    points_value = db.Column(db.Integer, default=0)
    
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'description': self.description,
            'icon_url': self.icon_url,
            'badge_type': self.badge_type,
            'points_value': self.points_value,
            'is_active': self.is_active
        }

# User Badge Awards
class UserBadge(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    badge_id = db.Column(db.Integer, db.ForeignKey('badge.id'), nullable=False)
    
    awarded_at = db.Column(db.DateTime, default=datetime.utcnow)
    awarded_by = db.Column(db.Integer, db.ForeignKey('user.id'))
    reason = db.Column(db.Text)
    
    badge = db.relationship('Badge', backref='user_awards')
    
    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'badge_id': self.badge_id,
            'badge': self.badge.to_dict(),
            'awarded_at': self.awarded_at.isoformat(),
            'awarded_by': self.awarded_by,
            'reason': self.reason
        }

# Notifications
class Notification(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    
    # Notification Content
    title = db.Column(db.String(200), nullable=False)
    message = db.Column(db.Text)
    notification_type = db.Column(db.String(20), default='info')  # info, warning, success, reminder
    
    # Targeting
    recipient_type = db.Column(db.String(20), default='user')  # user, group, all, role
    recipient_id = db.Column(db.Integer)  # User ID, Group ID, etc.
    
    # Status
    is_read = db.Column(db.Boolean, default=False)
    is_sent = db.Column(db.Boolean, default=False)
    
    # Timing
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    sent_at = db.Column(db.DateTime)
    read_at = db.Column(db.DateTime)
    expires_at = db.Column(db.DateTime)
    
    user = db.relationship('User', backref='notifications')
    
    def mark_as_read(self):
        if not self.is_read:
            self.is_read = True
            self.read_at = datetime.utcnow()
            db.session.commit()
    
    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'title': self.title,
            'message': self.message,
            'notification_type': self.notification_type,
            'is_read': self.is_read,
            'created_at': self.created_at.isoformat(),
            'sent_at': self.sent_at.isoformat() if self.sent_at else None,
            'read_at': self.read_at.isoformat() if self.read_at else None
        }

# Assignment System (for assignments beyond courses)
class Assignment(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    course_id = db.Column(db.Integer, db.ForeignKey('course.id'))
    
    title = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text)
    assignment_type = db.Column(db.String(20), default='course')  # course, mandatory, optional
    
    # Timing
    assigned_at = db.Column(db.DateTime, default=datetime.utcnow)
    due_date = db.Column(db.DateTime)
    completed_at = db.Column(db.DateTime)
    
    # Status
    status = db.Column(db.String(20), default='assigned')  # assigned, in_progress, completed, overdue
    assigned_by = db.Column(db.Integer, db.ForeignKey('user.id'))
    
    course = db.relationship('Course', backref='assigned_to_users')
    
    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'course_id': self.course_id,
            'title': self.title,
            'description': self.description,
            'assignment_type': self.assignment_type,
            'assigned_at': self.assigned_at.isoformat(),
            'due_date': self.due_date.isoformat() if self.due_date else None,
            'completed_at': self.completed_at.isoformat() if self.completed_at else None,
            'status': self.status,
            'assigned_by': self.assigned_by
        }

# Activity Log for Analytics
class ActivityLog(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'))
    
    # Activity Details
    activity_type = db.Column(db.String(50), nullable=False)  # login, course_access, assessment_start, etc.
    activity_data = db.Column(db.Text)  # JSON string of additional data
    
    # Context
    course_id = db.Column(db.Integer, db.ForeignKey('course.id'))
    session_id = db.Column(db.String(50))
    ip_address = db.Column(db.String(45))
    user_agent = db.Column(db.Text)
    
    # Timing
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)
    duration_seconds = db.Column(db.Integer)
    
    user = db.relationship('User', backref='activity_logs')
    course = db.relationship('Course', backref='activity_logs')
    
    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'activity_type': self.activity_type,
            'activity_data': json.loads(self.activity_data) if self.activity_data else {},
            'course_id': self.course_id,
            'timestamp': self.timestamp.isoformat(),
            'duration_seconds': self.duration_seconds
        }
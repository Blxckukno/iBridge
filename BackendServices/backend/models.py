#!/usr/bin/env python3
"""
iBridge data models.
"""

from datetime import datetime, timedelta
import json

from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import check_password_hash, generate_password_hash

db = SQLAlchemy()


class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)

    role = db.Column(db.String(20), default="learner")
    department = db.Column(db.String(50))
    branch = db.Column(db.String(50), default="iBridge")
    lob = db.Column(db.String(50))

    first_name = db.Column(db.String(50))
    last_name = db.Column(db.String(50))
    bio = db.Column(db.Text)
    avatar_url = db.Column(db.String(255))

    is_active = db.Column(db.Boolean, default=True)
    is_sleeping = db.Column(db.Boolean, default=False)
    sleep_start_date = db.Column(db.DateTime)
    sleep_end_date = db.Column(db.DateTime)

    failed_login_attempts = db.Column(db.Integer, default=0)
    locked_until = db.Column(db.DateTime)
    last_failed_login = db.Column(db.DateTime)
    password_changed_at = db.Column(db.DateTime, default=datetime.utcnow)

    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    last_login = db.Column(db.DateTime)
    last_activity = db.Column(db.DateTime)
    login_count = db.Column(db.Integer, default=0)

    points = db.Column(db.Integer, default=0)
    level = db.Column(db.Integer, default=1)
    streak_days = db.Column(db.Integer, default=0)
    last_streak_date = db.Column(db.Date)

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
        self.login_count = (self.login_count or 0) + 1
        self.update_streak()
        db.session.commit()

    def update_streak(self):
        today = datetime.utcnow().date()
        if self.last_streak_date == today - timedelta(days=1):
            self.streak_days += 1
        elif self.last_streak_date != today:
            self.streak_days = 1
        self.last_streak_date = today

    def add_points(self, points):
        self.points = (self.points or 0) + points
        self.level = max(1, (self.points // 1000) + 1)
        db.session.commit()

    def to_dict(self):
        return {
            "id": self.id,
            "username": self.username,
            "email": self.email,
            "role": self.role,
            "department": self.department,
            "branch": self.branch,
            "lob": self.lob,
            "first_name": self.first_name,
            "last_name": self.last_name,
            "full_name": self.get_full_name(),
            "bio": self.bio,
            "avatar_url": self.avatar_url,
            "is_active": self.is_active,
            "is_sleeping": self.is_sleeping,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "last_login": self.last_login.isoformat() if self.last_login else None,
            "last_activity": self.last_activity.isoformat() if self.last_activity else None,
            "login_count": self.login_count,
            "points": self.points,
            "level": self.level,
            "streak_days": self.streak_days,
        }


class Ticket(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text, nullable=False)
    status = db.Column(db.String(30), default="open")
    priority = db.Column(db.String(20), default="medium")
    category = db.Column(db.String(100))
    created_by = db.Column(db.Integer, db.ForeignKey("user.id"), nullable=False)
    assigned_to = db.Column(db.Integer, db.ForeignKey("user.id"))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    resolved_at = db.Column(db.DateTime)

    created_by_user = db.relationship("User", foreign_keys=[created_by], backref="created_tickets")
    assigned_to_user = db.relationship("User", foreign_keys=[assigned_to], backref="assigned_tickets")

    def to_dict(self):
        return {
            "id": self.id,
            "title": self.title,
            "description": self.description,
            "status": self.status,
            "priority": self.priority,
            "category": self.category,
            "created_by": self.created_by,
            "assigned_to": self.assigned_to,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
            "resolved_at": self.resolved_at.isoformat() if self.resolved_at else None,
        }


class TicketIntakeEvent(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    ticket_id = db.Column(db.Integer, db.ForeignKey("ticket.id"), nullable=False, index=True)
    source = db.Column(db.String(30), nullable=False, default="web")
    requester_name = db.Column(db.String(120))
    requester_email = db.Column(db.String(120))
    requester_phone = db.Column(db.String(50))
    requester_department = db.Column(db.String(80))
    requester_channel_id = db.Column(db.String(120))
    external_message_id = db.Column(db.String(120))
    meta_json = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

    ticket = db.relationship("Ticket", backref="intake_events")

    def get_meta(self):
        if not self.meta_json:
            return {}
        try:
            return json.loads(self.meta_json)
        except Exception:
            return {}

    def set_meta(self, data):
        self.meta_json = json.dumps(data or {}, ensure_ascii=False)

    def to_dict(self):
        return {
            "id": self.id,
            "ticket_id": self.ticket_id,
            "source": self.source,
            "requester_name": self.requester_name,
            "requester_email": self.requester_email,
            "requester_phone": self.requester_phone,
            "requester_department": self.requester_department,
            "requester_channel_id": self.requester_channel_id,
            "external_message_id": self.external_message_id,
            "meta": self.get_meta(),
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }


class Course(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text)
    category = db.Column(db.String(50))
    department = db.Column(db.String(50))
    lob = db.Column(db.String(50))
    instructor = db.Column(db.String(100))
    instructor_id = db.Column(db.Integer, db.ForeignKey("user.id"))
    duration_hours = db.Column(db.Integer)
    difficulty = db.Column(db.String(20))
    prerequisites = db.Column(db.Text)
    modules = db.Column(db.Text)
    learning_objectives = db.Column(db.Text)
    is_active = db.Column(db.Boolean, default=True)
    is_published = db.Column(db.Boolean, default=False)
    enrollment_type = db.Column(db.String(20), default="open")
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def get_prerequisites(self):
        return json.loads(self.prerequisites) if self.prerequisites else []

    def set_prerequisites(self, items):
        self.prerequisites = json.dumps(items)

    def get_modules(self):
        return json.loads(self.modules) if self.modules else []

    def set_modules(self, items):
        self.modules = json.dumps(items)

    def to_dict(self, include_stats=False):
        data = {
            "id": self.id,
            "title": self.title,
            "description": self.description,
            "category": self.category,
            "department": self.department,
            "lob": self.lob,
            "instructor": self.instructor,
            "instructor_id": self.instructor_id,
            "duration_hours": self.duration_hours,
            "difficulty": self.difficulty,
            "prerequisites": self.get_prerequisites(),
            "modules": self.get_modules(),
            "learning_objectives": self.learning_objectives,
            "is_active": self.is_active,
            "is_published": self.is_published,
            "enrollment_type": self.enrollment_type,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }
        if include_stats:
            total = Enrollment.query.filter_by(course_id=self.id).count()
            completed = Enrollment.query.filter_by(course_id=self.id, status="completed").count()
            data["enrollment_count"] = total
            data["completion_rate"] = (completed / total * 100) if total else 0
        return data


class Enrollment(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("user.id"), nullable=False)
    course_id = db.Column(db.Integer, db.ForeignKey("course.id"), nullable=False)
    status = db.Column(db.String(20), default="inactive")
    enrollment_type = db.Column(db.String(20), default="self")
    assigned_by = db.Column(db.Integer, db.ForeignKey("user.id"))
    progress_percentage = db.Column(db.Float, default=0.0)
    current_module = db.Column(db.Integer, default=0)
    time_spent_minutes = db.Column(db.Integer, default=0)
    enrolled_at = db.Column(db.DateTime, default=datetime.utcnow)
    started_at = db.Column(db.DateTime)
    completed_at = db.Column(db.DateTime)
    due_date = db.Column(db.DateTime)
    last_accessed = db.Column(db.DateTime)
    final_score = db.Column(db.Float)
    attempts = db.Column(db.Integer, default=0)

    user = db.relationship("User", foreign_keys=[user_id], backref="enrollments")
    course = db.relationship("Course", backref="enrollments")

    def activate_enrollment(self):
        if self.status == "inactive":
            self.status = "active"
            self.started_at = datetime.utcnow()
            db.session.commit()

    def update_progress(self, percentage, time_spent=0):
        self.progress_percentage = percentage
        self.time_spent_minutes += time_spent
        self.last_accessed = datetime.utcnow()
        if percentage >= 100 and self.status != "completed":
            self.status = "completed"
            self.completed_at = datetime.utcnow()
            self.user.add_points(100)
        db.session.commit()

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "course_id": self.course_id,
            "status": self.status,
            "enrollment_type": self.enrollment_type,
            "assigned_by": self.assigned_by,
            "progress_percentage": self.progress_percentage,
            "current_module": self.current_module,
            "time_spent_minutes": self.time_spent_minutes,
            "enrolled_at": self.enrolled_at.isoformat() if self.enrolled_at else None,
            "started_at": self.started_at.isoformat() if self.started_at else None,
            "completed_at": self.completed_at.isoformat() if self.completed_at else None,
            "due_date": self.due_date.isoformat() if self.due_date else None,
            "last_accessed": self.last_accessed.isoformat() if self.last_accessed else None,
            "final_score": self.final_score,
            "attempts": self.attempts,
        }


class UserProgress(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("user.id"), nullable=False)
    course_id = db.Column(db.Integer, db.ForeignKey("course.id"), nullable=False)
    progress = db.Column(db.Float, default=0.0)
    last_accessed = db.Column(db.DateTime, default=datetime.utcnow)


class Assessment(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    course_id = db.Column(db.Integer, db.ForeignKey("course.id"), nullable=False)
    title = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text)
    assessment_type = db.Column(db.String(20), default="quiz")
    questions = db.Column(db.Text)
    total_questions = db.Column(db.Integer, default=20)
    pass_mark = db.Column(db.Float, default=60.0)
    time_limit_minutes = db.Column(db.Integer, default=20)
    max_attempts = db.Column(db.Integer, default=3)
    is_active = db.Column(db.Boolean, default=True)
    randomize_questions = db.Column(db.Boolean, default=True)
    show_results = db.Column(db.Boolean, default=True)
    allow_review = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    created_by = db.Column(db.Integer, db.ForeignKey("user.id"))

    def get_questions(self):
        return json.loads(self.questions) if self.questions else []

    def set_questions(self, questions):
        self.questions = json.dumps(questions)
        self.total_questions = len(questions)


class AssessmentAttempt(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("user.id"), nullable=False)
    assessment_id = db.Column(db.Integer, db.ForeignKey("assessment.id"), nullable=False)
    attempt_number = db.Column(db.Integer, nullable=False)
    status = db.Column(db.String(20), default="in_progress")
    score = db.Column(db.Float)
    correct_answers = db.Column(db.Integer, default=0)
    total_questions = db.Column(db.Integer)
    passed = db.Column(db.Boolean, default=False)
    started_at = db.Column(db.DateTime, default=datetime.utcnow)
    completed_at = db.Column(db.DateTime)
    time_taken_minutes = db.Column(db.Integer)
    responses = db.Column(db.Text)

    user = db.relationship("User", backref="assessment_attempts")
    assessment = db.relationship("Assessment", backref="attempts")


class Group(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text)
    group_type = db.Column(db.String(20), default="team")
    parent_group_id = db.Column(db.Integer, db.ForeignKey("group.id"))
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    created_by = db.Column(db.Integer, db.ForeignKey("user.id"))


class GroupMember(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    group_id = db.Column(db.Integer, db.ForeignKey("group.id"), nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey("user.id"), nullable=False)
    role = db.Column(db.String(20), default="member")
    is_active = db.Column(db.Boolean, default=True)
    joined_at = db.Column(db.DateTime, default=datetime.utcnow)


class Badge(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text)
    icon_url = db.Column(db.String(255))
    badge_type = db.Column(db.String(20), default="achievement")
    criteria = db.Column(db.Text)
    points_value = db.Column(db.Integer, default=0)
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)


class UserBadge(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("user.id"), nullable=False)
    badge_id = db.Column(db.Integer, db.ForeignKey("badge.id"), nullable=False)
    awarded_at = db.Column(db.DateTime, default=datetime.utcnow)
    awarded_by = db.Column(db.Integer, db.ForeignKey("user.id"))
    reason = db.Column(db.Text)


class Notification(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("user.id"), nullable=False)
    title = db.Column(db.String(200), nullable=False)
    message = db.Column(db.Text)
    notification_type = db.Column(db.String(20), default="info")
    recipient_type = db.Column(db.String(20), default="user")
    recipient_id = db.Column(db.Integer)
    is_read = db.Column(db.Boolean, default=False)
    is_sent = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    sent_at = db.Column(db.DateTime)
    read_at = db.Column(db.DateTime)
    expires_at = db.Column(db.DateTime)


class Assignment(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("user.id"), nullable=False)
    course_id = db.Column(db.Integer, db.ForeignKey("course.id"))
    title = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text)
    assignment_type = db.Column(db.String(20), default="course")
    assigned_at = db.Column(db.DateTime, default=datetime.utcnow)
    due_date = db.Column(db.DateTime)
    completed_at = db.Column(db.DateTime)
    status = db.Column(db.String(20), default="assigned")
    assigned_by = db.Column(db.Integer, db.ForeignKey("user.id"))


class ActivityLog(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("user.id"))
    activity_type = db.Column(db.String(50), nullable=False)
    activity_data = db.Column(db.Text)
    course_id = db.Column(db.Integer, db.ForeignKey("course.id"))
    session_id = db.Column(db.String(50))
    ip_address = db.Column(db.String(45))
    user_agent = db.Column(db.Text)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)
    duration_seconds = db.Column(db.Integer)


class CMSContent(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    section = db.Column(db.String(80), unique=True, nullable=False, index=True)
    title = db.Column(db.String(200))
    subtitle = db.Column(db.String(300))
    body = db.Column(db.Text)
    payload_json = db.Column(db.Text)
    is_published = db.Column(db.Boolean, default=True)
    updated_by = db.Column(db.Integer, db.ForeignKey("user.id"))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def get_payload(self):
        if not self.payload_json:
            return {}
        try:
            return json.loads(self.payload_json)
        except Exception:
            return {}

    def set_payload(self, payload):
        self.payload_json = json.dumps(payload or {}, ensure_ascii=False)

    def to_dict(self):
        return {
            "id": self.id,
            "section": self.section,
            "title": self.title,
            "subtitle": self.subtitle,
            "body": self.body,
            "payload": self.get_payload(),
            "is_published": self.is_published,
            "updated_by": self.updated_by,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }


class Lead(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    full_name = db.Column(db.String(120), nullable=False)
    email = db.Column(db.String(120), nullable=False, index=True)
    phone = db.Column(db.String(50))
    company = db.Column(db.String(120))
    source = db.Column(db.String(80), default="website")
    inquiry_type = db.Column(db.String(80), default="general")
    message = db.Column(db.Text)
    status = db.Column(db.String(30), default="new", index=True)
    priority = db.Column(db.String(20), default="medium")
    assigned_to = db.Column(db.Integer, db.ForeignKey("user.id"))
    utm_source = db.Column(db.String(120))
    utm_medium = db.Column(db.String(120))
    utm_campaign = db.Column(db.String(120))
    page_url = db.Column(db.String(255))
    ip_address = db.Column(db.String(45))
    user_agent = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, index=True)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "full_name": self.full_name,
            "email": self.email,
            "phone": self.phone,
            "company": self.company,
            "source": self.source,
            "inquiry_type": self.inquiry_type,
            "message": self.message,
            "status": self.status,
            "priority": self.priority,
            "assigned_to": self.assigned_to,
            "utm_source": self.utm_source,
            "utm_medium": self.utm_medium,
            "utm_campaign": self.utm_campaign,
            "page_url": self.page_url,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }


class IntegrationEvent(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    integration = db.Column(db.String(50), nullable=False, index=True)
    direction = db.Column(db.String(20), default="outbound")
    event_type = db.Column(db.String(80), nullable=False)
    status = db.Column(db.String(30), default="queued", index=True)
    reference_id = db.Column(db.String(120), index=True)
    payload_json = db.Column(db.Text)
    response_json = db.Column(db.Text)
    error_message = db.Column(db.Text)
    attempts = db.Column(db.Integer, default=0)
    next_retry_at = db.Column(db.DateTime)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, index=True)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def get_payload(self):
        if not self.payload_json:
            return {}
        try:
            return json.loads(self.payload_json)
        except Exception:
            return {}

    def set_payload(self, payload):
        self.payload_json = json.dumps(payload or {}, ensure_ascii=False)

    def get_response(self):
        if not self.response_json:
            return {}
        try:
            return json.loads(self.response_json)
        except Exception:
            return {}

    def set_response(self, payload):
        self.response_json = json.dumps(payload or {}, ensure_ascii=False)

    def to_dict(self):
        return {
            "id": self.id,
            "integration": self.integration,
            "direction": self.direction,
            "event_type": self.event_type,
            "status": self.status,
            "reference_id": self.reference_id,
            "payload": self.get_payload(),
            "response": self.get_response(),
            "error_message": self.error_message,
            "attempts": self.attempts,
            "next_retry_at": self.next_retry_at.isoformat() if self.next_retry_at else None,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }

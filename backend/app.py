"""
iBridge Production Backend - Security & Authentication System
"""

from flask import Flask, request, jsonify, session, redirect, url_for, send_from_directory
from flask_sqlalchemy import SQLAlchemy
# Removed flask_login - using JWT authentication only
from werkzeug.security import generate_password_hash, check_password_hash
from flask_jwt_extended import JWTManager, jwt_required, create_access_token, get_jwt_identity
from flask_cors import CORS
import os
from datetime import datetime, timedelta
import secrets
import sqlite3

# Get the parent directory to serve static files
BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))

app = Flask(__name__, static_folder=BASE_DIR, static_url_path='')

# Security Configuration
app.config['SECRET_KEY'] = secrets.token_hex(32)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///ibridge_production.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['JWT_SECRET_KEY'] = secrets.token_hex(32)
app.config['JWT_ACCESS_TOKEN_EXPIRES'] = timedelta(hours=24)

# Initialize extensions
db = SQLAlchemy(app)
# Using JWT authentication only
jwt = JWTManager(app)
CORS(app)

# Register blueprints
from reports import reports_bp
app.register_blueprint(reports_bp)

# User Model
class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(128))
    role = db.Column(db.String(20), default='employee')  # admin, employee, customer
    department = db.Column(db.String(50))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    last_login = db.Column(db.DateTime)
    is_active = db.Column(db.Boolean, default=True)
    
    def set_password(self, password):
        self.password_hash = generate_password_hash(password)
    
    def check_password(self, password):
        return check_password_hash(self.password_hash, password)
    
    def to_dict(self):
        return {
            'id': self.id,
            'username': self.username,
            'email': self.email,
            'role': self.role,
            'department': self.department,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'last_login': self.last_login.isoformat() if self.last_login else None,
            'is_active': self.is_active
        }

# Ticket Model
class Ticket(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text)
    status = db.Column(db.String(20), default='open')  # open, in-progress, resolved, closed
    priority = db.Column(db.String(10), default='medium')  # low, medium, high, urgent
    category = db.Column(db.String(50))
    created_by = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    assigned_to = db.Column(db.Integer, db.ForeignKey('user.id'))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    resolved_at = db.Column(db.DateTime)
    
    created_by_user = db.relationship('User', foreign_keys=[created_by], backref='created_tickets')
    assigned_to_user = db.relationship('User', foreign_keys=[assigned_to], backref='assigned_tickets')
    
    def to_dict(self):
        return {
            'id': self.id,
            'title': self.title,
            'description': self.description,
            'status': self.status,
            'priority': self.priority,
            'category': self.category,
            'created_by': self.created_by_user.username if self.created_by_user else None,
            'assigned_to': self.assigned_to_user.username if self.assigned_to_user else None,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat(),
            'resolved_at': self.resolved_at.isoformat() if self.resolved_at else None
        }

# Course Model
class Course(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text)
    category = db.Column(db.String(50))
    instructor = db.Column(db.String(100))
    duration_hours = db.Column(db.Integer)
    difficulty = db.Column(db.String(20))  # beginner, intermediate, advanced
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def to_dict(self):
        return {
            'id': self.id,
            'title': self.title,
            'description': self.description,
            'category': self.category,
            'instructor': self.instructor,
            'duration_hours': self.duration_hours,
            'difficulty': self.difficulty,
            'is_active': self.is_active,
            'created_at': self.created_at.isoformat()
        }

# User Progress Model
class UserProgress(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    course_id = db.Column(db.Integer, db.ForeignKey('course.id'), nullable=False)
    progress_percentage = db.Column(db.Float, default=0.0)
    completed = db.Column(db.Boolean, default=False)
    started_at = db.Column(db.DateTime, default=datetime.utcnow)
    completed_at = db.Column(db.DateTime)
    
    user = db.relationship('User', backref='course_progress')
    course = db.relationship('Course', backref='user_progress')

# JWT authentication only - no user loader needed

# Static file serving routes
@app.route('/')
def index():
    return send_from_directory(BASE_DIR, 'index.html')

@app.route('/<path:path>')
def serve_static(path):
    return send_from_directory(BASE_DIR, path)

# Authentication Routes
@app.route('/api/register', methods=['POST'])
def register():
    data = request.get_json()
    
    if User.query.filter_by(username=data['username']).first():
        return jsonify({'error': 'Username already exists'}), 400
    
    if User.query.filter_by(email=data['email']).first():
        return jsonify({'error': 'Email already exists'}), 400
    
    user = User(
        username=data['username'],
        email=data['email'],
        role=data.get('role', 'employee'),
        department=data.get('department')
    )
    user.set_password(data['password'])
    
    db.session.add(user)
    db.session.commit()
    
    access_token = create_access_token(identity=user.id)
    
    return jsonify({
        'message': 'User registered successfully',
        'user': user.to_dict(),
        'access_token': access_token
    }), 201

@app.route('/api/login', methods=['POST'])
def login():
    data = request.get_json()
    user = User.query.filter_by(username=data['username']).first()
    
    if user and user.check_password(data['password']):
        user.last_login = datetime.utcnow()
        db.session.commit()
        
        login_user(user)
        access_token = create_access_token(identity=user.id)
        
        return jsonify({
            'message': 'Login successful',
            'user': user.to_dict(),
            'access_token': access_token
        })
    
    return jsonify({'error': 'Invalid credentials'}), 401

@app.route('/api/logout', methods=['POST'])
@jwt_required()
def logout():
    logout_user()
    return jsonify({'message': 'Logout successful'})

# Ticket Management Routes
@app.route('/api/tickets', methods=['GET'])
@jwt_required()
def get_tickets():
    tickets = Ticket.query.all()
    return jsonify([ticket.to_dict() for ticket in tickets])

@app.route('/api/tickets', methods=['POST'])
@jwt_required()
def create_ticket():
    data = request.get_json()
    user_id = get_jwt_identity()
    
    ticket = Ticket(
        title=data['title'],
        description=data['description'],
        priority=data.get('priority', 'medium'),
        category=data.get('category'),
        created_by=user_id
    )
    
    db.session.add(ticket)
    db.session.commit()
    
    return jsonify(ticket.to_dict()), 201

@app.route('/api/tickets/<int:ticket_id>', methods=['PUT'])
@jwt_required()
def update_ticket(ticket_id):
    ticket = Ticket.query.get_or_404(ticket_id)
    data = request.get_json()
    
    ticket.title = data.get('title', ticket.title)
    ticket.description = data.get('description', ticket.description)
    ticket.status = data.get('status', ticket.status)
    ticket.priority = data.get('priority', ticket.priority)
    
    if data.get('status') == 'resolved' and not ticket.resolved_at:
        ticket.resolved_at = datetime.utcnow()
    
    db.session.commit()
    return jsonify(ticket.to_dict())

# Course Management Routes
@app.route('/api/courses', methods=['GET'])
@jwt_required()
def get_courses():
    courses = Course.query.filter_by(is_active=True).all()
    return jsonify([course.to_dict() for course in courses])

@app.route('/api/courses/<int:course_id>/enroll', methods=['POST'])
@jwt_required()
def enroll_course(course_id):
    user_id = get_jwt_identity()
    
    existing_progress = UserProgress.query.filter_by(
        user_id=user_id, course_id=course_id
    ).first()
    
    if existing_progress:
        return jsonify({'error': 'Already enrolled'}), 400
    
    progress = UserProgress(user_id=user_id, course_id=course_id)
    db.session.add(progress)
    db.session.commit()
    
    return jsonify({'message': 'Enrolled successfully'}), 201

# User Management Routes
@app.route('/api/users', methods=['GET'])
@jwt_required()
def get_users():
    current_user_id = get_jwt_identity()
    current_user_obj = User.query.get(current_user_id)
    
    if current_user_obj.role != 'admin':
        return jsonify({'error': 'Admin access required'}), 403
    
    users = User.query.all()
    return jsonify([user.to_dict() for user in users])

# Initialize Database and Create Test Users
def init_db():
    db.create_all()
    
    # Create test admin user
    if not User.query.filter_by(username='admin').first():
        admin = User(
            username='admin',
            email='admin@ibridge.com',
            role='admin',
            department='IT'
        )
        admin.set_password('admin123')
        db.session.add(admin)
    
    # Create test employee user
    if not User.query.filter_by(username='employee').first():
        employee = User(
            username='employee',
            email='employee@ibridge.com',
            role='employee',
            department='Operations'
        )
        employee.set_password('employee123')
        db.session.add(employee)
    
    # Create test customer user
    if not User.query.filter_by(username='customer').first():
        customer = User(
            username='customer',
            email='customer@example.com',
            role='customer',
            department='External'
        )
        customer.set_password('customer123')
        db.session.add(customer)
    
    # Create sample courses
    if not Course.query.first():
        courses = [
            Course(
                title='Web Development Fundamentals',
                description='Learn HTML, CSS, and JavaScript basics',
                category='Technology',
                instructor='John Smith',
                duration_hours=40,
                difficulty='beginner'
            ),
            Course(
                title='Data Science with Python',
                description='Introduction to data analysis and machine learning',
                category='Technology',
                instructor='Sarah Johnson',
                duration_hours=60,
                difficulty='intermediate'
            ),
            Course(
                title='Cybersecurity Essentials',
                description='Basic security concepts and best practices',
                category='Security',
                instructor='Mike Wilson',
                duration_hours=30,
                difficulty='intermediate'
            )
        ]
        
        for course in courses:
            db.session.add(course)
    
    db.session.commit()
    print("Database initialized with test data!")

if __name__ == '__main__':
    with app.app_context():
        init_db()
    
    print("🚀 iBridge Production Backend Starting...")
    print("📊 Admin Login: admin/admin123")
    print("👤 Employee Login: employee/employee123") 
    print("🏢 Customer Login: customer/customer123")
    
    app.run(debug=True, host='127.0.0.1', port=5000)
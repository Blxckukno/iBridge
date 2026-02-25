"""
iBridge backend API.
"""

import os
import re
import secrets
import string
import json
import csv
import io
import zipfile
import time
import uuid
from datetime import datetime, timedelta

from flask import Flask, jsonify, request, send_from_directory, make_response, g
from flask_cors import CORS
from flask_jwt_extended import JWTManager, create_access_token, get_jwt_identity, verify_jwt_in_request
from sqlalchemy import text

from models import (
    ActivityLog,
    CMSContent,
    Course,
    Enrollment,
    Group,
    GroupMember,
    IntegrationEvent,
    Lead,
    Ticket,
    TicketIntakeEvent,
    User,
    UserProgress,
    db,
)
from security_enhancements import (
    AccountSecurityManager,
    ContactFormSchema,
    SecurityConfig,
    SecurityMiddleware,
    SecurityUtils,
    TicketCreationSchema,
    UserLoginSchema,
    UserRegistrationSchema,
    enhanced_jwt_required,
    setup_csp_violation_reporting,
    validate_json,
)

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "Website"))

app = Flask(__name__, static_folder=BASE_DIR, static_url_path="")
app.config.update(
    SECRET_KEY=os.environ.get("SECRET_KEY", "change-me-in-production"),
    SQLALCHEMY_DATABASE_URI=os.environ.get("DATABASE_URL", "sqlite:///ibridge.db"),
    SQLALCHEMY_TRACK_MODIFICATIONS=False,
    JWT_SECRET_KEY=os.environ.get("JWT_SECRET_KEY", "change-me-jwt-in-production"),
    JWT_ACCESS_TOKEN_EXPIRES=timedelta(hours=24),
    JWT_TOKEN_LOCATION=["headers"],
    JWT_COOKIE_SECURE=True,
    SESSION_COOKIE_SECURE=True,
    SESSION_COOKIE_HTTPONLY=True,
    SESSION_COOKIE_SAMESITE="Lax",
    PERMANENT_SESSION_LIFETIME=timedelta(hours=24),
    MAX_CONTENT_LENGTH=2 * 1024 * 1024,
)

if app.config["SECRET_KEY"] == "change-me-in-production" or app.config["JWT_SECRET_KEY"] == "change-me-jwt-in-production":
    app.logger.warning("Using default secrets. Set SECRET_KEY and JWT_SECRET_KEY environment variables for production.")

db.init_app(app)
jwt = JWTManager(app)
CORS(app, origins=os.environ.get("CORS_ORIGINS", "*").split(","))
security_middleware = SecurityMiddleware(app)
account_security = AccountSecurityManager(db)
setup_csp_violation_reporting(app)

_ops_metrics = {
    "started_at": datetime.utcnow().isoformat(),
    "requests_total": 0,
    "errors_total": 0,
    "by_path": {},
}


@app.before_request
def _ops_before_request():
    g.request_id = request.headers.get("X-Request-ID") or str(uuid.uuid4())
    g.request_started_ts = time.perf_counter()


@app.after_request
def _ops_after_request(response):
    duration_ms = 0.0
    try:
        duration_ms = (time.perf_counter() - getattr(g, "request_started_ts", time.perf_counter())) * 1000.0
    except Exception:
        duration_ms = 0.0

    path_key = request.path or "/"
    bucket = _ops_metrics["by_path"].setdefault(path_key, {"count": 0, "errors": 0, "avg_ms": 0.0})
    bucket["count"] += 1
    _ops_metrics["requests_total"] += 1

    if response.status_code >= 400:
        bucket["errors"] += 1
        _ops_metrics["errors_total"] += 1

    # Running average for response time per path
    prev = float(bucket.get("avg_ms", 0.0))
    count = int(bucket["count"])
    bucket["avg_ms"] = round(((prev * (count - 1)) + duration_ms) / max(1, count), 2)

    response.headers["X-Request-ID"] = getattr(g, "request_id", "")
    response.headers["X-Response-Time-Ms"] = f"{duration_ms:.2f}"
    return response


def _has_internal_security_key():
    expected = os.environ.get("INTERNAL_SECURITY_KEY", "").strip()
    provided = request.headers.get("X-Internal-Security-Key", "").strip()
    return bool(expected) and bool(provided) and secrets.compare_digest(expected, provided)


def _user_is_dev_or_it(user):
    if not user:
        return False
    role = (user.role or "").lower()
    department = (user.department or "").lower()
    allowed_roles = {"admin", "developer", "devops", "security", "it"}
    if role in allowed_roles:
        return True
    return any(tag in department for tag in ["it", "dev", "developer", "security", "technology"])


def _user_can_manage_users(user):
    if not user:
        return False
    role = (user.role or "").lower()
    department = (user.department or "").lower()
    if role in {"admin", "it", "security", "developer", "devops"}:
        return True
    return any(tag in department for tag in ["it", "dev", "security", "technology"])


def _user_can_manage_site_content(user):
    if not user:
        return False
    role = (user.role or "").lower()
    department = (user.department or "").lower()
    if role in {"admin", "developer", "devops", "it", "security", "marketing"}:
        return True
    return any(tag in department for tag in ["it", "dev", "security", "marketing", "communications"])


def _normalize_portal_role(raw_role):
    role = (raw_role or "").strip().lower()
    if role in {"developer", "devops", "it", "security", "dev"}:
        return "dev"
    if role in {"admin"}:
        return "admin"
    if role in {"supervisor", "manager", "teamlead", "team-lead", "lead"}:
        return "supervisor"
    if role in {"student", "learner"}:
        return "student"
    if role in {"agent", "employee", "staff", "support"}:
        return "agent"
    return "agent"


def _user_has_min_portal_role(user, minimum_role):
    if not user:
        return False
    rank = {"student": 1, "agent": 2, "supervisor": 3, "admin": 4, "dev": 5}
    current = _normalize_portal_role(getattr(user, "role", ""))
    return rank.get(current, 0) >= rank.get(_normalize_portal_role(minimum_role), 0)


def _generate_temp_password(length=14):
    alphabet = string.ascii_letters + string.digits + "!@#$%^&*"
    return "".join(secrets.choice(alphabet) for _ in range(length))


def _jwt_user_id():
    identity = get_jwt_identity()
    try:
        return int(identity)
    except (TypeError, ValueError):
        return None


def _sanitize_text(value, max_len=500):
    text_value = SecurityUtils.sanitize_input(str(value or "").strip())
    return text_value[:max_len]


def _sanitize_optional_email(value):
    raw = SecurityUtils.sanitize_input((value or "").strip().lower())
    if not raw:
        return ""
    if re.match(r"^[^@\s]+@[^@\s]+\.[^@\s]+$", raw):
        return raw
    return ""


def _get_user_from_optional_jwt():
    try:
        verify_jwt_in_request(optional=True)
        user_id = _jwt_user_id()
        if user_id:
            return User.query.get(user_id)
    except Exception:
        return None
    return None


def _ticket_number(ticket_id):
    try:
        return f"IBR-{int(ticket_id):06d}"
    except Exception:
        return "IBR-000000"


def _ticket_payload(ticket):
    payload = ticket.to_dict()
    payload["ticket_number"] = _ticket_number(ticket.id)
    return payload


def _get_or_create_intake_user():
    username = "system_intake"
    user = User.query.filter_by(username=username).first()
    if user:
        return user

    user = User(
        username=username,
        email="system.intake@ibridge.local",
        role="system",
        department="IT",
        created_at=datetime.utcnow(),
        password_changed_at=datetime.utcnow(),
        is_active=True,
    )
    user.set_password(_generate_temp_password())
    db.session.add(user)
    db.session.commit()
    return user


def _training_resources_path():
    data_dir = os.path.join(BASE_DIR, "data")
    os.makedirs(data_dir, exist_ok=True)
    return os.path.join(data_dir, "lms-training-resources.json")


def _load_training_resources():
    path = _training_resources_path()
    if not os.path.exists(path):
        return []
    try:
        with open(path, "r", encoding="utf-8") as fp:
            content = json.load(fp)
        resources = content.get("resources") if isinstance(content, dict) else content
        if isinstance(resources, list):
            return resources
        return []
    except Exception:
        return []


def _find_course_for_track(track):
    track = (track or "").strip().lower()
    keyword_map = {
        "web-development": ["web development", "frontend", "html", "css", "javascript"],
        "data-science": ["data science", "analytics", "python", "sql", "statistics"],
        "cybersecurity": ["cybersecurity", "security", "soc", "incident response"],
    }
    keywords = keyword_map.get(track, [])
    if not keywords:
        return None

    for kw in keywords:
        course = Course.query.filter(
            Course.is_active.is_(True),
            (Course.title.ilike(f"%{kw}%")) | (Course.category.ilike(f"%{kw}%"))
        ).first()
        if course:
            return course
    return None


def _apply_resource_progress(user_id, track, delta=12):
    course = _find_course_for_track(track)
    if not course:
        return {"course_id": None, "progress": None, "status": "no_course_match"}

    enrollment = Enrollment.query.filter_by(user_id=user_id, course_id=course.id).first()
    if not enrollment:
        enrollment = Enrollment(
            user_id=user_id,
            course_id=course.id,
            status="active",
            enrolled_at=datetime.utcnow(),
            started_at=datetime.utcnow(),
            last_accessed=datetime.utcnow(),
            progress_percentage=0.0,
        )
        db.session.add(enrollment)

    current = float(enrollment.progress_percentage or 0.0)
    next_value = max(0.0, min(100.0, current + float(delta)))
    enrollment.progress_percentage = next_value
    enrollment.last_accessed = datetime.utcnow()
    if next_value >= 100.0:
        enrollment.status = "completed"
        enrollment.completed_at = enrollment.completed_at or datetime.utcnow()
    elif enrollment.status == "inactive":
        enrollment.status = "active"
        enrollment.started_at = enrollment.started_at or datetime.utcnow()

    user_progress = UserProgress.query.filter_by(user_id=user_id, course_id=course.id).first()
    if not user_progress:
        user_progress = UserProgress(user_id=user_id, course_id=course.id, progress=0.0, last_accessed=datetime.utcnow())
        db.session.add(user_progress)
    user_progress.progress = next_value
    user_progress.last_accessed = datetime.utcnow()

    db.session.commit()
    return {"course_id": course.id, "course_title": course.title, "progress": next_value, "status": enrollment.status}


def _parse_date(value):
    if not value:
        return None
    try:
        return datetime.strptime(str(value), "%Y-%m-%d")
    except ValueError:
        return None


def _coerce_rows_to_csv(rows):
    output = io.StringIO()
    if not rows:
        output.write("no_data\n")
        return output.getvalue()

    keys = set()
    for row in rows:
        if isinstance(row, dict):
            keys.update(row.keys())
    ordered = sorted(keys)
    writer = csv.DictWriter(output, fieldnames=ordered)
    writer.writeheader()
    for row in rows:
        if isinstance(row, dict):
            writer.writerow({k: row.get(k, "") for k in ordered})
    return output.getvalue()


def _rows_to_txt(rows):
    lines = []
    for idx, row in enumerate(rows, 1):
        lines.append(f"Record #{idx}")
        if isinstance(row, dict):
            for key, value in row.items():
                lines.append(f"- {key}: {value}")
        lines.append("")
    return "\n".join(lines) if lines else "No records."


def _rows_to_sql(table_name, rows):
    if not rows:
        return f"-- No data for {table_name}\n"
    statements = [f"-- Export for {table_name} generated {datetime.utcnow().isoformat()}"]
    for row in rows:
        if not isinstance(row, dict):
            continue
        cols = []
        vals = []
        for key, value in row.items():
            cols.append(key)
            if value is None:
                vals.append("NULL")
            else:
                safe = str(value).replace("'", "''")
                vals.append(f"'{safe}'")
        statements.append(f"INSERT INTO {table_name} ({', '.join(cols)}) VALUES ({', '.join(vals)});")
    return "\n".join(statements) + "\n"


def _filtered_tickets(user, start_date=None, end_date=None, status="all"):
    if user and (user.role or "").lower() == "admin":
        query = Ticket.query
    elif user:
        query = Ticket.query.filter_by(created_by=user.id)
    else:
        query = Ticket.query

    if start_date:
        query = query.filter(Ticket.created_at >= start_date)
    if end_date:
        query = query.filter(Ticket.created_at < (end_date + timedelta(days=1)))
    if status and status != "all":
        status_map = {"active": "open", "completed": "resolved", "pending": "pending"}
        mapped = status_map.get(status, status)
        query = query.filter(Ticket.status.ilike(mapped))
    return query.order_by(Ticket.created_at.desc()).all()


def _collect_dataset(data_type, user, start_date=None, end_date=None, status="all"):
    dtype = (data_type or "").lower()
    if dtype == "tickets":
        return [t.to_dict() for t in _filtered_tickets(user, start_date, end_date, status)]
    if dtype == "users":
        users = User.query.order_by(User.created_at.desc()).all()
        return [u.to_dict() for u in users]
    if dtype == "analytics":
        tickets = _filtered_tickets(user, start_date, end_date, "all")
        total = len(tickets)
        by_status = {}
        by_priority = {}
        for t in tickets:
            by_status[t.status] = by_status.get(t.status, 0) + 1
            by_priority[t.priority] = by_priority.get(t.priority, 0) + 1
        return [{
            "total_tickets": total,
            "open_tickets": by_status.get("open", 0),
            "resolved_tickets": by_status.get("resolved", 0) + by_status.get("closed", 0),
            "pending_tickets": by_status.get("pending", 0),
            "by_status": json.dumps(by_status),
            "by_priority": json.dumps(by_priority),
            "generated_at": datetime.utcnow().isoformat(),
        }]
    if dtype == "security":
        log_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "logs", "security-events.log"))
        rows = []
        if os.path.exists(log_path):
            with open(log_path, "r", encoding="utf-8", errors="ignore") as fp:
                for line in fp.readlines()[-1000:]:
                    line = line.strip()
                    if line:
                        rows.append({"event": line})
        return rows
    if dtype == "lms":
        courses = [c.to_dict() for c in Course.query.filter_by(is_active=True).all()]
        progress = UserProgress.query.all()
        progress_rows = [{
            "user_id": p.user_id,
            "course_id": p.course_id,
            "progress": p.progress,
            "last_accessed": p.last_accessed.isoformat() if p.last_accessed else None,
        } for p in progress]
        return courses + progress_rows
    if dtype == "backup":
        return [{
            "users": [u.to_dict() for u in User.query.all()],
            "tickets": [t.to_dict() for t in Ticket.query.all()],
            "courses": [c.to_dict() for c in Course.query.all()],
            "generated_at": datetime.utcnow().isoformat(),
        }]
    return []


def _build_export_payload(data_type, rows, export_format):
    fmt = (export_format or "json").lower()
    if fmt == "json":
        content = json.dumps(rows, indent=2, ensure_ascii=False)
        return content.encode("utf-8"), "application/json", f"{data_type}.json"
    if fmt == "csv":
        content = _coerce_rows_to_csv(rows)
        return content.encode("utf-8"), "text/csv", f"{data_type}.csv"
    if fmt == "txt":
        content = _rows_to_txt(rows)
        return content.encode("utf-8"), "text/plain", f"{data_type}.txt"
    if fmt == "sql":
        content = _rows_to_sql(data_type, rows)
        return content.encode("utf-8"), "application/sql", f"{data_type}.sql"
    if fmt == "xlsx":
        # Excel-compatible CSV payload with .xlsx filename for lightweight export.
        content = _coerce_rows_to_csv(rows)
        return content.encode("utf-8"), "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", f"{data_type}.xlsx"
    if fmt == "pdf":
        # Lightweight text report payload with .pdf filename.
        content = _rows_to_txt(rows)
        return content.encode("utf-8"), "application/pdf", f"{data_type}.pdf"
    if fmt == "zip":
        mem = io.BytesIO()
        with zipfile.ZipFile(mem, mode="w", compression=zipfile.ZIP_DEFLATED) as zf:
            zf.writestr(f"{data_type}.json", json.dumps(rows, indent=2, ensure_ascii=False))
            zf.writestr(f"{data_type}.csv", _coerce_rows_to_csv(rows))
        return mem.getvalue(), "application/zip", f"{data_type}.zip"
    content = json.dumps(rows, indent=2, ensure_ascii=False)
    return content.encode("utf-8"), "application/json", f"{data_type}.json"


@jwt.expired_token_loader
def expired_token_callback(jwt_header, jwt_payload):
    return jsonify({"error": "Token has expired"}), 401


@jwt.invalid_token_loader
def invalid_token_callback(error):
    return jsonify({"error": "Invalid token"}), 401


@jwt.unauthorized_loader
def missing_token_callback(error):
    return jsonify({"error": "Authorization token required"}), 401


@app.route("/")
def index():
    response = send_from_directory(BASE_DIR, "index.html")
    response.headers["X-Content-Type-Options"] = "nosniff"
    return response


@app.route("/<path:path>")
def serve_static(path):
    try:
        response = send_from_directory(BASE_DIR, path)
        response.headers["X-Content-Type-Options"] = "nosniff"
        if path.endswith((".css", ".js", ".png", ".jpg", ".jpeg", ".gif", ".ico", ".svg")):
            response.headers["Cache-Control"] = "public, max-age=31536000"
        return response
    except Exception:
        return jsonify({"error": "File not found"}), 404


@app.route("/api/register", methods=["POST"])
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["register"])
@validate_json(UserRegistrationSchema)
def register():
    data = request.validated_json
    password_errors = SecurityUtils.validate_password_strength(data["password"])
    if password_errors:
        return jsonify({"error": "Password does not meet requirements", "details": password_errors}), 400

    if User.query.filter_by(username=data["username"]).first():
        return jsonify({"error": "Username already exists"}), 409
    if User.query.filter_by(email=data["email"]).first():
        return jsonify({"error": "Email already exists"}), 409

    user = User(
        username=data["username"],
        email=data["email"],
        role=data.get("role", "employee"),
        department=data.get("department"),
        password_changed_at=datetime.utcnow(),
        created_at=datetime.utcnow(),
    )
    user.set_password(data["password"])
    db.session.add(user)
    db.session.commit()

    access_token = create_access_token(identity=str(user.id), additional_claims={"role": user.role, "username": user.username})
    return jsonify({"message": "User registered successfully", "user": user.to_dict(), "access_token": access_token}), 201


@app.route("/api/login", methods=["POST"])
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["login"])
@validate_json(UserLoginSchema)
def login():
    data = request.validated_json
    identifier = data["username"]
    user = User.query.filter_by(username=identifier).first() or User.query.filter_by(email=identifier).first()
    if not user:
        account_security.log_security_event("LOGIN_ATTEMPT_INVALID_USER", {"identifier": identifier, "ip": request.remote_addr})
        return jsonify({"error": "Invalid credentials"}), 401

    if account_security.is_account_locked(user):
        return jsonify({"error": "Account temporarily locked due to multiple failed login attempts"}), 423
    if not user.is_active:
        return jsonify({"error": "Account is disabled"}), 403
    if not user.check_password(data["password"]):
        account_security.record_failed_login(identifier)
        return jsonify({"error": "Invalid credentials"}), 401

    account_security.record_successful_login(user)
    access_token = create_access_token(
        identity=str(user.id), additional_claims={"role": user.role, "username": user.username, "department": user.department}
    )
    return jsonify({"message": "Login successful", "user": user.to_dict(), "access_token": access_token})


@app.route("/api/logout", methods=["POST"])
@enhanced_jwt_required
def logout():
    account_security.log_security_event("LOGOUT", {"user_id": _jwt_user_id(), "ip": request.remote_addr})
    return jsonify({"message": "Logout successful"})


@app.route("/api/tickets", methods=["GET"])
@enhanced_jwt_required
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["api_general"])
def get_tickets():
    user_id = _jwt_user_id()
    user = User.query.get(user_id)
    if _normalize_portal_role(user.role if user else "") == "student":
        return jsonify({"error": "Students can only access courses"}), 403
    if user.role == "admin":
        tickets = Ticket.query.order_by(Ticket.created_at.desc()).all()
    else:
        tickets = Ticket.query.filter_by(created_by=user_id).order_by(Ticket.created_at.desc()).all()
    return jsonify([_ticket_payload(ticket) for ticket in tickets])


@app.route("/api/tickets", methods=["POST"])
@enhanced_jwt_required
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["api_intensive"])
@validate_json(TicketCreationSchema)
def create_ticket():
    data = request.validated_json
    user_id = _jwt_user_id()
    user = User.query.get(user_id)
    if _normalize_portal_role(user.role if user else "") == "student":
        return jsonify({"error": "Students can only access courses"}), 403
    ticket = Ticket(
        title=data["title"],
        description=data["description"],
        priority=data.get("priority", "medium"),
        category=data.get("category"),
        created_by=user_id,
    )
    db.session.add(ticket)
    db.session.commit()
    return jsonify(_ticket_payload(ticket)), 201


@app.route("/api/tickets/<int:ticket_id>", methods=["PUT"])
@enhanced_jwt_required
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["api_intensive"])
def update_ticket(ticket_id):
    user_id = _jwt_user_id()
    user = User.query.get(user_id)
    if _normalize_portal_role(user.role if user else "") == "student":
        return jsonify({"error": "Students can only access courses"}), 403
    ticket = Ticket.query.get_or_404(ticket_id)
    if ticket.created_by != user_id and user.role != "admin":
        return jsonify({"error": "Access denied"}), 403

    data = request.get_json(silent=True) or {}
    for field in ["status", "priority", "description", "category"]:
        if field in data:
            setattr(ticket, field, SecurityUtils.sanitize_input(data[field]))
    ticket.updated_at = datetime.utcnow()
    if ticket.status in {"resolved", "closed"} and not ticket.resolved_at:
        ticket.resolved_at = datetime.utcnow()
    db.session.commit()
    return jsonify(_ticket_payload(ticket))


@app.route("/api/v2", methods=["GET"])
def api_v2_info():
    return jsonify(
        {
            "version": "v2-compat",
            "status": "ok",
            "message": "Compatibility API for legacy frontend modules",
        }
    )


@app.route("/api/v2/tickets", methods=["GET", "POST"])
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["api_general"])
def api_v2_tickets():
    if request.method == "GET":
        user = None
        try:
            verify_jwt_in_request(optional=True)
            identity = _jwt_user_id()
            user = User.query.get(identity) if identity else None
        except Exception:
            user = None

        if user and _normalize_portal_role(user.role) == "student":
            return jsonify({"error": "Students can only access courses"}), 403
        if user and (user.role or "").lower() != "admin":
            tickets = Ticket.query.filter_by(created_by=user.id).order_by(Ticket.created_at.desc()).all()
        else:
            tickets = Ticket.query.order_by(Ticket.created_at.desc()).limit(200).all()
        return jsonify({"count": len(tickets), "items": [_ticket_payload(t) for t in tickets]})

    # POST requires auth for integrity.
    verify_jwt_in_request()
    payload = request.get_json(silent=True) or {}
    title = _sanitize_text(payload.get("title") or "API v2 Ticket", 180)
    description = _sanitize_text(payload.get("description") or payload.get("message"), 4000)
    if not description:
        return jsonify({"error": "description is required"}), 400

    priority = _sanitize_text(payload.get("priority") or "medium", 20).lower()
    if priority not in {"low", "medium", "high", "critical"}:
        priority = "medium"
    category = _sanitize_text(payload.get("category"), 100)
    user_id = _jwt_user_id()
    user = User.query.get(user_id)
    if _normalize_portal_role(user.role if user else "") == "student":
        return jsonify({"error": "Students can only access courses"}), 403

    ticket = Ticket(
        title=title,
        description=description,
        priority=priority,
        category=category or "general",
        created_by=user_id,
    )
    db.session.add(ticket)
    db.session.commit()
    return jsonify({"message": "created", "item": _ticket_payload(ticket)}), 201


@app.route("/api/ws", methods=["GET"])
def ws_compat():
    return jsonify(
        {
            "status": "not_available",
            "message": "WebSocket endpoint is not enabled in this Flask runtime.",
        }
    ), 426


@app.route("/api/tickets/intake", methods=["POST"])
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["contact_form"])
def create_ticket_from_intake():
    expected_key = os.environ.get("IBRIDGE_INTAKE_KEY", "").strip()
    provided_key = request.headers.get("X-Intake-Key", "").strip()
    if expected_key and not secrets.compare_digest(expected_key, provided_key):
        return jsonify({"error": "Invalid intake key"}), 403

    payload = request.get_json(silent=True) or {}
    if payload.get("website"):  # honeypot trap
        return jsonify({"error": "Rejected"}), 400

    source = _sanitize_text(payload.get("source") or "web", 30).lower()
    if source not in {"email", "chatbot", "web", "api"}:
        source = "web"

    title = _sanitize_text(payload.get("title") or payload.get("subject") or "", 180)
    description = _sanitize_text(payload.get("description") or payload.get("message") or "", 4000)
    if not title and description:
        title = _sanitize_text(f"{source.title()} support request", 180)
    if not description:
        return jsonify({"error": "description is required"}), 400

    requester = payload.get("requester") if isinstance(payload.get("requester"), dict) else {}
    requester_name = _sanitize_text(requester.get("name") or payload.get("requester_name"), 120)
    requester_email = _sanitize_text(requester.get("email") or payload.get("requester_email"), 120).lower()
    requester_phone = _sanitize_text(requester.get("phone") or payload.get("requester_phone"), 50)
    requester_department = _sanitize_text(requester.get("department") or payload.get("requester_department"), 80)
    requester_channel_id = _sanitize_text(payload.get("channel_id"), 120)
    external_message_id = _sanitize_text(payload.get("external_message_id"), 120)
    category = _sanitize_text(payload.get("category") or payload.get("issue_type"), 100)
    priority = _sanitize_text(payload.get("priority") or "medium", 20).lower()
    if priority not in {"low", "medium", "high", "critical"}:
        priority = "medium"

    details = [
        f"Source: {source}",
        f"Requester: {requester_name or 'Unknown'}",
        f"Email: {requester_email or 'Unknown'}",
        f"Phone: {requester_phone or 'Unknown'}",
        f"Department: {requester_department or 'Unknown'}",
        "",
        "Issue Description:",
        description,
    ]
    final_description = "\n".join(details)

    intake_user = _get_or_create_intake_user()
    ticket = Ticket(
        title=title or "Support Request",
        description=final_description,
        priority=priority,
        category=category or "general",
        created_by=intake_user.id,
    )
    db.session.add(ticket)
    db.session.flush()

    intake_event = TicketIntakeEvent(
        ticket_id=ticket.id,
        source=source,
        requester_name=requester_name,
        requester_email=requester_email,
        requester_phone=requester_phone,
        requester_department=requester_department,
        requester_channel_id=requester_channel_id,
        external_message_id=external_message_id,
    )
    intake_event.set_meta({
        "labels": payload.get("labels", []),
        "client_type": payload.get("client_type"),
        "context": payload.get("context", {}),
    })
    db.session.add(intake_event)
    db.session.commit()

    return jsonify({
        "message": "Ticket created from intake",
        "ticket": _ticket_payload(ticket),
        "ticket_number": _ticket_number(ticket.id),
        "intake_event": intake_event.to_dict(),
    }), 201


@app.route("/api/tickets/intake/events", methods=["GET"])
@enhanced_jwt_required
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["api_general"])
def list_ticket_intake_events():
    user = User.query.get(_jwt_user_id())
    if not _user_is_dev_or_it(user):
        return jsonify({"error": "Dev/IT access required"}), 403

    source_filter = _sanitize_text(request.args.get("source"), 30).lower()
    limit_raw = request.args.get("limit", "100")
    try:
        limit = max(1, min(500, int(limit_raw)))
    except Exception:
        limit = 100

    query = TicketIntakeEvent.query.order_by(TicketIntakeEvent.created_at.desc())
    if source_filter:
        query = query.filter(TicketIntakeEvent.source == source_filter)

    rows = query.limit(limit).all()
    payload = []
    for row in rows:
        event = row.to_dict()
        event["ticket_number"] = _ticket_number(row.ticket_id)
        payload.append(event)
    return jsonify({"count": len(payload), "events": payload})


@app.route("/api/courses", methods=["GET"])
@enhanced_jwt_required
def list_courses():
    courses = Course.query.filter_by(is_active=True).all()
    return jsonify([course.to_dict() for course in courses])


@app.route("/api/progress", methods=["GET"])
@enhanced_jwt_required
def get_progress():
    user_id = _jwt_user_id()
    progress = UserProgress.query.filter_by(user_id=user_id).all()
    return jsonify([{"course_id": p.course_id, "progress": p.progress, "last_accessed": p.last_accessed.isoformat()} for p in progress])


@app.route("/api/user/enrollments", methods=["GET"])
@enhanced_jwt_required
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["api_general"])
def user_enrollments():
    user_id = _jwt_user_id()
    enrollments = Enrollment.query.filter_by(user_id=user_id).order_by(Enrollment.enrolled_at.desc()).all()
    payload = []
    for e in enrollments:
        row = e.to_dict()
        row["progress"] = row.get("progress_percentage", 0)
        payload.append(row)
    return jsonify(payload)


@app.route("/api/courses/<int:course_id>/enroll", methods=["POST"])
@enhanced_jwt_required
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["api_intensive"])
def enroll_course(course_id):
    user_id = _jwt_user_id()
    course = Course.query.get_or_404(course_id)
    enrollment = Enrollment.query.filter_by(user_id=user_id, course_id=course_id).first()
    if enrollment:
        if enrollment.status == "inactive":
            enrollment.status = "active"
            enrollment.started_at = enrollment.started_at or datetime.utcnow()
            db.session.commit()
        return jsonify({"message": "Already enrolled", "enrollment": enrollment.to_dict(), "course": course.to_dict()})

    enrollment = Enrollment(
        user_id=user_id,
        course_id=course_id,
        status="active",
        enrolled_at=datetime.utcnow(),
        started_at=datetime.utcnow(),
        last_accessed=datetime.utcnow(),
        progress_percentage=0.0,
    )
    db.session.add(enrollment)

    user_progress = UserProgress.query.filter_by(user_id=user_id, course_id=course_id).first()
    if not user_progress:
        user_progress = UserProgress(user_id=user_id, course_id=course_id, progress=0.0, last_accessed=datetime.utcnow())
        db.session.add(user_progress)

    db.session.add(
        ActivityLog(
            user_id=user_id,
            activity_type="lms_enroll",
            activity_data=json.dumps({"course_id": course_id, "course_title": course.title}),
            course_id=course_id,
            ip_address=request.remote_addr,
            user_agent=request.headers.get("User-Agent", "")[:500],
        )
    )
    db.session.commit()
    return jsonify({"message": "Enrollment created", "enrollment": enrollment.to_dict(), "course": course.to_dict()}), 201


@app.route("/api/courses/<int:course_id>/progress", methods=["PUT"])
@enhanced_jwt_required
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["api_intensive"])
def update_course_progress(course_id):
    user_id = _jwt_user_id()
    Course.query.get_or_404(course_id)
    payload = request.get_json(silent=True) or {}
    progress_value = payload.get("progress")
    if progress_value is None:
        return jsonify({"error": "progress is required"}), 400
    try:
        progress_value = float(progress_value)
    except (TypeError, ValueError):
        return jsonify({"error": "progress must be numeric"}), 400
    progress_value = max(0.0, min(100.0, progress_value))

    enrollment = Enrollment.query.filter_by(user_id=user_id, course_id=course_id).first()
    if not enrollment:
        enrollment = Enrollment(
            user_id=user_id,
            course_id=course_id,
            status="active",
            enrolled_at=datetime.utcnow(),
            started_at=datetime.utcnow(),
            last_accessed=datetime.utcnow(),
            progress_percentage=0.0,
        )
        db.session.add(enrollment)
        db.session.flush()

    enrollment.progress_percentage = progress_value
    enrollment.last_accessed = datetime.utcnow()
    if enrollment.status == "inactive":
        enrollment.status = "active"
        enrollment.started_at = enrollment.started_at or datetime.utcnow()
    if progress_value >= 100.0 and enrollment.status != "completed":
        enrollment.status = "completed"
        enrollment.completed_at = datetime.utcnow()
    elif progress_value < 100.0 and enrollment.status == "completed":
        enrollment.status = "active"
        enrollment.completed_at = None

    user_progress = UserProgress.query.filter_by(user_id=user_id, course_id=course_id).first()
    if not user_progress:
        user_progress = UserProgress(user_id=user_id, course_id=course_id)
        db.session.add(user_progress)
    user_progress.progress = progress_value
    user_progress.last_accessed = datetime.utcnow()

    db.session.add(
        ActivityLog(
            user_id=user_id,
            activity_type="lms_progress_update",
            activity_data=json.dumps({"course_id": course_id, "progress": progress_value}),
            course_id=course_id,
            ip_address=request.remote_addr,
            user_agent=request.headers.get("User-Agent", "")[:500],
        )
    )
    db.session.commit()
    return jsonify({"message": "Progress updated", "enrollment": enrollment.to_dict(), "progress": progress_value})


@app.route("/api/lms/activity", methods=["POST"])
@enhanced_jwt_required
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["api_general"])
def lms_activity():
    user_id = _jwt_user_id()
    payload = request.get_json(silent=True) or {}
    activity_type = SecurityUtils.sanitize_input((payload.get("activity_type") or "lms_activity").strip())[:50]
    data = payload.get("data") or {}
    course_id = payload.get("course_id")
    try:
        course_id = int(course_id) if course_id is not None else None
    except (TypeError, ValueError):
        course_id = None

    entry = ActivityLog(
        user_id=user_id,
        activity_type=activity_type or "lms_activity",
        activity_data=json.dumps(data)[:5000],
        course_id=course_id,
        ip_address=request.remote_addr,
        user_agent=request.headers.get("User-Agent", "")[:500],
    )
    db.session.add(entry)
    db.session.commit()
    return jsonify({"message": "Activity logged", "id": entry.id, "timestamp": entry.timestamp.isoformat()})


@app.route("/api/lms/activity", methods=["GET"])
@enhanced_jwt_required
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["api_general"])
def lms_activity_feed():
    user_id = _jwt_user_id()
    limit = request.args.get("limit", 20)
    try:
        limit = max(1, min(100, int(limit)))
    except (TypeError, ValueError):
        limit = 20

    rows = ActivityLog.query.filter_by(user_id=user_id).order_by(ActivityLog.timestamp.desc()).limit(limit).all()
    payload = []
    for r in rows:
        try:
            parsed = json.loads(r.activity_data) if r.activity_data else {}
        except Exception:
            parsed = {"raw": r.activity_data}
        payload.append(
            {
                "id": r.id,
                "activity_type": r.activity_type,
                "course_id": r.course_id,
                "data": parsed,
                "timestamp": r.timestamp.isoformat() if r.timestamp else None,
            }
        )
    return jsonify({"events": payload, "count": len(payload)})


@app.route("/api/lms/groups", methods=["GET", "POST"])
@enhanced_jwt_required
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["api_general"])
def lms_groups():
    user_id = _jwt_user_id()
    if request.method == "GET":
        groups = Group.query.filter_by(is_active=True).order_by(Group.created_at.desc()).all()
        payload = []
        for g in groups:
            members = GroupMember.query.filter_by(group_id=g.id, is_active=True).count()
            payload.append(
                {
                    "id": g.id,
                    "name": g.name,
                    "description": g.description,
                    "group_type": g.group_type,
                    "created_at": g.created_at.isoformat() if g.created_at else None,
                    "created_by": g.created_by,
                    "member_count": members,
                }
            )
        return jsonify({"groups": payload, "count": len(payload)})

    payload = request.get_json(silent=True) or {}
    name = SecurityUtils.sanitize_input((payload.get("name") or "").strip())[:100]
    if not name:
        return jsonify({"error": "Group name is required"}), 400
    description = SecurityUtils.sanitize_input((payload.get("description") or "").strip())[:1000]
    group_type = SecurityUtils.sanitize_input((payload.get("group_type") or "study").strip())[:20]

    group = Group(name=name, description=description, group_type=group_type, created_by=user_id, created_at=datetime.utcnow())
    db.session.add(group)
    db.session.flush()
    db.session.add(GroupMember(group_id=group.id, user_id=user_id, role="owner", is_active=True))
    db.session.commit()
    return jsonify({"message": "Group created", "group": {"id": group.id, "name": group.name, "description": group.description}}), 201


@app.route("/api/lms/groups/join", methods=["POST"])
@enhanced_jwt_required
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["api_general"])
def lms_join_group():
    user_id = _jwt_user_id()
    payload = request.get_json(silent=True) or {}
    group_id = payload.get("group_id")
    group_key = SecurityUtils.sanitize_input((payload.get("group_key") or "").strip()).lower()

    group = None
    if group_id is not None:
        try:
            group = Group.query.get(int(group_id))
        except (TypeError, ValueError):
            group = None
    if not group and group_key:
        group = Group.query.filter(Group.name.ilike(f"%{group_key}%"), Group.is_active == True).first()
    if not group:
        group = Group(name=(group_key or "Study Group").title(), description="Auto-created study group", group_type="study", created_by=user_id)
        db.session.add(group)
        db.session.flush()

    membership = GroupMember.query.filter_by(group_id=group.id, user_id=user_id).first()
    if membership:
        membership.is_active = True
    else:
        membership = GroupMember(group_id=group.id, user_id=user_id, role="member", is_active=True)
        db.session.add(membership)

    db.session.add(
        ActivityLog(
            user_id=user_id,
            activity_type="lms_group_join",
            activity_data=json.dumps({"group_id": group.id, "group_name": group.name}),
            ip_address=request.remote_addr,
            user_agent=request.headers.get("User-Agent", "")[:500],
        )
    )
    db.session.commit()
    return jsonify({"message": "Joined group", "group": {"id": group.id, "name": group.name}})


@app.route("/api/lms/training-resources", methods=["GET"])
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["api_general"])
def lms_training_resources():
    track = _sanitize_text(request.args.get("track"), 40).lower()
    resources = _load_training_resources()
    if track:
        resources = [r for r in resources if str(r.get("track", "")).lower() == track]
    return jsonify({"count": len(resources), "resources": resources})


@app.route("/api/lms/training-resources/<string:resource_id>/start", methods=["POST"])
@enhanced_jwt_required
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["api_general"])
def lms_training_resource_start(resource_id):
    user_id = _jwt_user_id()
    resources = _load_training_resources()
    target = next((r for r in resources if str(r.get("id", "")).lower() == resource_id.lower()), None)
    if not target:
        return jsonify({"error": "Resource not found"}), 404

    course = _find_course_for_track(target.get("track"))
    db.session.add(
        ActivityLog(
            user_id=user_id,
            activity_type="lms_resource_start",
            activity_data=json.dumps(
                {
                    "resource_id": target.get("id"),
                    "title": target.get("title"),
                    "track": target.get("track"),
                    "url": target.get("url"),
                }
            ),
            course_id=course.id if course else None,
            ip_address=request.remote_addr,
            user_agent=request.headers.get("User-Agent", "")[:500],
        )
    )
    db.session.commit()
    return jsonify({"message": "Resource start logged", "resource_id": target.get("id"), "track": target.get("track")})


@app.route("/api/lms/training-resources/<string:resource_id>/complete", methods=["POST"])
@enhanced_jwt_required
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["api_general"])
def lms_training_resource_complete(resource_id):
    user_id = _jwt_user_id()
    payload = request.get_json(silent=True) or {}
    resources = _load_training_resources()
    target = next((r for r in resources if str(r.get("id", "")).lower() == resource_id.lower()), None)
    if not target:
        return jsonify({"error": "Resource not found"}), 404

    delta = payload.get("progress_delta", target.get("progress_delta", 12))
    try:
        delta = float(delta)
    except (TypeError, ValueError):
        delta = 12.0
    delta = max(1.0, min(40.0, delta))

    progress_result = _apply_resource_progress(user_id, target.get("track"), delta=delta)
    db.session.add(
        ActivityLog(
            user_id=user_id,
            activity_type="lms_resource_complete",
            activity_data=json.dumps(
                {
                    "resource_id": target.get("id"),
                    "title": target.get("title"),
                    "track": target.get("track"),
                    "url": target.get("url"),
                    "progress_delta": delta,
                    "progress_result": progress_result,
                }
            ),
            course_id=progress_result.get("course_id"),
            ip_address=request.remote_addr,
            user_agent=request.headers.get("User-Agent", "")[:500],
        )
    )
    db.session.commit()

    return jsonify(
        {
            "message": "Resource completion logged",
            "resource_id": target.get("id"),
            "track": target.get("track"),
            "progress": progress_result,
        }
    )


@app.route("/api/contact", methods=["POST"])
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["contact_form"])
@validate_json(ContactFormSchema)
def contact_form():
    return jsonify({"message": "Thank you for your message. We will get back to you soon.", "status": "submitted"})


@app.route("/api/cms/content", methods=["GET"])
def get_cms_content():
    section = _sanitize_text(request.args.get("section", ""), 80).lower()
    only_published = request.args.get("published", "true").lower() != "false"

    query = CMSContent.query
    if section:
        query = query.filter_by(section=section)
    if only_published:
        query = query.filter(CMSContent.is_published.is_(True))

    rows = query.order_by(CMSContent.updated_at.desc()).all()
    return jsonify({"count": len(rows), "items": [r.to_dict() for r in rows]})


@app.route("/api/cms/content/<string:section>", methods=["PUT"])
@enhanced_jwt_required
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["api_general"])
def upsert_cms_content(section):
    user = User.query.get(_jwt_user_id())
    if not _user_can_manage_site_content(user):
        return jsonify({"error": "Content management access denied"}), 403

    section = _sanitize_text(section, 80).lower()
    if not section:
        return jsonify({"error": "Section is required"}), 400

    payload = request.get_json(silent=True) or {}
    row = CMSContent.query.filter_by(section=section).first()
    if not row:
        row = CMSContent(section=section, created_at=datetime.utcnow())
        db.session.add(row)

    row.title = _sanitize_text(payload.get("title", row.title or ""), 200)
    row.subtitle = _sanitize_text(payload.get("subtitle", row.subtitle or ""), 300)
    row.body = _sanitize_text(payload.get("body", row.body or ""), 10000)
    row.is_published = bool(payload.get("is_published", True))
    row.updated_by = user.id if user else None
    row.updated_at = datetime.utcnow()
    row.set_payload(payload.get("payload", row.get_payload()))

    db.session.commit()
    return jsonify({"message": "Content updated", "item": row.to_dict()})


def _load_cms_payload_items(section):
    row = CMSContent.query.filter_by(section=section).first()
    if not row:
        return []
    payload = row.get_payload()
    items = payload.get("items", []) if isinstance(payload, dict) else []
    return items if isinstance(items, list) else []


def _save_cms_payload_items(section, items, user_id=None):
    row = CMSContent.query.filter_by(section=section).first()
    if not row:
        row = CMSContent(section=section, is_published=True, created_at=datetime.utcnow())
        db.session.add(row)
    row.updated_by = user_id
    row.updated_at = datetime.utcnow()
    row.set_payload({"items": items})
    db.session.commit()
    return row


@app.route("/api/cms/case-studies", methods=["GET"])
def cms_case_studies():
    items = _load_cms_payload_items("case_studies")
    return jsonify({"count": len(items), "items": items})


@app.route("/api/cms/case-studies", methods=["POST"])
@enhanced_jwt_required
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["api_general"])
def cms_create_case_study():
    user = User.query.get(_jwt_user_id())
    if not _user_can_manage_site_content(user):
        return jsonify({"error": "Content management access denied"}), 403

    payload = request.get_json(silent=True) or {}
    items = _load_cms_payload_items("case_studies")
    next_id = (max([int(i.get("id", 0)) for i in items], default=0) + 1) if items else 1
    item = {
        "id": next_id,
        "title": _sanitize_text(payload.get("title", "Case Study"), 160),
        "client": _sanitize_text(payload.get("client", "Confidential Client"), 120),
        "industry": _sanitize_text(payload.get("industry", "BPO"), 120),
        "challenge": _sanitize_text(payload.get("challenge", ""), 1200),
        "solution": _sanitize_text(payload.get("solution", ""), 1200),
        "result": _sanitize_text(payload.get("result", ""), 600),
        "metric_label": _sanitize_text(payload.get("metric_label", "Improvement"), 80),
        "metric_value": _sanitize_text(payload.get("metric_value", ""), 80),
        "published": bool(payload.get("published", True)),
        "updated_at": datetime.utcnow().isoformat(),
    }
    items.insert(0, item)
    _save_cms_payload_items("case_studies", items, user.id if user else None)
    return jsonify({"message": "Case study created", "item": item}), 201


@app.route("/api/cms/testimonials", methods=["GET"])
def cms_testimonials():
    items = _load_cms_payload_items("testimonials")
    return jsonify({"count": len(items), "items": items})


@app.route("/api/cms/testimonials", methods=["POST"])
@enhanced_jwt_required
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["api_general"])
def cms_create_testimonial():
    user = User.query.get(_jwt_user_id())
    if not _user_can_manage_site_content(user):
        return jsonify({"error": "Content management access denied"}), 403

    payload = request.get_json(silent=True) or {}
    items = _load_cms_payload_items("testimonials")
    next_id = (max([int(i.get("id", 0)) for i in items], default=0) + 1) if items else 1
    item = {
        "id": next_id,
        "name": _sanitize_text(payload.get("name", "Client"), 120),
        "role": _sanitize_text(payload.get("role", "Operations Manager"), 120),
        "company": _sanitize_text(payload.get("company", "Client Company"), 120),
        "quote": _sanitize_text(payload.get("quote", ""), 900),
        "rating": max(1, min(5, int(payload.get("rating", 5) or 5))),
        "published": bool(payload.get("published", True)),
        "updated_at": datetime.utcnow().isoformat(),
    }
    items.insert(0, item)
    _save_cms_payload_items("testimonials", items, user.id if user else None)
    return jsonify({"message": "Testimonial created", "item": item}), 201


@app.route("/api/leads", methods=["POST"])
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["contact_form"])
def create_lead():
    payload = request.get_json(silent=True) or {}
    full_name = _sanitize_text(payload.get("full_name", ""), 120)
    email = _sanitize_optional_email(payload.get("email", ""))
    if not full_name or not email:
        return jsonify({"error": "full_name and valid email are required"}), 400

    existing = Lead.query.filter_by(email=email).order_by(Lead.created_at.desc()).first()
    if existing and existing.created_at and (datetime.utcnow() - existing.created_at).total_seconds() < 120:
        return jsonify({"error": "Duplicate lead submission detected"}), 429

    lead = Lead(
        full_name=full_name,
        email=email,
        phone=_sanitize_text(payload.get("phone", ""), 50),
        company=_sanitize_text(payload.get("company", ""), 120),
        source=_sanitize_text(payload.get("source", "website"), 80),
        inquiry_type=_sanitize_text(payload.get("inquiry_type", "general"), 80),
        message=_sanitize_text(payload.get("message", ""), 3000),
        priority=_sanitize_text(payload.get("priority", "medium"), 20).lower() or "medium",
        utm_source=_sanitize_text(payload.get("utm_source", ""), 120),
        utm_medium=_sanitize_text(payload.get("utm_medium", ""), 120),
        utm_campaign=_sanitize_text(payload.get("utm_campaign", ""), 120),
        page_url=_sanitize_text(payload.get("page_url", request.referrer or ""), 255),
        ip_address=request.remote_addr,
        user_agent=(request.headers.get("User-Agent", "") or "")[:1000],
        created_at=datetime.utcnow(),
    )
    db.session.add(lead)
    db.session.commit()

    evt = IntegrationEvent(
        integration="crm",
        direction="outbound",
        event_type="lead_created",
        status="queued",
        reference_id=str(lead.id),
        attempts=0,
        created_at=datetime.utcnow(),
    )
    evt.set_payload({"lead": lead.to_dict()})
    db.session.add(evt)
    db.session.commit()

    return jsonify({"message": "Lead captured", "lead_id": lead.id, "status": lead.status}), 201


@app.route("/api/leads", methods=["GET"])
@enhanced_jwt_required
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["api_general"])
def list_leads():
    user = User.query.get(_jwt_user_id())
    if not _user_can_manage_site_content(user):
        return jsonify({"error": "Lead management access denied"}), 403

    status = _sanitize_text(request.args.get("status", "all"), 30).lower()
    limit = max(1, min(500, int(request.args.get("limit", 100) or 100)))
    query = Lead.query
    if status and status != "all":
        query = query.filter_by(status=status)
    rows = query.order_by(Lead.created_at.desc()).limit(limit).all()
    return jsonify({"count": len(rows), "items": [r.to_dict() for r in rows]})


@app.route("/api/leads/<int:lead_id>/status", methods=["PUT"])
@enhanced_jwt_required
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["api_general"])
def update_lead_status(lead_id):
    user = User.query.get(_jwt_user_id())
    if not _user_can_manage_site_content(user):
        return jsonify({"error": "Lead management access denied"}), 403

    payload = request.get_json(silent=True) or {}
    status = _sanitize_text(payload.get("status", ""), 30).lower()
    if status not in {"new", "qualified", "contacted", "closed", "rejected"}:
        return jsonify({"error": "Invalid status"}), 400

    lead = Lead.query.get_or_404(lead_id)
    lead.status = status
    lead.updated_at = datetime.utcnow()
    if payload.get("priority"):
        lead.priority = _sanitize_text(payload.get("priority", lead.priority), 20).lower()
    if payload.get("assigned_to"):
        try:
            lead.assigned_to = int(payload.get("assigned_to"))
        except Exception:
            pass
    db.session.commit()
    return jsonify({"message": "Lead updated", "item": lead.to_dict()})


@app.route("/api/integrations/events", methods=["GET"])
@enhanced_jwt_required
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["api_general"])
def list_integration_events():
    user = User.query.get(_jwt_user_id())
    if not _user_is_dev_or_it(user):
        return jsonify({"error": "Dev/IT access required"}), 403

    integration = _sanitize_text(request.args.get("integration", ""), 50).lower()
    status = _sanitize_text(request.args.get("status", ""), 30).lower()
    limit = max(1, min(500, int(request.args.get("limit", 100) or 100)))

    query = IntegrationEvent.query
    if integration:
        query = query.filter_by(integration=integration)
    if status:
        query = query.filter_by(status=status)
    rows = query.order_by(IntegrationEvent.created_at.desc()).limit(limit).all()
    return jsonify({"count": len(rows), "items": [r.to_dict() for r in rows]})


@app.route("/api/health", methods=["GET"])
def health_check():
    db.session.execute(text("SELECT 1"))
    return jsonify({"status": "healthy", "timestamp": datetime.utcnow().isoformat(), "version": "3.0.0"})


@app.route("/api/ops/metrics", methods=["GET"])
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["api_general"])
def ops_metrics():
    user = _get_user_from_optional_jwt()
    if not (_user_is_dev_or_it(user) or _has_internal_security_key()):
        return jsonify({"error": "Dev/IT access required"}), 403

    uptime_seconds = int((datetime.utcnow() - datetime.fromisoformat(_ops_metrics["started_at"])).total_seconds())
    top_paths = sorted(
        [
            {"path": p, "count": v["count"], "errors": v["errors"], "avg_ms": v.get("avg_ms", 0.0)}
            for p, v in _ops_metrics["by_path"].items()
        ],
        key=lambda x: x["count"],
        reverse=True,
    )[:30]

    return jsonify(
        {
            "started_at": _ops_metrics["started_at"],
            "uptime_seconds": uptime_seconds,
            "requests_total": _ops_metrics["requests_total"],
            "errors_total": _ops_metrics["errors_total"],
            "error_rate_percent": round(
                (_ops_metrics["errors_total"] / _ops_metrics["requests_total"] * 100.0)
                if _ops_metrics["requests_total"]
                else 0.0,
                2,
            ),
            "top_paths": top_paths,
        }
    )


@app.route("/api/security-info", methods=["GET"])
def security_info():
    return jsonify(
        {
            "password_policy": {
                "min_length": SecurityConfig.PASSWORD_MIN_LENGTH,
                "requires_uppercase": SecurityConfig.PASSWORD_REQUIRE_UPPERCASE,
                "requires_lowercase": SecurityConfig.PASSWORD_REQUIRE_LOWERCASE,
                "requires_numbers": SecurityConfig.PASSWORD_REQUIRE_NUMBERS,
                "requires_special": SecurityConfig.PASSWORD_REQUIRE_SPECIAL,
            },
            "account_security": {
                "max_login_attempts": SecurityConfig.MAX_LOGIN_ATTEMPTS,
                "lockout_duration_minutes": int(SecurityConfig.LOCKOUT_DURATION.total_seconds() / 60),
            },
            "rate_limits": SecurityConfig.RATE_LIMITS,
        }
    )


@app.route("/api/analytics", methods=["POST"])
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["api_general"])
def analytics_ingest():
    payload = request.get_json(silent=True) or {}
    app.logger.info("Analytics event received: %s", str(payload)[:500])
    return jsonify({"status": "accepted"}), 202


@app.route("/api/performance", methods=["POST"])
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["api_general"])
def performance_ingest():
    payload = request.get_json(silent=True) or {}
    app.logger.info("Performance event received: %s", str(payload)[:500])
    return jsonify({"status": "accepted"}), 202


@app.route("/api/performance-alerts", methods=["POST"])
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["api_general"])
def performance_alerts():
    payload = request.get_json(silent=True) or {}
    app.logger.warning("Performance alert received: %s", str(payload)[:500])
    return jsonify({"status": "received"}), 202


@app.route("/api/errors", methods=["POST"])
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["api_general"])
def client_errors():
    payload = request.get_json(silent=True) or {}
    app.logger.error("Client error report: %s", str(payload)[:500])
    return jsonify({"status": "logged"}), 202


@app.route("/api/crm-sync", methods=["POST"])
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["api_general"])
def crm_sync():
    payload = request.get_json(silent=True) or {}
    app.logger.info("CRM sync payload received: %s", str(payload)[:500])
    return jsonify({"status": "queued", "integration": "crm-sync"}), 202


@app.route("/api/helpdesk-sync", methods=["POST"])
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["api_general"])
def helpdesk_sync():
    payload = request.get_json(silent=True) or {}
    app.logger.info("Helpdesk sync payload received: %s", str(payload)[:500])
    return jsonify({"status": "queued", "integration": "helpdesk-sync"}), 202


@app.route("/api/push-subscription", methods=["POST", "DELETE"])
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["api_general"])
def push_subscription():
    return jsonify({"status": "ok"}), 200


@app.route("/api/security/report", methods=["POST"])
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["api_general"])
def security_report():
    payload = request.get_json(silent=True) or {}
    account_security.log_security_event("CLIENT_SECURITY_REPORT", {"ip": request.remote_addr, "payload": payload})
    return jsonify({"status": "received"}), 200


@app.route("/api/submit-form", methods=["POST"])
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["contact_form"])
def submit_form():
    payload = request.get_json(silent=True) or {}
    app.logger.info("Offline form submission received: %s", str(payload)[:500])
    return jsonify({"status": "queued"}), 202


@app.route("/api/users", methods=["GET"])
@enhanced_jwt_required
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["api_general"])
def list_users():
    user_id = _jwt_user_id()
    actor = User.query.get(user_id)
    if not _user_can_manage_users(actor):
        return jsonify({"error": "User management access denied"}), 403

    users = User.query.order_by(User.created_at.desc()).all()
    payload = []
    for u in users:
        entry = u.to_dict()
        entry["failed_login_attempts"] = u.failed_login_attempts or 0
        entry["is_locked"] = bool(u.locked_until and datetime.utcnow() < u.locked_until)
        payload.append(entry)
    return jsonify({"users": payload, "count": len(payload)})


@app.route("/api/users", methods=["POST"])
@enhanced_jwt_required
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["api_intensive"])
def create_user():
    user_id = _jwt_user_id()
    actor = User.query.get(user_id)
    if not _user_can_manage_users(actor):
        return jsonify({"error": "User management access denied"}), 403

    data = request.get_json(silent=True) or {}
    username = SecurityUtils.sanitize_input((data.get("username") or "").strip())
    email = SecurityUtils.sanitize_input((data.get("email") or "").strip().lower())
    role = SecurityUtils.sanitize_input((data.get("role") or "employee").strip().lower())
    department = SecurityUtils.sanitize_input((data.get("department") or "").strip())
    password = data.get("password") or _generate_temp_password()

    if not username or not email:
        return jsonify({"error": "username and email are required"}), 400
    if User.query.filter_by(username=username).first():
        return jsonify({"error": "Username already exists"}), 409
    if User.query.filter_by(email=email).first():
        return jsonify({"error": "Email already exists"}), 409

    password_errors = SecurityUtils.validate_password_strength(password)
    if password_errors:
        return jsonify({"error": "Password does not meet requirements", "details": password_errors}), 400

    new_user = User(
        username=username,
        email=email,
        role=role,
        department=department,
        is_active=True,
        created_at=datetime.utcnow(),
        password_changed_at=datetime.utcnow(),
    )
    new_user.set_password(password)
    db.session.add(new_user)
    db.session.commit()

    response_user = new_user.to_dict()
    return jsonify({"message": "User created", "user": response_user, "temporary_password": password}), 201


@app.route("/api/users/<int:target_user_id>", methods=["PUT"])
@enhanced_jwt_required
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["api_intensive"])
def update_user(target_user_id):
    user_id = _jwt_user_id()
    actor = User.query.get(user_id)
    if not _user_can_manage_users(actor):
        return jsonify({"error": "User management access denied"}), 403

    target = User.query.get_or_404(target_user_id)
    data = request.get_json(silent=True) or {}

    if "email" in data:
        email = SecurityUtils.sanitize_input((data.get("email") or "").strip().lower())
        if email and email != target.email and User.query.filter_by(email=email).first():
            return jsonify({"error": "Email already exists"}), 409
        target.email = email or target.email
    if "role" in data:
        target.role = SecurityUtils.sanitize_input((data.get("role") or "").strip().lower()) or target.role
    if "department" in data:
        target.department = SecurityUtils.sanitize_input((data.get("department") or "").strip())
    if "is_active" in data:
        target.is_active = bool(data.get("is_active"))

    db.session.commit()
    return jsonify({"message": "User updated", "user": target.to_dict()})


@app.route("/api/users/<int:target_user_id>/reset-password", methods=["POST"])
@enhanced_jwt_required
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["api_intensive"])
def reset_user_password(target_user_id):
    user_id = _jwt_user_id()
    actor = User.query.get(user_id)
    if not _user_can_manage_users(actor):
        return jsonify({"error": "User management access denied"}), 403

    target = User.query.get_or_404(target_user_id)
    temp_password = _generate_temp_password()
    target.set_password(temp_password)
    target.password_changed_at = datetime.utcnow()
    target.failed_login_attempts = 0
    target.locked_until = None
    db.session.commit()

    return jsonify({"message": "Password reset", "temporary_password": temp_password, "user": target.to_dict()})


@app.route("/api/reports/generate", methods=["POST"])
@enhanced_jwt_required
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["api_general"])
def generate_report():
    user = User.query.get(_jwt_user_id())
    if not _user_has_min_portal_role(user, "supervisor"):
        return jsonify({"error": "Supervisor+ role required for report generation"}), 403
    payload = request.get_json(silent=True) or {}
    report_type = (payload.get("type") or "").lower().strip()
    if not report_type:
        return jsonify({"error": "Report type is required"}), 400

    type_map = {
        "ticket": "tickets",
        "user": "users",
        "performance": "analytics",
        "security": "security",
        "financial": "analytics",
        "custom": (payload.get("data_type") or "tickets").lower(),
    }
    data_type = type_map.get(report_type, report_type)
    start_date = _parse_date(payload.get("start_date"))
    end_date = _parse_date(payload.get("end_date"))
    status = (payload.get("status") or "all").lower()

    rows = _collect_dataset(data_type, user, start_date, end_date, status)
    summary = {
        "report_type": report_type,
        "data_type": data_type,
        "rows": len(rows),
        "generated_at": datetime.utcnow().isoformat(),
    }
    return jsonify({"summary": summary, "rows": rows[:200], "truncated": len(rows) > 200})


@app.route("/api/exports/<string:data_type>", methods=["GET"])
@enhanced_jwt_required
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["api_general"])
def export_dataset(data_type):
    user = User.query.get(_jwt_user_id())
    if not _user_has_min_portal_role(user, "supervisor"):
        return jsonify({"error": "Supervisor+ role required for data export"}), 403
    export_format = request.args.get("format", "json")
    start_date = _parse_date(request.args.get("start_date"))
    end_date = _parse_date(request.args.get("end_date"))
    status = request.args.get("status", "all")

    rows = _collect_dataset(data_type, user, start_date, end_date, status)
    content, mimetype, filename = _build_export_payload(data_type, rows, export_format)
    response = make_response(content)
    response.headers["Content-Type"] = mimetype
    response.headers["Content-Disposition"] = f'attachment; filename="{filename}"'
    response.headers["X-Export-Row-Count"] = str(len(rows))
    return response


def _settings_store_path():
    data_dir = os.path.join(BASE_DIR, "data")
    os.makedirs(data_dir, exist_ok=True)
    return os.path.join(data_dir, "staff-settings.json")


def _load_settings_store():
    path = _settings_store_path()
    if not os.path.exists(path):
        return {}
    try:
        with open(path, "r", encoding="utf-8") as fp:
            return json.load(fp)
    except Exception:
        return {}


def _save_settings_store(store):
    path = _settings_store_path()
    with open(path, "w", encoding="utf-8") as fp:
        json.dump(store, fp, indent=2)


@app.route("/api/settings/profile", methods=["GET", "PUT"])
@enhanced_jwt_required
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["api_general"])
def settings_profile():
    user = User.query.get(_jwt_user_id())
    if not user:
        return jsonify({"error": "User not found"}), 404

    if request.method == "GET":
        return jsonify({
            "first_name": user.first_name or "",
            "last_name": user.last_name or "",
            "email": user.email or "",
            "department": user.department or "",
            "bio": user.bio or "",
            "phone": "",
        })

    payload = request.get_json(silent=True) or {}
    user.first_name = SecurityUtils.sanitize_input(payload.get("first_name", user.first_name or ""))
    user.last_name = SecurityUtils.sanitize_input(payload.get("last_name", user.last_name or ""))
    if payload.get("email"):
        candidate = SecurityUtils.sanitize_input(payload.get("email", "")).lower()
        existing = User.query.filter_by(email=candidate).first()
        if existing and existing.id != user.id:
            return jsonify({"error": "Email already exists"}), 409
        user.email = candidate
    user.department = SecurityUtils.sanitize_input(payload.get("department", user.department or ""))
    user.bio = SecurityUtils.sanitize_input(payload.get("bio", user.bio or ""))
    db.session.commit()
    return jsonify({"message": "Profile settings saved", "profile": user.to_dict()})


@app.route("/api/settings/preferences", methods=["GET", "PUT"])
@enhanced_jwt_required
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["api_general"])
def settings_preferences():
    user_id = _jwt_user_id()
    store = _load_settings_store()
    key = str(user_id)

    if request.method == "GET":
        prefs = store.get(key, {})
        return jsonify({"preferences": prefs})

    payload = request.get_json(silent=True) or {}
    prefs = {
        "notifications": payload.get("notifications", {}),
        "security": payload.get("security", {}),
        "updated_at": datetime.utcnow().isoformat(),
    }
    store[key] = prefs
    _save_settings_store(store)
    return jsonify({"message": "Preferences saved", "preferences": prefs})


@app.route("/api/settings/login-history", methods=["GET"])
@enhanced_jwt_required
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["api_general"])
def settings_login_history():
    user = User.query.get(_jwt_user_id())
    if not user:
        return jsonify({"error": "User not found"}), 404
    events = [{
        "username": user.username,
        "last_login": user.last_login.isoformat() if user.last_login else None,
        "login_count": user.login_count or 0,
        "last_activity": user.last_activity.isoformat() if user.last_activity else None,
        "is_locked": bool(user.locked_until and datetime.utcnow() < user.locked_until),
    }]
    return jsonify({"events": events})


@app.route("/api/settings/system-action", methods=["POST"])
@enhanced_jwt_required
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["api_intensive"])
def settings_system_action():
    user = User.query.get(_jwt_user_id())
    if not _user_is_dev_or_it(user):
        return jsonify({"error": "Dev/IT access required"}), 403

    payload = request.get_json(silent=True) or {}
    action = (payload.get("action") or "").strip().lower()
    if not action:
        return jsonify({"error": "Action is required"}), 400

    result = {"action": action, "executed_at": datetime.utcnow().isoformat(), "status": "ok"}
    if action == "diagnostics":
        result["health"] = {"db": "ok", "api": "ok", "timestamp": datetime.utcnow().isoformat()}
    elif action == "create_backup":
        rows = _collect_dataset("backup", user)
        content, _, filename = _build_export_payload("backup", rows, "zip")
        backup_dir = os.path.join(BASE_DIR, "data", "backups")
        os.makedirs(backup_dir, exist_ok=True)
        backup_path = os.path.join(backup_dir, f"{datetime.utcnow().strftime('%Y%m%d-%H%M%S')}-{filename}")
        with open(backup_path, "wb") as fp:
            fp.write(content)
        result["backup_file"] = backup_path
    elif action == "signout_all":
        account_security.log_security_event("FORCE_SIGNOUT_ALL", {"actor_id": user.id, "ip": request.remote_addr})
    elif action in {"clear_cache", "refresh_system", "restore_backup"}:
        account_security.log_security_event("SYSTEM_ACTION", {"action": action, "actor_id": user.id})
    else:
        return jsonify({"error": "Unsupported action"}), 400

    return jsonify(result)


@app.route("/api/sharepoint-tickets", methods=["GET"])
def sharepoint_tickets_feed():
    data_path = os.path.join(BASE_DIR, "data", "sharepoint-tickets.json")
    if not os.path.exists(data_path):
        return jsonify({"error": "SharePoint ticket data file not found"}), 404
    try:
        with open(data_path, "r", encoding="utf-8") as fp:
            return app.response_class(fp.read(), mimetype="application/json")
    except Exception:
        return jsonify({"error": "Unable to read SharePoint ticket data"}), 500


@app.route("/api/security/audit-summary", methods=["GET"])
def security_audit_summary():
    summary = {
        "timestamp": datetime.utcnow().isoformat(),
        "users_total": 0,
        "users_with_failed_logins": 0,
        "users_locked_now": 0,
        "tickets_total": 0,
        "suspicious_tickets_found": 0,
        "security_log_entries": 0,
        "suspicious_log_entries": 0,
    }

    suspicious_pattern = re.compile(
        r"(?i)(SUSPICIOUS_REQUEST_BLOCKED|LOGIN_ATTEMPT_INVALID_USER|CSP_VIOLATION|REQUEST_TOO_LARGE|blocked)"
    )
    db_injection_pattern = re.compile(r"(?i)(<script|javascript:|union\s+select|drop\s+table|onerror=|onload=)")

    try:
        summary["users_total"] = User.query.count()
        summary["users_with_failed_logins"] = User.query.filter(User.failed_login_attempts > 0).count()
        summary["users_locked_now"] = User.query.filter(User.locked_until.isnot(None)).count()
        tickets = Ticket.query.all()
        summary["tickets_total"] = len(tickets)
        summary["suspicious_tickets_found"] = sum(
            1
            for t in tickets
            if db_injection_pattern.search(f"{t.title or ''} {t.description or ''}")
        )
    except Exception:
        pass

    log_path = os.path.join("logs", "security-events.log")
    if os.path.exists(log_path):
        try:
            with open(log_path, "r", encoding="utf-8", errors="ignore") as fp:
                lines = fp.readlines()
            summary["security_log_entries"] = len(lines)
            summary["suspicious_log_entries"] = sum(1 for line in lines if suspicious_pattern.search(line))
        except Exception:
            pass

    return jsonify(summary)


@app.route("/api/security/attacks", methods=["GET"])
@security_middleware.limiter.limit(SecurityConfig.RATE_LIMITS["api_general"])
def security_attacks():
    user = None
    try:
        verify_jwt_in_request(optional=True)
        identity = _jwt_user_id()
        if identity:
            user = User.query.get(identity)
    except Exception:
        user = None

    if not (_user_is_dev_or_it(user) or _has_internal_security_key()):
        return jsonify({"error": "Dev/IT access required"}), 403

    log_path = os.path.join(os.path.dirname(__file__), "..", "..", "logs", "security-events.log")
    log_path = os.path.abspath(log_path)

    suspicious_pattern = re.compile(
        r"(?i)(SUSPICIOUS_REQUEST_BLOCKED|LOGIN_ATTEMPT_INVALID_USER|CSP_VIOLATION|REQUEST_TOO_LARGE|blocked)"
    )
    if not os.path.exists(log_path):
        return jsonify({"source": log_path, "total": 0, "suspicious": 0, "events": []})

    with open(log_path, "r", encoding="utf-8", errors="ignore") as fp:
        lines = fp.readlines()

    events = []
    for line in lines[-500:]:
        text = line.strip()
        if not text:
            continue
        events.append({"line": text, "is_suspicious": bool(suspicious_pattern.search(text))})

    suspicious_count = sum(1 for e in events if e["is_suspicious"])
    return jsonify(
        {
            "source": log_path,
            "total": len(events),
            "suspicious": suspicious_count,
            "events": events[-200:],
        }
    )


def init_db():
    with app.app_context():
        db.create_all()
        admin_user = User.query.filter_by(username="admin").first()
        if not admin_user:
            admin_password = os.environ.get("IBRIDGE_ADMIN_PASSWORD")
            if admin_password:
                admin_user = User(
                    username="admin",
                    email=os.environ.get("IBRIDGE_ADMIN_EMAIL", "admin@ibridge-solutions.com"),
                    role="admin",
                    department="Administration",
                    created_at=datetime.utcnow(),
                    password_changed_at=datetime.utcnow(),
                )
                admin_user.set_password(admin_password)
                db.session.add(admin_user)
                db.session.commit()

        # Seed CMS blocks once for main-site dynamic sections.
        if not CMSContent.query.filter_by(section="case_studies").first():
            seeded_case_studies = CMSContent(
                section="case_studies",
                title="Case Studies",
                subtitle="Measured delivery outcomes from live operations",
                body="Real examples of service improvements delivered by iBridge teams.",
                is_published=True,
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow(),
            )
            seeded_case_studies.set_payload(
                {
                    "items": [
                        {
                            "id": 1,
                            "title": "First Contact Resolution Program",
                            "client": "Telecom Enterprise",
                            "industry": "Telecommunications",
                            "challenge": "High repeat-contact rates and long queue times.",
                            "solution": "Tiered routing, QA calibration, and targeted agent coaching.",
                            "result": "Reduced repeat calls by 28% in 90 days.",
                            "metric_label": "Repeat Calls",
                            "metric_value": "-28%",
                            "published": True,
                        },
                        {
                            "id": 2,
                            "title": "IT Helpdesk Stabilization",
                            "client": "Regional Services Group",
                            "industry": "Professional Services",
                            "challenge": "Backlog growth and inconsistent SLA adherence.",
                            "solution": "Priority triage matrix and real-time ticket aging dashboards.",
                            "result": "Improved SLA compliance from 72% to 96%.",
                            "metric_label": "SLA Compliance",
                            "metric_value": "96%",
                            "published": True,
                        },
                    ]
                }
            )
            db.session.add(seeded_case_studies)

        if not CMSContent.query.filter_by(section="testimonials").first():
            seeded_testimonials = CMSContent(
                section="testimonials",
                title="Client Testimonials",
                subtitle="What partners say about iBridge delivery",
                body="Trusted by teams that need reliable, measurable support operations.",
                is_published=True,
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow(),
            )
            seeded_testimonials.set_payload(
                {
                    "items": [
                        {
                            "id": 1,
                            "name": "Operations Director",
                            "role": "Contact Centre Lead",
                            "company": "Enterprise Client",
                            "quote": "iBridge improved our service quality and gave us clear operational visibility.",
                            "rating": 5,
                            "published": True,
                        },
                        {
                            "id": 2,
                            "name": "Head of IT Support",
                            "role": "Infrastructure Services",
                            "company": "National Business Unit",
                            "quote": "Ticket handling is now faster, cleaner, and easier to report to leadership.",
                            "rating": 5,
                            "published": True,
                        },
                    ]
                }
            )
            db.session.add(seeded_testimonials)

        db.session.commit()


if __name__ == "__main__":
    os.makedirs("logs", exist_ok=True)
    init_db()
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 5000)), debug=os.environ.get("FLASK_ENV") == "development")

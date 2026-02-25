"""
Security middleware and validation helpers for iBridge backend.
"""

from datetime import datetime, timedelta
from functools import wraps
import logging
from logging.handlers import RotatingFileHandler
import os
import re

import bleach
from flask import jsonify, request
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from marshmallow import Schema, ValidationError, fields, validate


class SecurityConfig:
    RATE_LIMITS = {
        "login": "5 per minute",
        "register": "3 per minute",
        "api_general": "100 per minute",
        "api_intensive": "20 per minute",
        "contact_form": "5 per minute",
    }

    PASSWORD_MIN_LENGTH = 8
    PASSWORD_REQUIRE_UPPERCASE = True
    PASSWORD_REQUIRE_LOWERCASE = True
    PASSWORD_REQUIRE_NUMBERS = True
    PASSWORD_REQUIRE_SPECIAL = True

    MAX_LOGIN_ATTEMPTS = 5
    LOCKOUT_DURATION = timedelta(minutes=30)
    USERNAME_PATTERN = r"^[a-zA-Z0-9_-]{3,20}$"
    EMAIL_MAX_LENGTH = 254
    TEXT_FIELD_MAX_LENGTH = 2000
    MAX_REQUEST_SIZE = 2 * 1024 * 1024  # 2 MB
    SUSPICIOUS_INPUT_PATTERNS = [
        r"(?i)<script",
        r"(?i)javascript:",
        r"(?i)onerror\s*=",
        r"(?i)onload\s*=",
        r"(?i)union\s+select",
        r"(?i)drop\s+table",
        r"(?i)insert\s+into",
        r"(?i)\.\./",
        r"(?i)%2e%2e",
        r"(?i)\b(cmd\.exe|powershell|/bin/sh)\b",
    ]


class UserRegistrationSchema(Schema):
    username = fields.Str(
        required=True,
        validate=[
            validate.Length(min=3, max=20),
            validate.Regexp(SecurityConfig.USERNAME_PATTERN),
        ],
    )
    email = fields.Email(required=True, validate=validate.Length(max=SecurityConfig.EMAIL_MAX_LENGTH))
    password = fields.Str(required=True, validate=validate.Length(min=SecurityConfig.PASSWORD_MIN_LENGTH))
    role = fields.Str(validate=validate.OneOf(["admin", "employee", "customer", "learner", "instructor"]))
    department = fields.Str(validate=validate.Length(max=100))


class UserLoginSchema(Schema):
    username = fields.Str(required=True, validate=validate.Length(min=1, max=120))
    password = fields.Str(required=True, validate=validate.Length(min=1))


class TicketCreationSchema(Schema):
    title = fields.Str(required=True, validate=validate.Length(min=3, max=200))
    description = fields.Str(required=True, validate=validate.Length(min=5, max=SecurityConfig.TEXT_FIELD_MAX_LENGTH))
    priority = fields.Str(validate=validate.OneOf(["low", "medium", "high", "urgent", "critical"]))
    category = fields.Str(validate=validate.Length(max=100))


class ContactFormSchema(Schema):
    name = fields.Str(required=True, validate=validate.Length(min=2, max=100))
    email = fields.Email(required=True)
    subject = fields.Str(required=True, validate=validate.Length(min=3, max=200))
    message = fields.Str(required=True, validate=validate.Length(min=5, max=SecurityConfig.TEXT_FIELD_MAX_LENGTH))


class SecurityUtils:
    @staticmethod
    def sanitize_input(value, allow_html=False):
        if value is None:
            return value
        if not isinstance(value, str):
            return value
        if allow_html:
            return bleach.clean(value, tags=["p", "br", "strong", "em", "ul", "ol", "li"], strip=True)
        return bleach.clean(value, tags=[], strip=True)

    @staticmethod
    def validate_password_strength(password):
        errors = []
        if len(password) < SecurityConfig.PASSWORD_MIN_LENGTH:
            errors.append(f"Password must be at least {SecurityConfig.PASSWORD_MIN_LENGTH} characters")
        if SecurityConfig.PASSWORD_REQUIRE_UPPERCASE and not re.search(r"[A-Z]", password):
            errors.append("Password must include an uppercase letter")
        if SecurityConfig.PASSWORD_REQUIRE_LOWERCASE and not re.search(r"[a-z]", password):
            errors.append("Password must include a lowercase letter")
        if SecurityConfig.PASSWORD_REQUIRE_NUMBERS and not re.search(r"\d", password):
            errors.append("Password must include a number")
        if SecurityConfig.PASSWORD_REQUIRE_SPECIAL and not re.search(r"[!@#$%^&*(),.?\":{}|<>]", password):
            errors.append("Password must include a special character")
        return errors


class SecurityMiddleware:
    def __init__(self, app):
        self.app = app
        self.limiter = Limiter(key_func=get_remote_address, app=app, default_limits=["1000 per hour"])
        self.security_logger = logging.getLogger("security")
        self._setup_logging()
        self._setup_request_guards()
        self._setup_headers()

    def _setup_logging(self):
        if self.security_logger.handlers:
            return
        os.makedirs("logs", exist_ok=True)
        handler = RotatingFileHandler("logs/security-events.log", maxBytes=2_000_000, backupCount=5)
        formatter = logging.Formatter("%(asctime)s %(levelname)s %(message)s")
        handler.setFormatter(formatter)
        self.security_logger.setLevel(logging.INFO)
        self.security_logger.addHandler(handler)

    def _looks_suspicious(self, value):
        if not value:
            return False
        text = str(value)
        return any(re.search(pattern, text) for pattern in SecurityConfig.SUSPICIOUS_INPUT_PATTERNS)

    def _setup_request_guards(self):
        @self.app.before_request
        def inspect_request():
            if request.content_length and request.content_length > SecurityConfig.MAX_REQUEST_SIZE:
                self.security_logger.warning(
                    "SECURITY_EVENT:REQUEST_TOO_LARGE ip=%s path=%s size=%s",
                    request.remote_addr,
                    request.path,
                    request.content_length,
                )
                return jsonify({"error": "Request too large"}), 413

            inspected_parts = [
                request.path,
                request.query_string.decode("utf-8", errors="ignore"),
            ]

            if request.is_json:
                data = request.get_json(silent=True)
                if data is not None:
                    inspected_parts.append(str(data))
            else:
                inspected_parts.append(str(request.form.to_dict(flat=False)))

            combined = " ".join(inspected_parts)
            if self._looks_suspicious(combined):
                self.security_logger.warning(
                    "SECURITY_EVENT:SUSPICIOUS_REQUEST_BLOCKED ip=%s method=%s path=%s ua=%s",
                    request.remote_addr,
                    request.method,
                    request.path,
                    request.headers.get("User-Agent", ""),
                )
                return jsonify({"error": "Suspicious request blocked"}), 403

    def _setup_headers(self):
        @self.app.after_request
        def add_security_headers(response):
            response.headers["X-Content-Type-Options"] = "nosniff"
            response.headers["X-Frame-Options"] = "DENY"
            response.headers["X-XSS-Protection"] = "1; mode=block"
            response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
            response.headers["Permissions-Policy"] = "geolocation=(), microphone=(), camera=(), payment=()"
            response.headers["X-Permitted-Cross-Domain-Policies"] = "none"
            response.headers["Cross-Origin-Opener-Policy"] = "same-origin"
            response.headers["Cross-Origin-Resource-Policy"] = "same-origin"
            response.headers["Content-Security-Policy"] = (
                "default-src 'self'; "
                "script-src 'self' 'unsafe-inline' https://cdnjs.cloudflare.com https://www.googletagmanager.com https://www.google-analytics.com; "
                "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; "
                "font-src 'self' https://fonts.gstatic.com; "
                "img-src 'self' data: https:; "
                "connect-src 'self' https://www.google-analytics.com https://www.googletagmanager.com https://www.google.com https://maps.googleapis.com https://www.openstreetmap.org; "
                "frame-src 'self' https://www.google.com https://www.google.com/maps https://www.openstreetmap.org; "
                "frame-ancestors 'none'; base-uri 'self'; form-action 'self'"
            )
            if request.is_secure:
                response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains; preload"
            return response


class AccountSecurityManager:
    def __init__(self, db):
        self.db = db
        self.logger = logging.getLogger("security")

    def record_failed_login(self, identifier):
        from models import User

        user = User.query.filter_by(username=identifier).first() or User.query.filter_by(email=identifier).first()
        if not user:
            return
        user.failed_login_attempts = (user.failed_login_attempts or 0) + 1
        user.last_failed_login = datetime.utcnow()
        if user.failed_login_attempts >= SecurityConfig.MAX_LOGIN_ATTEMPTS:
            user.locked_until = datetime.utcnow() + SecurityConfig.LOCKOUT_DURATION
        self.db.session.commit()

    def record_successful_login(self, user):
        user.failed_login_attempts = 0
        user.locked_until = None
        user.last_login = datetime.utcnow()
        user.login_count = (user.login_count or 0) + 1
        self.db.session.commit()

    def is_account_locked(self, user):
        if not user.locked_until:
            return False
        if datetime.utcnow() < user.locked_until:
            return True
        user.locked_until = None
        user.failed_login_attempts = 0
        self.db.session.commit()
        return False

    def log_security_event(self, event_type, details):
        self.logger.warning("SECURITY_EVENT:%s - %s", event_type, details)


def validate_json(schema_class):
    def decorator(f):
        @wraps(f)
        def wrapped(*args, **kwargs):
            try:
                schema = schema_class()
                data = schema.load(request.get_json() or {})
                for key, value in list(data.items()):
                    if isinstance(value, str):
                        data[key] = SecurityUtils.sanitize_input(value)
                request.validated_json = data
                return f(*args, **kwargs)
            except ValidationError as exc:
                return jsonify({"error": "Validation failed", "details": exc.messages}), 400
            except Exception:
                return jsonify({"error": "Invalid request format"}), 400

        return wrapped

    return decorator


def enhanced_jwt_required(f):
    from flask_jwt_extended import get_jwt_identity, jwt_required
    from models import User, db

    @wraps(f)
    @jwt_required()
    def wrapped(*args, **kwargs):
        identity = get_jwt_identity()
        try:
            user_id = int(identity)
        except (TypeError, ValueError):
            return jsonify({"error": "Invalid user identity"}), 401
        user = User.query.get(user_id)
        if not user or not user.is_active:
            return jsonify({"error": "Account not found or inactive"}), 401
        if user.locked_until and datetime.utcnow() < user.locked_until:
            return jsonify({"error": "Account is temporarily locked"}), 423
        user.last_activity = datetime.utcnow()
        db.session.commit()
        return f(*args, **kwargs)

    return wrapped


def setup_csp_violation_reporting(app):
    @app.route("/api/csp-violation-report", methods=["POST"])
    def csp_violation_report():
        logging.getLogger("security").warning("CSP_VIOLATION:%s", request.get_json(silent=True))
        return "", 204


__all__ = [
    "SecurityConfig",
    "SecurityUtils",
    "SecurityMiddleware",
    "AccountSecurityManager",
    "validate_json",
    "enhanced_jwt_required",
    "UserRegistrationSchema",
    "UserLoginSchema",
    "TicketCreationSchema",
    "ContactFormSchema",
    "setup_csp_violation_reporting",
]

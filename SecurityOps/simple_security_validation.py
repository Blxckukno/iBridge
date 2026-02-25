
# Advanced SQL Security System - Auto-generated Security Patch

# Advanced RCE Protection - Security Enhancement
import builtins
import subprocess
import os
import sys
from functools import wraps

class AdvancedRCEProtection:
    """Advanced Remote Code Execution protection system"""
    
    @staticmethod
    def initialize():
        """Initialize RCE protection"""
        
        # Block dangerous built-in functions
        def blocked_eval(*args, **kwargs):
            raise SecurityError("eval() function is permanently disabled")
        
        def blocked_exec(*args, **kwargs):
            raise SecurityError("exec() function is permanently disabled")
        
        def blocked_compile(*args, **kwargs):
            raise SecurityError("compile() function is permanently disabled")
        
        # Override built-ins
        builtins.eval = blocked_eval
        builtins.exec = blocked_exec
        builtins.compile = blocked_compile
        
        # Secure subprocess
        original_call = subprocess.call
        original_run = subprocess.run
        original_popen = subprocess.Popen
        
        def secure_call(*args, **kwargs):
            if kwargs.get('shell', False):
                raise SecurityError("Shell execution not permitted")
            if len(args) > 0 and isinstance(args[0], str):
                raise SecurityError("String commands not permitted")
            return original_call(*args, **kwargs)
        
        def secure_run(*args, **kwargs):
            if kwargs.get('shell', False):
                raise SecurityError("Shell execution not permitted")
            if len(args) > 0 and isinstance(args[0], str):
                raise SecurityError("String commands not permitted")
            return original_run(*args, **kwargs)
        
        def secure_popen(*args, **kwargs):
            if kwargs.get('shell', False):
                raise SecurityError("Shell execution not permitted")
            if len(args) > 0 and isinstance(args[0], str):
                raise SecurityError("String commands not permitted")
            return original_popen(*args, **kwargs)
        
        subprocess.call = secure_call
        subprocess.run = secure_run
        subprocess.Popen = secure_popen
        
        # Block os.system
        original_system = os.system
        def blocked_system(*args, **kwargs):
            raise SecurityError("os.system() is permanently disabled")
        os.system = blocked_system
        
        print("🔒 Advanced RCE Protection initialized")

class SecurityError(Exception):
    """Security violation exception"""
    pass

# Initialize RCE protection immediately
AdvancedRCEProtection.initialize()


import sqlite3
import re
import hashlib
import secrets
from typing import List, Dict, Any, Optional
import logging

class SQLSecurityManager:
    """Advanced SQL injection prevention system"""
    
    def __init__(self, db_path: str):
        self.db_path = db_path
        self.logger = logging.getLogger('sql_security')
        self.blocked_patterns = [
            r"('|(\x27)|(\x2D)|(\x2D)|(\x23)|(\x3B))",  # Basic injection characters
            r"(\x3D)|(\x27)|(\x22)|(\x5C)|(\x3B)",      # Hex encoded
            r"(union|select|insert|delete|update|create|drop|exec|execute)",  # SQL keywords
            r"(script|javascript|vbscript|onload|onerror)",    # XSS attempts
            r"(\x3C|\x3E|\x22|\x27)",                     # HTML/JS injection
            r"(\d+\s*=\s*\d+)",                           # Always true conditions
            r"(or\s+\d+\s*=\s*\d+)",                     # OR injection
            r"(and\s+\d+\s*=\s*\d+)",                    # AND injection
        ]
    
    def validate_input(self, user_input: str) -> str:
        """Comprehensive input validation and sanitization"""
        if not isinstance(user_input, str):
            return str(user_input)
        
        # Length limit
        if len(user_input) > 1000:
            raise ValueError("Input too long")
        
        # Check for malicious patterns
        input_lower = user_input.lower()
        for pattern in self.blocked_patterns:
            if re.search(pattern, input_lower, re.IGNORECASE):
                self.logger.warning(f"Blocked malicious input: {pattern}")
                raise ValueError("Malicious input detected")
        
        # Basic sanitization
        sanitized = user_input.replace("'", "''")  # Escape single quotes
        sanitized = re.sub(r'[\x00-\x1f\x7f-\x9f]', '', sanitized)  # Remove control chars
        
        return sanitized[:255]  # Truncate to safe length
    
    def execute_query(self, query: str, params: Optional[List] = None) -> List[Dict]:
        """Execute parameterized queries safely"""
        # Validate query structure
        if not self.is_safe_query(query):
            raise ValueError("Unsafe query structure")
        
        # Validate parameters
        if params:
            validated_params = [self.validate_input(str(p)) for p in params]
        else:
            validated_params = []
        
        try:
            conn = sqlite3.connect(self.db_path)
            conn.row_factory = sqlite3.Row  # Return dict-like rows
            cursor = conn.cursor()
            
            if validated_params:
                cursor.execute(query, validated_params)
            else:
                cursor.execute(query)
            
            if query.strip().lower().startswith('select'):
                results = [dict(row) for row in cursor.fetchall()]
            else:
                conn.commit()
                results = [{"affected_rows": cursor.rowcount}]
            
            conn.close()
            return results
            
        except sqlite3.Error as e:
            self.logger.error(f"Database error: {e}")
            raise ValueError("Database operation failed")
    
    def is_safe_query(self, query: str) -> bool:
        """Validate query structure for safety"""
        query_lower = query.lower().strip()
        
        # Must be parameterized (contain ? placeholders)
        if "?" not in query and any(word in query_lower for word in ['where', 'set', 'values']):
            self.logger.warning("Non-parameterized query detected")
            return False
        
        # No string concatenation patterns
        if re.search(r'\+|%s|\{.*\}|f["\'].*\{.*\}', query):
            self.logger.warning("String concatenation in query")
            return False
        
        # Check for dangerous SQL keywords in unexpected places
        dangerous_in_data = ['drop', 'create', 'alter', 'exec', 'execute', 'sp_', 'xp_']
        for danger in dangerous_in_data:
            if danger in query_lower and not query_lower.startswith(danger):
                self.logger.warning(f"Dangerous keyword in query: {danger}")
                return False
        
        return True
    
    def create_secure_connection(self):
        """Create a secure database connection with safety settings"""
        conn = sqlite3.connect(self.db_path)
        
        # Enable foreign key constraints
        conn.execute("PRAGMA foreign_keys = ON")
        
        # Set secure defaults
        conn.execute("PRAGMA secure_delete = ON")
        conn.execute("PRAGMA auto_vacuum = INCREMENTAL")
        
        return conn

# Global SQL security instance
sql_security = None

def init_sql_security(db_path: str):
    """Initialize SQL security system"""
    global sql_security
    sql_security = SQLSecurityManager(db_path)
    print("🔒 SQL Security System initialized")

def secure_query(query: str, params: Optional[List] = None) -> List[Dict]:
    """Secure query execution wrapper"""
    if sql_security is None:
        raise RuntimeError("SQL security not initialized")
    return sql_security.execute_query(query, params)



# Secure Execution Framework - Auto-generated Security Patch
import subprocess
import shlex
import os
import sys
from pathlib import Path
import logging

# Configure security logging
security_logger = logging.getLogger('security')
security_logger.setLevel(logging.WARNING)
handler = logging.FileHandler('security.log')
handler.setFormatter(logging.Formatter('%(asctime)s - SECURITY - %(message)s'))
security_logger.addHandler(handler)

class SecureExecutionFramework:
    """Secure command execution with comprehensive validation"""
    
    ALLOWED_COMMANDS = {
        'git': ['status', 'add', 'commit', 'push', 'pull', 'clone'],
        'python': ['-m', '-c'],
        'pip': ['install', 'list', 'show', 'freeze'],
        'node': ['--version'],
        'npm': ['install', 'list', 'audit']
    }
    
    @staticmethod
    def validate_command(command, args=None):
        """Validate command against whitelist"""
        if command not in SecureExecutionFramework.ALLOWED_COMMANDS:
            security_logger.warning(f"Blocked unauthorized command: {command}")
            return False
        
        if args:
            allowed_args = SecureExecutionFramework.ALLOWED_COMMANDS[command]
            for arg in args:
                if not any(arg.startswith(allowed) for allowed in allowed_args):
                    security_logger.warning(f"Blocked unauthorized argument: {arg}")
                    return False
        
        return True
    
    @staticmethod
    def secure_execute(command, args=None, cwd=None):
        """Execute command securely"""
        if not SecureExecutionFramework.validate_command(command, args):
            raise SecurityError(f"Command not allowed: {command}")
        
        # Sanitize arguments
        if args:
            safe_args = [shlex.quote(str(arg)) for arg in args if arg]
            cmd_list = [command] + safe_args
        else:
            cmd_list = [command]
        
        try:
            result = subprocess.run(
                cmd_list,
                cwd=cwd,
                capture_output=True,
                text=True,
                timeout=30,
                check=False,
                shell=False  # Never use shell=True
            )
            
            if result.returncode != 0:
                security_logger.warning(f"Command failed: {command} - {result.stderr}")
            
            return result
            
        except subprocess.TimeoutExpired:
            security_logger.error(f"Command timeout: {command}")
            raise SecurityError("Command execution timeout")
        except Exception as e:
            security_logger.error(f"Command execution error: {e}")
            raise SecurityError(f"Execution failed: {e}")

class SecurityError(Exception):
    """Custom security exception"""
    pass

# Disable dangerous functions
def blocked_eval(*args, **kwargs):
    security_logger.error("Attempt to use eval() - BLOCKED")
    raise SecurityError("eval() function is disabled for security")

def blocked_exec(*args, **kwargs):
    security_logger.error("Attempt to use exec() - BLOCKED")
    raise SecurityError("exec() function is disabled for security")

def blocked_compile(*args, **kwargs):
    security_logger.error("Attempt to use compile() - BLOCKED")
    raise SecurityError("compile() function is disabled for security")

# Override dangerous built-ins
import builtins
builtins.eval = blocked_eval
builtins.exec = blocked_exec
builtins.compile = blocked_compile

# Secure subprocess wrapper
original_call = subprocess.call
original_run = subprocess.run
original_popen = subprocess.Popen

def secure_call(*args, **kwargs):
    if kwargs.get('shell', False):
        security_logger.error("Blocked subprocess.call with shell=True")
        raise SecurityError("shell=True not permitted")
    return original_call(*args, **kwargs)

def secure_run(*args, **kwargs):
    if kwargs.get('shell', False):
        security_logger.error("Blocked subprocess.run with shell=True")
        raise SecurityError("shell=True not permitted")
    return original_run(*args, **kwargs)

def secure_popen(*args, **kwargs):
    if kwargs.get('shell', False):
        security_logger.error("Blocked subprocess.Popen with shell=True")
        raise SecurityError("shell=True not permitted")
    return original_popen(*args, **kwargs)

subprocess.call = secure_call
subprocess.run = secure_run
subprocess.Popen = secure_popen

print("🔒 Secure Execution Framework loaded")


#!/usr/bin/env python3
"""
Simple Security Validation Script for iBridge
Validates basic security configurations without external dependencies
"""

import os
import sys
import json
import hashlib
from datetime import datetime

def validate_security_files():
    """Validate that all security files are present"""
    print("🔒 iBridge Security Validation")
    print("=" * 50)
    
    required_files = [
        "backend/security_enhancements.py",
        "backend/app.py",
        "js/csp-security-manager.js", 
        "security_config.env",
        "SECURITY_ASSESSMENT_REPORT.md",
        "SECURITY_IMPLEMENTATION_GUIDE.md"
    ]
    
    missing_files = []
    present_files = []
    
    for file_path in required_files:
        if os.path.exists(file_path):
            present_files.append(file_path)
            print(f"✅ {file_path}")
        else:
            missing_files.append(file_path)
            print(f"❌ {file_path}")
    
    print(f"\n📊 Security Files Status:")
    print(f"   Present: {len(present_files)}/{len(required_files)}")
    print(f"   Missing: {len(missing_files)}")
    
    return len(missing_files) == 0

def validate_html_security():
    """Validate HTML security headers"""
    print(f"\n🌐 HTML Security Validation")
    print("-" * 30)
    
    html_files = ["index.html", "about.html", "services.html", "contact.html"]
    security_issues = []
    
    for html_file in html_files:
        if not os.path.exists(html_file):
            continue
            
        with open(html_file, 'r', encoding='utf-8') as f:
            content = f.read()
            
        # Check for secure CSP - specifically script-src
        if "script-src 'self' 'unsafe-inline'" in content:
            security_issues.append(f"{html_file}: Contains 'unsafe-inline' in script-src")
            print(f"⚠️  {html_file}: CSP contains unsafe-inline in script-src")
        elif "script-src 'self' 'nonce-" in content:
            print(f"✅ {html_file}: Secure nonce-based CSP")
        else:
            security_issues.append(f"{html_file}: Missing or insecure CSP")
            print(f"❌ {html_file}: Missing secure CSP")
        
        # Check for security headers
        security_headers = [
            "X-Content-Type-Options",
            "X-Frame-Options", 
            "X-XSS-Protection",
            "Strict-Transport-Security"
        ]
        
        for header in security_headers:
            if header in content:
                print(f"✅ {html_file}: {header} present")
            else:
                security_issues.append(f"{html_file}: Missing {header}")
                print(f"❌ {html_file}: Missing {header}")
    
    return len(security_issues) == 0

def validate_backend_security():
    """Validate backend security configuration"""
    print(f"\n⚙️  Backend Security Validation")
    print("-" * 30)
    
    issues = []
    
    # Check if secure app is deployed
    if os.path.exists("backend/app.py"):
        with open("backend/app.py", 'r', encoding='utf-8') as f:
            content = f.read()
            
        security_features = {
            "CSRF Protection": "csrf" in content.lower() or "CSRFProtect" in content or "WTF_CSRF" in content,
            "Rate Limiting": "limiter" in content.lower() or "RateLimiter" in content or "Flask-Limiter" in content,
            "Input Validation": "marshmallow" in content.lower() or "ValidationSchema" in content or "validate_json" in content,
            "Security Headers": "security_headers" in content.lower() or "SecurityMiddleware" in content,
            "Session Security": "SESSION_COOKIE" in content or "session_cookie" in content.lower()
        }
        
        for feature, present in security_features.items():
            if present:
                print(f"✅ {feature}")
            else:
                issues.append(f"Missing {feature}")
                print(f"❌ {feature}")
    else:
        issues.append("Backend app.py not found")
        print("❌ Backend app.py not found")
    
    # Check security enhancements file
    if os.path.exists("backend/security_enhancements.py"):
        print("✅ Security enhancements framework present")
    else:
        issues.append("Security enhancements framework missing")
        print("❌ Security enhancements framework missing")
    
    return len(issues) == 0

def validate_environment_config():
    """Validate environment configuration"""
    print(f"\n🔧 Environment Configuration Validation")
    print("-" * 40)
    
    issues = []
    
    if os.path.exists("security_config.env"):
        with open("security_config.env", 'r', encoding='utf-8') as f:
            content = f.read()
            
        required_configs = [
            "SECRET_KEY",
            "JWT_SECRET_KEY",
            "FLASK_ENV",
            "SESSION_COOKIE_SECURE", 
            "SECURITY_HEADERS_ENABLED"
        ]
        
        for config in required_configs:
            if config in content:
                print(f"✅ {config}")
            else:
                issues.append(f"Missing {config}")
                print(f"❌ {config}")
    else:
        issues.append("security_config.env not found")
        print("❌ security_config.env not found")
    
    # Check logs directory
    if os.path.exists("logs"):
        print("✅ Logs directory present")
    else:
        issues.append("Logs directory missing")
        print("❌ Logs directory missing")
    
    return len(issues) == 0

def generate_security_report():
    """Generate security validation report"""
    print(f"\n📋 Security Validation Report")
    print("=" * 50)
    
    # Run all validations
    files_valid = validate_security_files()
    html_valid = validate_html_security() 
    backend_valid = validate_backend_security()
    config_valid = validate_environment_config()
    
    # Calculate overall score
    validations = [files_valid, html_valid, backend_valid, config_valid]
    passed_validations = sum(validations)
    total_validations = len(validations)
    score = (passed_validations / total_validations) * 100
    
    # Determine grade
    if score >= 95:
        grade = "A+"
    elif score >= 90:
        grade = "A"
    elif score >= 80:
        grade = "B+"
    elif score >= 70:
        grade = "B"
    elif score >= 60:
        grade = "C"
    else:
        grade = "F"
    
    print(f"\n🎯 Overall Security Status:")
    print(f"   Score: {score:.1f}%")
    print(f"   Grade: {grade}")
    print(f"   Validations Passed: {passed_validations}/{total_validations}")
    
    # Recommendations
    print(f"\n💡 Recommendations:")
    if not files_valid:
        print("   - Ensure all security files are present and properly deployed")
    if not html_valid:
        print("   - Update HTML files with secure CSP (remove unsafe-inline)")
    if not backend_valid:
        print("   - Deploy secure backend with CSRF, rate limiting, and validation")
    if not config_valid:
        print("   - Configure environment variables and create logs directory")
    
    if score >= 80:
        print("   🎉 Security deployment is successful!")
        print("   - Consider setting up SSL/TLS certificates")
        print("   - Configure automated security monitoring")
        print("   - Schedule regular security testing")
    else:
        print("   ⚠️  Critical security issues need immediate attention")
    
    # Save report
    report_data = {
        "timestamp": datetime.now().isoformat(),
        "score": score,
        "grade": grade,
        "validations": {
            "security_files": files_valid,
            "html_security": html_valid,
            "backend_security": backend_valid,
            "environment_config": config_valid
        }
    }
    
    with open("security_validation_report.json", "w") as f:
        json.dump(report_data, f, indent=2)
    
    print(f"\n📄 Report saved to: security_validation_report.json")
    
    return score >= 70

def main():
    """Main validation function"""
    try:
        success = generate_security_report()
        if success:
            print(f"\n✅ Security validation completed successfully!")
            return 0
        else:
            print(f"\n❌ Security validation failed - critical issues found")
            return 1
    except Exception as e:
        print(f"\n💥 Security validation error: {str(e)}")
        return 1

if __name__ == "__main__":
    sys.exit(main())
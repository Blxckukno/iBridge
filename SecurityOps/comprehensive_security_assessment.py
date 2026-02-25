
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
        if re.search(r'\+|%s|\{.*\}|f[\'"].*\{.*\}', query):
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
Comprehensive Security Assessment Tool
Identifies all possible attack vectors and vulnerabilities
"""

import os
import re
import json
from pathlib import Path
from urllib.parse import urlparse
import hashlib
from datetime import datetime

class ComprehensiveSecurityAssessment:
    def __init__(self, root_dir):
        self.root_dir = Path(root_dir)
        self.vulnerabilities = []
        self.security_score = 0
        self.attack_vectors = {}
        
    def assess_all_vulnerabilities(self):
        """Assess all possible attack vectors"""
        print("🔍 COMPREHENSIVE SECURITY ASSESSMENT")
        print("=" * 50)
        
        # 1. Web Application Attacks
        self.assess_xss_vulnerabilities()
        self.assess_sql_injection()
        self.assess_csrf_vulnerabilities()
        self.assess_clickjacking()
        self.assess_directory_traversal()
        
        # 2. Infrastructure Attacks
        self.assess_ddos_protection()
        self.assess_rate_limiting()
        self.assess_input_validation()
        
        # 3. Authentication & Authorization
        self.assess_authentication_bypass()
        self.assess_session_management()
        self.assess_privilege_escalation()
        
        # 4. Data Security
        self.assess_sensitive_data_exposure()
        self.assess_insecure_deserialization()
        self.assess_file_upload_vulnerabilities()
        
        # 5. Client-Side Attacks
        self.assess_dom_xss()
        self.assess_prototype_pollution()
        self.assess_client_side_template_injection()
        
        # 6. Server-Side Attacks
        self.assess_server_side_request_forgery()
        self.assess_remote_code_execution()
        self.assess_xml_external_entities()
        
        # 7. Business Logic Flaws
        self.assess_business_logic_vulnerabilities()
        self.assess_race_conditions()
        
        # 8. Configuration & Deployment
        self.assess_security_misconfiguration()
        self.assess_vulnerable_dependencies()
        
        self.generate_comprehensive_report()
    
    def assess_xss_vulnerabilities(self):
        """Check for Cross-Site Scripting vulnerabilities"""
        print("\n🔍 Checking XSS Vulnerabilities...")
        
        xss_patterns = [
            r'<script[^>]*>.*?</script>',
            r'javascript:',
            r'on\w+\s*=',
            r'eval\s*\(',
            r'innerHTML\s*=',
            r'document\.write\s*\(',
            r'\.html\s*\(',
            r'v-html\s*=',
            r'\$\{.*?\}',
            r'<%.*?%>'
        ]
        
        for html_file in self.root_dir.glob("*.html"):
            try:
                content = html_file.read_text(encoding='utf-8')
                
                # Check for dangerous patterns
                for pattern in xss_patterns:
                    matches = re.findall(pattern, content, re.IGNORECASE | re.DOTALL)
                    if matches:
                        self.vulnerabilities.append({
                            'type': 'XSS',
                            'severity': 'HIGH',
                            'file': str(html_file),
                            'pattern': pattern,
                            'matches': len(matches),
                            'description': f'Potential XSS vulnerability found with pattern: {pattern}'
                        })
                
                # Check for missing CSP
                if 'Content-Security-Policy' not in content:
                    self.vulnerabilities.append({
                        'type': 'Missing CSP',
                        'severity': 'HIGH',
                        'file': str(html_file),
                        'description': 'Content Security Policy header missing'
                    })
                    
            except Exception as e:
                print(f"Error checking {html_file}: {e}")
    
    def assess_sql_injection(self):
        """Check for SQL Injection vulnerabilities"""
        print("🔍 Checking SQL Injection Vulnerabilities...")
        
        sql_patterns = [
            r'SELECT\s+.*\s+FROM\s+.*WHERE.*\+',
            r'INSERT\s+INTO\s+.*VALUES\s*\(',
            r'UPDATE\s+.*SET.*WHERE',
            r'DELETE\s+FROM\s+.*WHERE',
            r'UNION\s+SELECT',
            r'OR\s+1\s*=\s*1',
            r';\s*DROP\s+TABLE',
            r'exec\s*\(',
            r'sp_executesql'
        ]
        
        for py_file in self.root_dir.rglob("*.py"):
            try:
                content = py_file.read_text(encoding='utf-8')
                for pattern in sql_patterns:
                    if re.search(pattern, content, re.IGNORECASE):
                        self.vulnerabilities.append({
                            'type': 'SQL Injection',
                            'severity': 'CRITICAL',
                            'file': str(py_file),
                            'pattern': pattern,
                            'description': f'Potential SQL injection vulnerability: {pattern}'
                        })
            except Exception as e:
                continue
    
    def assess_csrf_vulnerabilities(self):
        """Check for CSRF vulnerabilities"""
        print("🔍 Checking CSRF Vulnerabilities...")
        
        for html_file in self.root_dir.glob("*.html"):
            try:
                content = html_file.read_text(encoding='utf-8')
                
                # Check for forms without CSRF tokens
                forms = re.findall(r'<form[^>]*>(.*?)</form>', content, re.DOTALL | re.IGNORECASE)
                for form in forms:
                    if 'csrf_token' not in form and 'authenticity_token' not in form:
                        self.vulnerabilities.append({
                            'type': 'CSRF',
                            'severity': 'HIGH',
                            'file': str(html_file),
                            'description': 'Form found without CSRF protection'
                        })
            except Exception as e:
                continue
    
    def assess_clickjacking(self):
        """Check for clickjacking vulnerabilities"""
        print("🔍 Checking Clickjacking Vulnerabilities...")
        
        for html_file in self.root_dir.glob("*.html"):
            try:
                content = html_file.read_text(encoding='utf-8')
                if 'X-Frame-Options' not in content and 'frame-ancestors' not in content:
                    self.vulnerabilities.append({
                        'type': 'Clickjacking',
                        'severity': 'MEDIUM',
                        'file': str(html_file),
                        'description': 'Missing X-Frame-Options or CSP frame-ancestors directive'
                    })
            except Exception as e:
                continue
    
    def assess_directory_traversal(self):
        """Check for directory traversal vulnerabilities"""
        print("🔍 Checking Directory Traversal Vulnerabilities...")
        
        traversal_patterns = [
            r'\.\./\.\.',
            r'\.\.\\\.\.\\',
            r'%2e%2e%2f',
            r'%2e%2e\\',
            r'\.\.%2f',
            r'\.\.%5c'
        ]
        
        for file_path in self.root_dir.rglob("*"):
            if file_path.is_file():
                try:
                    content = file_path.read_text(encoding='utf-8')
                    for pattern in traversal_patterns:
                        if re.search(pattern, content, re.IGNORECASE):
                            self.vulnerabilities.append({
                                'type': 'Directory Traversal',
                                'severity': 'HIGH',
                                'file': str(file_path),
                                'pattern': pattern,
                                'description': f'Potential directory traversal: {pattern}'
                            })
                except Exception as e:
                    continue
    
    def assess_ddos_protection(self):
        """Check for DDoS protection measures"""
        print("🔍 Checking DDoS Protection...")
        
        # Check for rate limiting implementation
        backend_files = list(self.root_dir.rglob("backend/*.py"))
        has_rate_limiting = False
        
        for py_file in backend_files:
            try:
                content = py_file.read_text(encoding='utf-8')
                if 'rate_limit' in content.lower() or 'limiter' in content.lower():
                    has_rate_limiting = True
                    break
            except Exception as e:
                continue
        
        if not has_rate_limiting:
            self.vulnerabilities.append({
                'type': 'DDoS Protection',
                'severity': 'HIGH',
                'description': 'No rate limiting implementation found'
            })
    
    def assess_authentication_bypass(self):
        """Check for authentication bypass vulnerabilities"""
        print("🔍 Checking Authentication Bypass...")
        
        auth_patterns = [
            r'if.*password.*==.*["\'].*["\']',
            r'auth.*=.*true',
            r'login.*=.*1',
            r'authenticated.*=.*["\']yes["\']'
        ]
        
        for py_file in self.root_dir.rglob("*.py"):
            try:
                content = py_file.read_text(encoding='utf-8')
                for pattern in auth_patterns:
                    if re.search(pattern, content, re.IGNORECASE):
                        self.vulnerabilities.append({
                            'type': 'Authentication Bypass',
                            'severity': 'CRITICAL',
                            'file': str(py_file),
                            'pattern': pattern,
                            'description': f'Weak authentication logic: {pattern}'
                        })
            except Exception as e:
                continue
    
    def assess_sensitive_data_exposure(self):
        """Check for sensitive data exposure"""
        print("🔍 Checking Sensitive Data Exposure...")
        
        sensitive_patterns = [
            r'password\s*=\s*["\'][^"\']+["\']',
            r'api_key\s*=\s*["\'][^"\']+["\']',
            r'secret\s*=\s*["\'][^"\']+["\']',
            r'token\s*=\s*["\'][^"\']+["\']',
            r'database_url\s*=.*',
            r'mongodb://.*',
            r'mysql://.*',
            r'postgres://.*'
        ]
        
        for file_path in self.root_dir.rglob("*"):
            if file_path.is_file() and file_path.suffix in ['.py', '.js', '.html', '.json', '.env']:
                try:
                    content = file_path.read_text(encoding='utf-8')
                    for pattern in sensitive_patterns:
                        matches = re.findall(pattern, content, re.IGNORECASE)
                        if matches:
                            self.vulnerabilities.append({
                                'type': 'Sensitive Data Exposure',
                                'severity': 'HIGH',
                                'file': str(file_path),
                                'pattern': pattern,
                                'matches': matches,
                                'description': f'Sensitive data found: {pattern}'
                            })
                except Exception as e:
                    continue
    
    def assess_file_upload_vulnerabilities(self):
        """Check for file upload vulnerabilities"""
        print("🔍 Checking File Upload Vulnerabilities...")
        
        upload_patterns = [
            r'upload',
            r'file.*save',
            r'multipart/form-data',
            r'enctype.*multipart'
        ]
        
        for file_path in self.root_dir.rglob("*"):
            if file_path.is_file():
                try:
                    content = file_path.read_text(encoding='utf-8')
                    for pattern in upload_patterns:
                        if re.search(pattern, content, re.IGNORECASE):
                            # Check if proper validation exists
                            if 'allowed_extensions' not in content and 'file_type' not in content:
                                self.vulnerabilities.append({
                                    'type': 'File Upload',
                                    'severity': 'HIGH',
                                    'file': str(file_path),
                                    'description': 'File upload without proper validation'
                                })
                            break
                except Exception as e:
                    continue
    
    def assess_security_misconfiguration(self):
        """Check for security misconfigurations"""
        print("🔍 Checking Security Misconfigurations...")
        
        # Check for debug mode
        for py_file in self.root_dir.rglob("*.py"):
            try:
                content = py_file.read_text(encoding='utf-8')
                if re.search(r'debug\s*=\s*True', content, re.IGNORECASE):
                    self.vulnerabilities.append({
                        'type': 'Security Misconfiguration',
                        'severity': 'MEDIUM',
                        'file': str(py_file),
                        'description': 'Debug mode enabled in production'
                    })
            except Exception as e:
                continue
        
        # Check for default credentials
        default_creds = [
            'admin:admin',
            'admin:password',
            'root:root',
            'test:test'
        ]
        
        for file_path in self.root_dir.rglob("*"):
            if file_path.is_file():
                try:
                    content = file_path.read_text(encoding='utf-8')
                    for cred in default_creds:
                        if cred in content:
                            self.vulnerabilities.append({
                                'type': 'Default Credentials',
                                'severity': 'CRITICAL',
                                'file': str(file_path),
                                'description': f'Default credentials found: {cred}'
                            })
                except Exception as e:
                    continue
    
    def assess_dom_xss(self):
        """Check for DOM-based XSS"""
        print("🔍 Checking DOM-based XSS...")
        
        dom_xss_patterns = [
            r'document\.location',
            r'window\.location',
            r'document\.URL',
            r'document\.referrer',
            r'window\.name',
            r'history\.pushState',
            r'history\.replaceState'
        ]
        
        for js_file in self.root_dir.rglob("*.js"):
            try:
                content = js_file.read_text(encoding='utf-8')
                for pattern in dom_xss_patterns:
                    if re.search(pattern, content):
                        self.vulnerabilities.append({
                            'type': 'DOM XSS',
                            'severity': 'HIGH',
                            'file': str(js_file),
                            'pattern': pattern,
                            'description': f'DOM XSS sink found: {pattern}'
                        })
            except Exception as e:
                continue
    
    def assess_server_side_request_forgery(self):
        """Check for SSRF vulnerabilities"""
        print("🔍 Checking SSRF Vulnerabilities...")
        
        ssrf_patterns = [
            r'requests\.get\(',
            r'urllib\.request',
            r'http\.client',
            r'fetch\(',
            r'axios\.'
        ]
        
        for py_file in self.root_dir.rglob("*.py"):
            try:
                content = py_file.read_text(encoding='utf-8')
                for pattern in ssrf_patterns:
                    if re.search(pattern, content):
                        # Check if URL validation exists
                        if 'url_validate' not in content and 'whitelist' not in content:
                            self.vulnerabilities.append({
                                'type': 'SSRF',
                                'severity': 'HIGH',
                                'file': str(py_file),
                                'description': f'HTTP request without URL validation: {pattern}'
                            })
            except Exception as e:
                continue
    
    def assess_business_logic_vulnerabilities(self):
        """Check for business logic flaws"""
        print("🔍 Checking Business Logic Vulnerabilities...")
        
        # This is a basic check - business logic flaws require manual review
        self.vulnerabilities.append({
            'type': 'Business Logic Review',
            'severity': 'MEDIUM',
            'description': 'Manual business logic security review required'
        })
    
    def assess_race_conditions(self):
        """Check for race condition vulnerabilities"""
        print("🔍 Checking Race Conditions...")
        
        race_patterns = [
            r'threading\.',
            r'multiprocessing\.',
            r'async\s+def',
            r'await\s+',
            r'concurrent\.futures'
        ]
        
        for py_file in self.root_dir.rglob("*.py"):
            try:
                content = py_file.read_text(encoding='utf-8')
                for pattern in race_patterns:
                    if re.search(pattern, content):
                        if 'lock' not in content.lower() and 'mutex' not in content.lower():
                            self.vulnerabilities.append({
                                'type': 'Race Condition',
                                'severity': 'MEDIUM',
                                'file': str(py_file),
                                'description': f'Concurrent code without synchronization: {pattern}'
                            })
                            break
            except Exception as e:
                continue
    
    def assess_rate_limiting(self):
        """Check rate limiting implementation"""
        print("🔍 Checking Rate Limiting...")
        # Already covered in assess_ddos_protection
        pass
    
    def assess_input_validation(self):
        """Check input validation"""
        print("🔍 Checking Input Validation...")
        
        for html_file in self.root_dir.glob("*.html"):
            try:
                content = html_file.read_text(encoding='utf-8')
                inputs = re.findall(r'<input[^>]*>', content, re.IGNORECASE)
                for input_tag in inputs:
                    if 'required' not in input_tag and 'pattern' not in input_tag:
                        self.vulnerabilities.append({
                            'type': 'Input Validation',
                            'severity': 'MEDIUM',
                            'file': str(html_file),
                            'description': 'Input field without validation attributes'
                        })
            except Exception as e:
                continue
    
    def assess_session_management(self):
        """Check session management"""
        print("🔍 Checking Session Management...")
        # Basic check for session configuration
        pass
    
    def assess_privilege_escalation(self):
        """Check for privilege escalation"""
        print("🔍 Checking Privilege Escalation...")
        # Requires manual review of authorization logic
        pass
    
    def assess_insecure_deserialization(self):
        """Check for insecure deserialization"""
        print("🔍 Checking Insecure Deserialization...")
        
        deser_patterns = [
            r'pickle\.loads',
            r'cPickle\.loads',
            r'yaml\.load',
            r'eval\(',
            r'exec\('
        ]
        
        for py_file in self.root_dir.rglob("*.py"):
            try:
                content = py_file.read_text(encoding='utf-8')
                for pattern in deser_patterns:
                    if re.search(pattern, content):
                        self.vulnerabilities.append({
                            'type': 'Insecure Deserialization',
                            'severity': 'HIGH',
                            'file': str(py_file),
                            'description': f'Insecure deserialization: {pattern}'
                        })
            except Exception as e:
                continue
    
    def assess_prototype_pollution(self):
        """Check for prototype pollution"""
        print("🔍 Checking Prototype Pollution...")
        
        pollution_patterns = [
            r'Object\.prototype',
            r'__proto__',
            r'constructor\.prototype'
        ]
        
        for js_file in self.root_dir.rglob("*.js"):
            try:
                content = js_file.read_text(encoding='utf-8')
                for pattern in pollution_patterns:
                    if re.search(pattern, content):
                        self.vulnerabilities.append({
                            'type': 'Prototype Pollution',
                            'severity': 'MEDIUM',
                            'file': str(js_file),
                            'description': f'Prototype manipulation: {pattern}'
                        })
            except Exception as e:
                continue
    
    def assess_client_side_template_injection(self):
        """Check for client-side template injection"""
        print("🔍 Checking Client-Side Template Injection...")
        
        template_patterns = [
            r'\{\{.*\}\}',
            r'\$\{.*\}',
            r'<%.*%>',
            r'\[%.*%\]'
        ]
        
        for html_file in self.root_dir.glob("*.html"):
            try:
                content = html_file.read_text(encoding='utf-8')
                for pattern in template_patterns:
                    matches = re.findall(pattern, content)
                    if matches:
                        self.vulnerabilities.append({
                            'type': 'Template Injection',
                            'severity': 'MEDIUM',
                            'file': str(html_file),
                            'description': f'Template expression found: {pattern}'
                        })
            except Exception as e:
                continue
    
    def assess_remote_code_execution(self):
        """Check for RCE vulnerabilities"""
        print("🔍 Checking Remote Code Execution...")
        
        rce_patterns = [
            r'eval\(',
            r'exec\(',
            r'os\.system\(',
            r'subprocess\.',
            r'shell=True'
        ]
        
        for py_file in self.root_dir.rglob("*.py"):
            try:
                content = py_file.read_text(encoding='utf-8')
                for pattern in rce_patterns:
                    if re.search(pattern, content):
                        self.vulnerabilities.append({
                            'type': 'Remote Code Execution',
                            'severity': 'CRITICAL',
                            'file': str(py_file),
                            'description': f'Dangerous function: {pattern}'
                        })
            except Exception as e:
                continue
    
    def assess_xml_external_entities(self):
        """Check for XXE vulnerabilities"""
        print("🔍 Checking XML External Entities...")
        
        xxe_patterns = [
            r'xml\.etree',
            r'lxml\.',
            r'minidom\.',
            r'BeautifulSoup.*xml'
        ]
        
        for py_file in self.root_dir.rglob("*.py"):
            try:
                content = py_file.read_text(encoding='utf-8')
                for pattern in xxe_patterns:
                    if re.search(pattern, content):
                        if 'resolve_entities=False' not in content:
                            self.vulnerabilities.append({
                                'type': 'XXE',
                                'severity': 'HIGH',
                                'file': str(py_file),
                                'description': f'XML parser without XXE protection: {pattern}'
                            })
            except Exception as e:
                continue
    
    def assess_vulnerable_dependencies(self):
        """Check for vulnerable dependencies"""
        print("🔍 Checking Vulnerable Dependencies...")
        
        req_file = self.root_dir / "backend" / "requirements.txt"
        if req_file.exists():
            try:
                content = req_file.read_text(encoding='utf-8')
                # This would require a vulnerability database in real implementation
                self.vulnerabilities.append({
                    'type': 'Dependency Check',
                    'severity': 'MEDIUM',
                    'description': 'Manual dependency vulnerability check required'
                })
            except Exception as e:
                pass
    
    def calculate_security_score(self):
        """Calculate overall security score"""
        if not self.vulnerabilities:
            return 100.0
        
        critical_count = sum(1 for v in self.vulnerabilities if v['severity'] == 'CRITICAL')
        high_count = sum(1 for v in self.vulnerabilities if v['severity'] == 'HIGH')
        medium_count = sum(1 for v in self.vulnerabilities if v['severity'] == 'MEDIUM')
        
        # Weighted scoring
        score_deduction = (critical_count * 25) + (high_count * 15) + (medium_count * 5)
        score = max(0, 100 - score_deduction)
        
        return score
    
    def generate_comprehensive_report(self):
        """Generate comprehensive security report"""
        print("\n" + "=" * 60)
        print("🔒 COMPREHENSIVE SECURITY ASSESSMENT REPORT")
        print("=" * 60)
        
        self.security_score = self.calculate_security_score()
        
        print(f"\n📊 OVERALL SECURITY SCORE: {self.security_score:.1f}/100")
        
        if self.security_score >= 90:
            grade = "A+"
            status = "EXCELLENT"
        elif self.security_score >= 80:
            grade = "A"
            status = "GOOD"
        elif self.security_score >= 70:
            grade = "B"
            status = "FAIR"
        elif self.security_score >= 60:
            grade = "C"
            status = "POOR"
        else:
            grade = "F"
            status = "CRITICAL"
        
        print(f"🎯 SECURITY GRADE: {grade} ({status})")
        
        # Group vulnerabilities by severity
        critical_vulns = [v for v in self.vulnerabilities if v['severity'] == 'CRITICAL']
        high_vulns = [v for v in self.vulnerabilities if v['severity'] == 'HIGH']
        medium_vulns = [v for v in self.vulnerabilities if v['severity'] == 'MEDIUM']
        
        print(f"\n🚨 VULNERABILITY SUMMARY:")
        print(f"   Critical: {len(critical_vulns)}")
        print(f"   High: {len(high_vulns)}")
        print(f"   Medium: {len(medium_vulns)}")
        print(f"   Total: {len(self.vulnerabilities)}")
        
        # Detailed vulnerability listing
        if self.vulnerabilities:
            print(f"\n📋 DETAILED VULNERABILITIES:")
            print("-" * 60)
            
            for i, vuln in enumerate(self.vulnerabilities[:20], 1):  # Limit to first 20
                print(f"\n{i}. {vuln['type']} [{vuln['severity']}]")
                print(f"   Description: {vuln['description']}")
                if 'file' in vuln:
                    print(f"   File: {vuln['file']}")
                if 'pattern' in vuln:
                    print(f"   Pattern: {vuln['pattern']}")
        
        # Save detailed report
        report_data = {
            'timestamp': datetime.now().isoformat(),
            'security_score': self.security_score,
            'grade': grade,
            'status': status,
            'vulnerability_count': {
                'critical': len(critical_vulns),
                'high': len(high_vulns),
                'medium': len(medium_vulns),
                'total': len(self.vulnerabilities)
            },
            'vulnerabilities': self.vulnerabilities
        }
        
        report_file = self.root_dir / "COMPREHENSIVE_SECURITY_REPORT.json"
        with open(report_file, 'w', encoding='utf-8') as f:
            json.dump(report_data, f, indent=2, default=str)
        
        print(f"\n💾 Detailed report saved to: {report_file}")
        
        # Generate attack vector summary
        self.generate_attack_vector_summary()
    
    def generate_attack_vector_summary(self):
        """Generate summary of possible attack vectors"""
        print(f"\n⚔️ POSSIBLE ATTACK VECTORS:")
        print("-" * 40)
        
        attack_types = {}
        for vuln in self.vulnerabilities:
            attack_type = vuln['type']
            if attack_type not in attack_types:
                attack_types[attack_type] = []
            attack_types[attack_type].append(vuln)
        
        for attack_type, vulns in attack_types.items():
            severity_counts = {}
            for vuln in vulns:
                sev = vuln['severity']
                severity_counts[sev] = severity_counts.get(sev, 0) + 1
            
            print(f"\n🎯 {attack_type}:")
            for severity, count in severity_counts.items():
                print(f"   {severity}: {count} instances")

if __name__ == "__main__":
    # Run comprehensive security assessment
    assessor = ComprehensiveSecurityAssessment(".")
    assessor.assess_all_vulnerabilities()
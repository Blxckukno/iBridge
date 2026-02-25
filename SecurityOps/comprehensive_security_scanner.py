
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
Comprehensive Security Scanner for ALL iBridge HTML Files
Checks every single HTML file for security vulnerabilities and issues
"""

import os
import glob
import re
from datetime import datetime

class ComprehensiveSecurityScanner:
    def __init__(self):
        self.security_issues = []
        self.protected_files = []
        self.vulnerable_files = []
        self.total_files_scanned = 0
        
        # Security requirements
        self.required_security_headers = {
            'X-Content-Type-Options': 'nosniff',
            'X-Frame-Options': ['DENY', 'SAMEORIGIN'],
            'X-XSS-Protection': '1; mode=block',
            'Strict-Transport-Security': 'max-age=',
            'Referrer-Policy': ['strict-origin', 'no-referrer']
        }
        
        # Dangerous patterns to detect
        self.dangerous_patterns = [
            r'eval\s*\(',  # # eval() blocked for security usage
            r'innerHTML\s*=.*\+',  # Unsafe innerHTML concatenation
            r'document\.write\s*\(',  # document.write usage
            r'setTimeout\s*\(\s*["\'].*["\']',  # setTimeout with string
            r'setInterval\s*\(\s*["\'].*["\']',  # setInterval with string
            r'<script[^>]*src=["\'][^"\']*["\'][^>]*></script>',  # External scripts without integrity
            r'javascript:',  # javascript: protocol
            r'data:text/html',  # data URLs for HTML
            r'vbscript:',  # VBScript protocol
            r'onload\s*=',  # Inline event handlers
            r'onerror\s*=',
            r'onclick\s*=',
            r'onmouseover\s*=',
        ]
        
        # CSP violations
        self.csp_violations = [
            r"script-src[^;]*'unsafe-inline'",  # unsafe-inline in script-src
            r"script-src[^;]*'unsafe-eval'",    # unsafe-eval in script-src
            r"object-src[^;]*\*",               # Wildcard in object-src
            r"default-src[^;]*\*",              # Wildcard in default-src
        ]

    def scan_all_html_files(self):
        """Scan all HTML files in the directory and subdirectories"""
        print("🔍 COMPREHENSIVE SECURITY SCAN - ALL HTML FILES")
        print("=" * 80)
        
        # Find all HTML files recursively
        html_files = []
        for root, dirs, files in os.walk('.'):
            for file in files:
                if file.endswith('.html'):
                    html_files.append(os.path.join(root, file))
        
        print(f"📁 Found {len(html_files)} HTML files to scan")
        print("-" * 80)
        
        for html_file in sorted(html_files):
            self.scan_single_file(html_file)
        
        return self.generate_comprehensive_report()

    def scan_single_file(self, file_path):
        """Scan a single HTML file for security issues"""
        self.total_files_scanned += 1
        
        try:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
        except Exception as e:
            print(f"❌ Error reading {file_path}: {str(e)}")
            return
        
        file_issues = []
        security_score = 100
        
        print(f"\n🔍 Scanning: {file_path}")
        
        # Check 1: Security Headers
        missing_headers = self.check_security_headers(content)
        if missing_headers:
            file_issues.extend(missing_headers)
            security_score -= len(missing_headers) * 10
            print(f"  ❌ Missing security headers: {len(missing_headers)}")
        else:
            print(f"  ✅ Security headers present")
        
        # Check 2: Content Security Policy
        csp_issues = self.check_csp(content)
        if csp_issues:
            file_issues.extend(csp_issues)
            security_score -= len(csp_issues) * 15
            print(f"  ❌ CSP issues: {len(csp_issues)}")
        else:
            print(f"  ✅ CSP properly configured")
        
        # Check 3: Dangerous JavaScript Patterns
        js_issues = self.check_dangerous_patterns(content, file_path)
        if js_issues:
            file_issues.extend(js_issues)
            security_score -= len(js_issues) * 20
            print(f"  ❌ Dangerous JS patterns: {len(js_issues)}")
        else:
            print(f"  ✅ No dangerous JavaScript patterns")
        
        # Check 4: External Resources
        external_issues = self.check_external_resources(content)
        if external_issues:
            file_issues.extend(external_issues)
            security_score -= len(external_issues) * 5
            print(f"  ⚠️  External resource issues: {len(external_issues)}")
        else:
            print(f"  ✅ External resources secure")
        
        # Check 5: Form Security
        form_issues = self.check_form_security(content)
        if form_issues:
            file_issues.extend(form_issues)
            security_score -= len(form_issues) * 10
            print(f"  ⚠️  Form security issues: {len(form_issues)}")
        else:
            print(f"  ✅ Forms properly secured")
        
        # Check 6: Information Disclosure
        info_issues = self.check_information_disclosure(content)
        if info_issues:
            file_issues.extend(info_issues)
            security_score -= len(info_issues) * 5
            print(f"  ⚠️  Information disclosure risks: {len(info_issues)}")
        
        # Record results
        security_score = max(0, security_score)
        
        if file_issues:
            self.vulnerable_files.append({
                'file': file_path,
                'issues': file_issues,
                'score': security_score,
                'severity': 'CRITICAL' if security_score < 50 else 'HIGH' if security_score < 70 else 'MEDIUM'
            })
            print(f"  📊 Security Score: {security_score}/100 - {self.vulnerable_files[-1]['severity']}")
        else:
            self.protected_files.append({
                'file': file_path,
                'score': security_score
            })
            print(f"  📊 Security Score: {security_score}/100 - SECURE ✅")
        
        self.security_issues.extend(file_issues)

    def check_security_headers(self, content):
        """Check for required security headers"""
        issues = []
        
        for header, expected in self.required_security_headers.items():
            header_pattern = f'<meta[^>]*http-equiv=["\']?{re.escape(header)}["\']?[^>]*>'
            
            if not re.search(header_pattern, content, re.IGNORECASE):
                issues.append(f"Missing security header: {header}")
        
        return issues

    def check_csp(self, content):
        """Check Content Security Policy configuration"""
        issues = []
        
        # Find CSP meta tag
        csp_pattern = r'<meta[^>]*http-equiv=["\']?Content-Security-Policy["\']?[^>]*content=["\']([^"\']*)["\'][^>]*>'
        csp_match = re.search(csp_pattern, content, re.IGNORECASE)
        
        if not csp_match:
            issues.append("Missing Content-Security-Policy header")
            return issues
        
        csp_content = csp_match.group(1)
        
        # Check for CSP violations
        for violation_pattern in self.csp_violations:
            if re.search(violation_pattern, csp_content, re.IGNORECASE):
                issues.append(f"CSP violation detected: {violation_pattern}")
        
        # Check for required CSP directives
        required_directives = ['default-src', 'script-src', 'style-src']
        for directive in required_directives:
            if directive not in csp_content:
                issues.append(f"Missing CSP directive: {directive}")
        
        return issues

    def check_dangerous_patterns(self, content, file_path):
        """Check for dangerous JavaScript patterns"""
        issues = []
        
        for pattern in self.dangerous_patterns:
            matches = re.findall(pattern, content, re.IGNORECASE | re.MULTILINE)
            if matches:
                issues.append(f"Dangerous pattern found: {pattern} (matches: {len(matches)})")
        
        return issues

    def check_external_resources(self, content):
        """Check external resource loading security"""
        issues = []
        
        # Check for scripts without integrity
        script_pattern = r'<script[^>]*src=["\']https?://[^"\']*["\'][^>]*>'
        scripts = re.findall(script_pattern, content, re.IGNORECASE)
        
        for script in scripts:
            if 'integrity=' not in script:
                issues.append(f"External script without integrity check: {script[:100]}...")
        
        # Check for mixed content
        if 'https://' in content and 'http://' in content:
            http_resources = re.findall(r'http://[^\s"\'<>]+', content)
            if http_resources:
                issues.append(f"Mixed content detected: {len(http_resources)} HTTP resources")
        
        return issues

    def check_form_security(self, content):
        """Check form security configurations"""
        issues = []
        
        # Find forms
        forms = re.findall(r'<form[^>]*>(.*?)</form>', content, re.DOTALL | re.IGNORECASE)
        
        for i, form in enumerate(forms):
            # Check for CSRF protection
            if 'csrf' not in form.lower() and 'token' not in form.lower():
                issues.append(f"Form {i+1} missing CSRF protection")
            
            # Check for proper method
            if re.search(r'method=["\']?get["\']?', form, re.IGNORECASE):
                if 'password' in form.lower() or 'login' in form.lower():
                    issues.append(f"Form {i+1} using GET method for sensitive data")
        
        return issues

    def check_information_disclosure(self, content):
        """Check for potential information disclosure"""
        issues = []
        
        # Check for comments with sensitive information
        comments = re.findall(r'<!--.*?-->', content, re.DOTALL)
        
        sensitive_patterns = [
            r'password', r'secret', r'key', r'token', r'api[_-]?key',
            r'database', r'connection', r'config', r'admin', r'debug'
        ]
        
        for comment in comments:
            for pattern in sensitive_patterns:
                if re.search(pattern, comment, re.IGNORECASE):
                    issues.append(f"Potentially sensitive information in comment: {pattern}")
                    break
        
        return issues

    def generate_comprehensive_report(self):
        """Generate comprehensive security report"""
        print("\n" + "=" * 80)
        print("🛡️ COMPREHENSIVE SECURITY REPORT")
        print("=" * 80)
        
        # Calculate overall statistics
        total_vulnerable = len(self.vulnerable_files)
        total_protected = len(self.protected_files)
        overall_score = ((total_protected / self.total_files_scanned) * 100) if self.total_files_scanned > 0 else 0
        
        print(f"📊 SCAN SUMMARY:")
        print(f"   Total Files Scanned: {self.total_files_scanned}")
        print(f"   Secure Files: {total_protected}")
        print(f"   Vulnerable Files: {total_vulnerable}")
        print(f"   Overall Security Score: {overall_score:.1f}%")
        
        # Security grade
        if overall_score >= 95:
            grade = "A+"
            status = "EXCELLENT"
        elif overall_score >= 90:
            grade = "A"
            status = "VERY GOOD"
        elif overall_score >= 80:
            grade = "B+"
            status = "GOOD"
        elif overall_score >= 70:
            grade = "B"
            status = "ACCEPTABLE"
        elif overall_score >= 60:
            grade = "C"
            status = "NEEDS IMPROVEMENT"
        else:
            grade = "F"
            status = "CRITICAL - IMMEDIATE ACTION REQUIRED"
        
        print(f"   Security Grade: {grade}")
        print(f"   Status: {status}")
        
        # Critical vulnerabilities
        critical_files = [f for f in self.vulnerable_files if f['severity'] == 'CRITICAL']
        high_risk_files = [f for f in self.vulnerable_files if f['severity'] == 'HIGH']
        medium_risk_files = [f for f in self.vulnerable_files if f['severity'] == 'MEDIUM']
        
        if critical_files:
            print(f"\n🚨 CRITICAL VULNERABILITIES ({len(critical_files)} files):")
            for file_info in critical_files:
                print(f"   ❌ {file_info['file']} (Score: {file_info['score']}/100)")
                for issue in file_info['issues'][:3]:  # Show top 3 issues
                    print(f"      • {issue}")
        
        if high_risk_files:
            print(f"\n⚠️ HIGH RISK VULNERABILITIES ({len(high_risk_files)} files):")
            for file_info in high_risk_files:
                print(f"   ⚠️  {file_info['file']} (Score: {file_info['score']}/100)")
        
        if medium_risk_files:
            print(f"\n📋 MEDIUM RISK ISSUES ({len(medium_risk_files)} files):")
            for file_info in medium_risk_files:
                print(f"   📋 {file_info['file']} (Score: {file_info['score']}/100)")
        
        # Secure files
        if self.protected_files:
            print(f"\n✅ SECURE FILES ({len(self.protected_files)} files):")
            for file_info in self.protected_files:
                print(f"   ✅ {file_info['file']} (Score: {file_info['score']}/100)")
        
        # Recommendations
        print(f"\n💡 SECURITY RECOMMENDATIONS:")
        if critical_files or high_risk_files:
            print("   🚨 IMMEDIATE ACTION REQUIRED:")
            print("   1. Fix all CRITICAL and HIGH risk vulnerabilities immediately")
            print("   2. Add missing security headers to all vulnerable files")
            print("   3. Update CSP policies to remove unsafe directives")
            print("   4. Remove or secure dangerous JavaScript patterns")
            print("   5. Add CSRF protection to all forms")
        
        print("   📈 IMPROVEMENT ACTIONS:")
        print("   1. Implement consistent security headers across all pages")
        print("   2. Use nonce-based CSP for all script execution")
        print("   3. Add integrity checks for external resources")
        print("   4. Regular security scanning and monitoring")
        print("   5. Security awareness training for development team")
        
        # Save detailed report
        report_data = {
            'timestamp': datetime.now().isoformat(),
            'total_files': self.total_files_scanned,
            'secure_files': len(self.protected_files),
            'vulnerable_files': len(self.vulnerable_files),
            'overall_score': overall_score,
            'grade': grade,
            'status': status,
            'critical_files': len(critical_files),
            'high_risk_files': len(high_risk_files),
            'medium_risk_files': len(medium_risk_files),
            'vulnerable_file_details': self.vulnerable_files,
            'secure_file_details': self.protected_files
        }
        
        import json
        with open('comprehensive_security_scan_report.json', 'w') as f:
            json.dump(report_data, f, indent=2)
        
        print(f"\n📄 Detailed report saved to: comprehensive_security_scan_report.json")
        print("=" * 80)
        
        return overall_score >= 80  # Return True if acceptable security level

def main():
    """Main function"""
    scanner = ComprehensiveSecurityScanner()
    success = scanner.scan_all_html_files()
    
    if success:
        print("\n✅ Security scan completed - Acceptable security level achieved")
        return 0
    else:
        print("\n❌ Security scan completed - CRITICAL ISSUES FOUND")
        return 1

if __name__ == "__main__":
    exit(main())
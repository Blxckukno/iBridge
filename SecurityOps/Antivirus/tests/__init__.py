
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
        if re.search(r'\+|%s|\{.*\}|f["'].*\{.*\}', query):
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


"""
Comprehensive Testing Framework
Unit tests, integration tests, security tests, and performance tests for the antivirus system
"""

import unittest
import sys
import os
import time
import threading
import tempfile
import shutil
import logging
import json
import subprocess
from pathlib import Path
from typing import Dict, List, Any, Optional, Callable
from datetime import datetime, timedelta

# Add project root to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

class TestFramework:
    """
    Main testing framework coordinator
    """
    
    def __init__(self):
        self.test_results = {}
        self.test_suite = unittest.TestSuite()
        self.logger = self._setup_logging()
        self.test_data_dir = Path(__file__).parent / "test_data"
        self.test_data_dir.mkdir(exist_ok=True)
        
        # Test configuration
        self.config = {
            'run_unit_tests': True,
            'run_integration_tests': True,
            'run_security_tests': True,
            'run_performance_tests': True,
            'verbose_output': True,
            'create_test_report': True,
            'test_timeout': 300,  # 5 minutes per test
            'parallel_tests': False,
            'cleanup_after_tests': True
        }
        
        # Test statistics
        self.stats = {
            'total_tests': 0,
            'passed_tests': 0,
            'failed_tests': 0,
            'skipped_tests': 0,
            'error_tests': 0,
            'start_time': None,
            'end_time': None,
            'duration': 0
        }
        
        self.logger.info("Test Framework initialized")
    
    def _setup_logging(self):
        """Setup logging for test framework"""
        logger = logging.getLogger('TestFramework')
        logger.setLevel(logging.INFO)
        
        # Create logs directory
        logs_dir = Path(__file__).parent / "logs"
        logs_dir.mkdir(exist_ok=True)
        
        # File handler
        log_file = logs_dir / f"test_run_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"
        file_handler = logging.FileHandler(log_file)
        file_handler.setLevel(logging.INFO)
        
        # Console handler
        console_handler = logging.StreamHandler()
        console_handler.setLevel(logging.INFO)
        
        # Formatter
        formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
        file_handler.setFormatter(formatter)
        console_handler.setFormatter(formatter)
        
        logger.addHandler(file_handler)
        logger.addHandler(console_handler)
        
        return logger
    
    def discover_tests(self):
        """Discover all test modules"""
        try:
            test_loader = unittest.TestLoader()
            
            # Discover unit tests
            if self.config['run_unit_tests']:
                unit_tests = test_loader.discover('unit', pattern='test_*.py')
                self.test_suite.addTest(unit_tests)
                self.logger.info("Unit tests discovered")
            
            # Discover integration tests
            if self.config['run_integration_tests']:
                integration_tests = test_loader.discover('integration', pattern='test_*.py')
                self.test_suite.addTest(integration_tests)
                self.logger.info("Integration tests discovered")
            
            # Discover security tests
            if self.config['run_security_tests']:
                security_tests = test_loader.discover('security', pattern='test_*.py')
                self.test_suite.addTest(security_tests)
                self.logger.info("Security tests discovered")
            
            # Discover performance tests
            if self.config['run_performance_tests']:
                performance_tests = test_loader.discover('performance', pattern='test_*.py')
                self.test_suite.addTest(performance_tests)
                self.logger.info("Performance tests discovered")
            
            return True
            
        except Exception as e:
            self.logger.error(f"Error discovering tests: {e}")
            return False
    
    def run_tests(self):
        """Run all discovered tests"""
        try:
            self.stats['start_time'] = datetime.now()
            self.logger.info("Starting test execution")
            
            # Setup test runner
            if self.config['verbose_output']:
                verbosity = 2
            else:
                verbosity = 1
            
            runner = unittest.TextTestRunner(
                verbosity=verbosity,
                stream=sys.stdout,
                buffer=True
            )
            
            # Run tests
            result = runner.run(self.test_suite)
            
            # Update statistics
            self.stats['end_time'] = datetime.now()
            self.stats['duration'] = (self.stats['end_time'] - self.stats['start_time']).total_seconds()
            self.stats['total_tests'] = result.testsRun
            self.stats['passed_tests'] = result.testsRun - len(result.failures) - len(result.errors) - len(result.skipped)
            self.stats['failed_tests'] = len(result.failures)
            self.stats['error_tests'] = len(result.errors)
            self.stats['skipped_tests'] = len(result.skipped)
            
            # Store detailed results
            self.test_results = {
                'summary': self.stats.copy(),
                'failures': [{'test': str(test), 'traceback': traceback} for test, traceback in result.failures],
                'errors': [{'test': str(test), 'traceback': traceback} for test, traceback in result.errors],
                'skipped': [{'test': str(test), 'reason': reason} for test, reason in result.skipped]
            }
            
            # Generate report
            if self.config['create_test_report']:
                self._generate_test_report()
            
            # Log summary
            self._log_test_summary()
            
            return result.wasSuccessful()
            
        except Exception as e:
            self.logger.error(f"Error running tests: {e}")
            return False
    
    def _generate_test_report(self):
        """Generate comprehensive test report"""
        try:
            report_dir = Path(__file__).parent / "reports"
            report_dir.mkdir(exist_ok=True)
            
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            
            # Generate HTML report
            html_report = self._generate_html_report()
            html_file = report_dir / f"test_report_{timestamp}.html"
            with open(html_file, 'w') as f:
                f.write(html_report)
            
            # Generate JSON report
            json_file = report_dir / f"test_report_{timestamp}.json"
            with open(json_file, 'w') as f:
                json.dump(self.test_results, f, indent=2, default=str)
            
            self.logger.info(f"Test reports generated: {html_file}, {json_file}")
            
        except Exception as e:
            self.logger.error(f"Error generating test report: {e}")
    
    def _generate_html_report(self):
        """Generate HTML test report"""
        success_rate = (self.stats['passed_tests'] / self.stats['total_tests'] * 100) if self.stats['total_tests'] > 0 else 0
        
        html = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>Antivirus Test Report</title>
            <style>
                body {{ font-family: Arial, sans-serif; margin: 20px; }}
                .header {{ background-color: #f4f4f4; padding: 20px; border-radius: 5px; }}
                .summary {{ display: flex; gap: 20px; margin: 20px 0; }}
                .metric {{ background-color: #e9e9e9; padding: 15px; border-radius: 5px; text-align: center; }}
                .metric h3 {{ margin: 0; color: #333; }}
                .metric .value {{ font-size: 24px; font-weight: bold; color: #007acc; }}
                .success {{ color: #28a745; }}
                .failure {{ color: #dc3545; }}
                .error {{ color: #fd7e14; }}
                .skipped {{ color: #6c757d; }}
                .details {{ margin: 20px 0; }}
                .test-list {{ background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin: 10px 0; }}
                .test-item {{ padding: 5px 0; border-bottom: 1px solid #dee2e6; }}
                .traceback {{ background-color: #f1f1f1; padding: 10px; margin: 5px 0; white-space: pre-wrap; font-family: monospace; }}
            </style>
        </head>
        <body>
            <div class="header">
                <h1>Antivirus System Test Report</h1>
                <p>Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
                <p>Duration: {self.stats['duration']:.2f} seconds</p>
                <p>Success Rate: {success_rate:.1f}%</p>
            </div>
            
            <div class="summary">
                <div class="metric">
                    <h3>Total Tests</h3>
                    <div class="value">{self.stats['total_tests']}</div>
                </div>
                <div class="metric">
                    <h3>Passed</h3>
                    <div class="value success">{self.stats['passed_tests']}</div>
                </div>
                <div class="metric">
                    <h3>Failed</h3>
                    <div class="value failure">{self.stats['failed_tests']}</div>
                </div>
                <div class="metric">
                    <h3>Errors</h3>
                    <div class="value error">{self.stats['error_tests']}</div>
                </div>
                <div class="metric">
                    <h3>Skipped</h3>
                    <div class="value skipped">{self.stats['skipped_tests']}</div>
                </div>
            </div>
        """
        
        # Add failure details
        if self.test_results.get('failures'):
            html += """
            <div class="details">
                <h2>Test Failures</h2>
                <div class="test-list">
            """
            for failure in self.test_results['failures']:
                html += f"""
                <div class="test-item">
                    <h4 class="failure">{failure['test']}</h4>
                    <div class="traceback">{failure['traceback']}</div>
                </div>
                """
            html += "</div></div>"
        
        # Add error details
        if self.test_results.get('errors'):
            html += """
            <div class="details">
                <h2>Test Errors</h2>
                <div class="test-list">
            """
            for error in self.test_results['errors']:
                html += f"""
                <div class="test-item">
                    <h4 class="error">{error['test']}</h4>
                    <div class="traceback">{error['traceback']}</div>
                </div>
                """
            html += "</div></div>"
        
        # Add skipped details
        if self.test_results.get('skipped'):
            html += """
            <div class="details">
                <h2>Skipped Tests</h2>
                <div class="test-list">
            """
            for skipped in self.test_results['skipped']:
                html += f"""
                <div class="test-item">
                    <h4 class="skipped">{skipped['test']}</h4>
                    <p>Reason: {skipped['reason']}</p>
                </div>
                """
            html += "</div></div>"
        
        html += """
        </body>
        </html>
        """
        
        return html
    
    def _log_test_summary(self):
        """Log test execution summary"""
        self.logger.info("=" * 60)
        self.logger.info("TEST EXECUTION SUMMARY")
        self.logger.info("=" * 60)
        self.logger.info(f"Total Tests: {self.stats['total_tests']}")
        self.logger.info(f"Passed: {self.stats['passed_tests']}")
        self.logger.info(f"Failed: {self.stats['failed_tests']}")
        self.logger.info(f"Errors: {self.stats['error_tests']}")
        self.logger.info(f"Skipped: {self.stats['skipped_tests']}")
        self.logger.info(f"Duration: {self.stats['duration']:.2f} seconds")
        
        if self.stats['total_tests'] > 0:
            success_rate = (self.stats['passed_tests'] / self.stats['total_tests']) * 100
            self.logger.info(f"Success Rate: {success_rate:.1f}%")
        
        self.logger.info("=" * 60)
    
    def create_test_data(self):
        """Create test data files for testing"""
        try:
            # Create sample files for testing
            test_files = [
                ("clean_file.txt", "This is a clean test file content."),
                ("large_file.txt", "Large file content.\n" * 10000),
                ("binary_file.bin", bytes([i % 256 for i in range(1000)])),
                ("empty_file.txt", ""),
            ]
            
            for filename, content in test_files:
                file_path = self.test_data_dir / filename
                
                if isinstance(content, str):
                    with open(file_path, 'w') as f:
                        f.write(content)
                else:
                    with open(file_path, 'wb') as f:
                        f.write(content)
            
            # Create malware signature samples (for testing only)
            malware_signatures = [
                "EICAR-STANDARD-ANTIVIRUS-TEST-FILE",
                "X5O!P%@AP[4\\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*",
            ]
            
            for i, signature in enumerate(malware_signatures):
                file_path = self.test_data_dir / f"test_malware_{i}.txt"
                with open(file_path, 'w') as f:
                    f.write(signature)
            
            self.logger.info("Test data created successfully")
            return True
            
        except Exception as e:
            self.logger.error(f"Error creating test data: {e}")
            return False
    
    def cleanup_test_data(self):
        """Clean up test data after testing"""
        try:
            if self.test_data_dir.exists() and self.config['cleanup_after_tests']:
                shutil.rmtree(self.test_data_dir)
                self.logger.info("Test data cleaned up")
        except Exception as e:
            self.logger.error(f"Error cleaning up test data: {e}")
    
    def run_specific_test(self, test_module: str, test_class: Optional[str] = None, test_method: Optional[str] = None):
        """Run a specific test module, class, or method"""
        try:
            if test_method and test_class:
                suite = unittest.TestSuite()
                suite.addTest(unittest.TestLoader().loadTestsFromName(f'{test_module}.{test_class}.{test_method}'))
            elif test_class:
                suite = unittest.TestLoader().loadTestsFromName(f'{test_module}.{test_class}')
            else:
                suite = unittest.TestLoader().loadTestsFromName(test_module)
            
            runner = unittest.TextTestRunner(verbosity=2)
            result = runner.run(suite)
            
            return result.wasSuccessful()
            
        except Exception as e:
            self.logger.error(f"Error running specific test: {e}")
            return False
    
    def get_test_coverage(self):
        """Get test coverage information (requires coverage.py)"""
        try:
            import coverage
            
            cov = coverage.Coverage()
            cov.start()
            
            # Run tests with coverage
            self.run_tests()
            
            cov.stop()
            cov.save()
            
            # Generate coverage report
            coverage_report = cov.report()
            return coverage_report
            
        except ImportError:
            self.logger.warning("Coverage.py not installed. Install with: pip install coverage")
            return None
        except Exception as e:
            self.logger.error(f"Error generating coverage report: {e}")
            return None

class BaseTestCase(unittest.TestCase):
    """
    Base test case with common utilities
    """
    
    @classmethod
    def setUpClass(cls):
        """Set up test class"""
        cls.test_dir = Path(tempfile.mkdtemp())
        cls.logger = logging.getLogger(cls.__name__)
    
    @classmethod
    def tearDownClass(cls):
        """Clean up test class"""
        if cls.test_dir.exists():
            shutil.rmtree(cls.test_dir)
    
    def setUp(self):
        """Set up individual test"""
        self.start_time = time.time()
    
    def tearDown(self):
        """Clean up individual test"""
        self.end_time = time.time()
        duration = self.end_time - self.start_time
        self.logger.info(f"Test {self._testMethodName} completed in {duration:.3f}s")
    
    def create_temp_file(self, content: str = "test content", suffix: str = ".txt"):
        """Create a temporary file for testing"""
        temp_file = self.test_dir / f"temp_{int(time.time() * 1000)}{suffix}"
        with open(temp_file, 'w') as f:
            f.write(content)
        return temp_file
    
    def create_temp_binary_file(self, content: bytes = b"test content", suffix: str = ".bin"):
        """Create a temporary binary file for testing"""
        temp_file = self.test_dir / f"temp_{int(time.time() * 1000)}{suffix}"
        with open(temp_file, 'wb') as f:
            f.write(content)
        return temp_file
    
    def assert_file_exists(self, file_path):
        """Assert that a file exists"""
        self.assertTrue(os.path.exists(file_path), f"File does not exist: {file_path}")
    
    def assert_file_not_exists(self, file_path):
        """Assert that a file does not exist"""
        self.assertFalse(os.path.exists(file_path), f"File should not exist: {file_path}")
    
    def assert_file_contains(self, file_path, content):
        """Assert that a file contains specific content"""
        with open(file_path, 'r') as f:
            file_content = f.read()
        self.assertIn(content, file_content, f"File {file_path} does not contain expected content")
    
    def assert_process_running(self, process_name):
        """Assert that a process is running"""
        try:
            import psutil
            for proc in psutil.process_iter(['name']):
                if proc.info['name'] == process_name:
                    return True
            self.fail(f"Process {process_name} is not running")
        except ImportError:
            self.skipTest("psutil not available for process checking")
    
    def measure_execution_time(self, func: Callable, *args, **kwargs):
        """Measure execution time of a function"""
        start_time = time.time()
        result = func(*args, **kwargs)
        end_time = time.time()
        return result, end_time - start_time
    
    def assert_execution_time_under(self, func: Callable, max_time: float, *args, **kwargs):
        """Assert that function execution time is under a maximum"""
        result, execution_time = self.measure_execution_time(func, *args, **kwargs)
        self.assertLess(execution_time, max_time, 
                       f"Execution time {execution_time:.3f}s exceeds maximum {max_time}s")
        return result

def main():
    """Main test runner function"""
    framework = TestFramework()
    
    print("Antivirus Testing Framework")
    print("=" * 50)
    
    # Create test data
    if not framework.create_test_data():
        print("Failed to create test data")
        return False
    
    # Discover tests
    if not framework.discover_tests():
        print("Failed to discover tests")
        return False
    
    # Run tests
    success = framework.run_tests()
    
    # Cleanup
    framework.cleanup_test_data()
    
    return success

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
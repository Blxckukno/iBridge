
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
        if re.search(r'\+|%s|\{.*?\}|f["\'].*?\{.*?\}', query):
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
Database Optimization Script
Comprehensive database optimization for iBridge platform
"""

import sqlite3
import os
import time
import logging
from datetime import datetime, timedelta
from typing import List, Dict, Any

class DatabaseOptimizer:
    def __init__(self, db_path: str = "instance/ibridge.db"):
        self.db_path = db_path
        self.backup_dir = "backups"
        self.setup_logging()
        
    def setup_logging(self):
        """Setup logging for database operations"""
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler('db_optimization.log'),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)

    def create_backup(self) -> str:
        """Create database backup before optimization"""
        if not os.path.exists(self.backup_dir):
            os.makedirs(self.backup_dir)
            
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_path = f"{self.backup_dir}/ibridge_backup_{timestamp}.db"
        
        try:
            # Create backup using sqlite3 backup
            source = sqlite3.connect(self.db_path)
            backup = sqlite3.connect(backup_path)
            
            with backup:
                source.backup(backup)
            
            source.close()
            backup.close()
            
            self.logger.info(f"✅ Database backup created: {backup_path}")
            return backup_path
            
        except Exception as e:
            self.logger.error(f"❌ Backup creation failed: {e}")
            raise

    def analyze_database(self) -> Dict[str, Any]:
        """Analyze database structure and performance"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        analysis = {
            'tables': {},
            'indexes': [],
            'total_size': 0,
            'page_count': 0,
            'page_size': 0,
            'fragmentation': 0
        }
        
        try:
            # Get database size information
            cursor.execute("PRAGMA page_count")
            analysis['page_count'] = cursor.fetchone()[0]
            
            cursor.execute("PRAGMA page_size")
            analysis['page_size'] = cursor.fetchone()[0]
            
            analysis['total_size'] = analysis['page_count'] * analysis['page_size']
            
            # Get fragmentation info
            cursor.execute("PRAGMA freelist_count")
            freelist_count = cursor.fetchone()[0]
            if analysis['page_count'] > 0:
                analysis['fragmentation'] = (freelist_count / analysis['page_count']) * 100
            
            # Get table information
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
            tables = cursor.fetchall()
            
            for table in tables:
                table_name = table[0]
                if table_name.startswith('sqlite_'):
                    continue
                    
                # Get table stats
                secure_query(query, params)
                row_count = cursor.fetchone()[0]
                
                secure_query(query, params)
                columns = cursor.fetchall()
                
                analysis['tables'][table_name] = {
                    'row_count': row_count,
                    'column_count': len(columns),
                    'columns': [col[1] for col in columns]
                }
            
            # Get existing indexes
            cursor.execute("""
                SELECT name, tbl_name, sql 
                FROM sqlite_master 
                WHERE type='index' AND name NOT LIKE 'sqlite_%'
            """)
            indexes = cursor.fetchall()
            
            for index in indexes:
                analysis['indexes'].append({
                    'name': index[0],
                    'table': index[1],
                    'sql': index[2]
                })
            
            self.logger.info(f"📊 Database Analysis Complete:")
            self.logger.info(f"  - Total Size: {analysis['total_size'] / 1024 / 1024:.2f} MB")
            self.logger.info(f"  - Tables: {len(analysis['tables'])}")
            self.logger.info(f"  - Indexes: {len(analysis['indexes'])}")
            self.logger.info(f"  - Fragmentation: {analysis['fragmentation']:.2f}%")
            
            return analysis
            
        except Exception as e:
            self.logger.error(f"❌ Database analysis failed: {e}")
            raise
        finally:
            conn.close()

    def create_indexes(self) -> List[str]:
        """Create optimized indexes for better query performance"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Define indexes for optimal performance
        indexes = [
            # User table indexes
            "CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)",
            "CREATE INDEX IF NOT EXISTS idx_users_active ON users(active)",
            "CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at)",
            
            # Ticket table indexes
            "CREATE INDEX IF NOT EXISTS idx_tickets_user_id ON tickets(user_id)",
            "CREATE INDEX IF NOT EXISTS idx_tickets_status ON tickets(status)",
            "CREATE INDEX IF NOT EXISTS idx_tickets_priority ON tickets(priority)",
            "CREATE INDEX IF NOT EXISTS idx_tickets_category ON tickets(category)",
            "CREATE INDEX IF NOT EXISTS idx_tickets_created_at ON tickets(created_at)",
            "CREATE INDEX IF NOT EXISTS idx_tickets_updated_at ON tickets(updated_at)",
            
            # LMS indexes
            "CREATE INDEX IF NOT EXISTS idx_lms_users_email ON lms_users(email)",
            "CREATE INDEX IF NOT EXISTS idx_lms_enrollments_user ON lms_enrollments(user_id)",
            "CREATE INDEX IF NOT EXISTS idx_lms_enrollments_course ON lms_enrollments(course_id)",
            "CREATE INDEX IF NOT EXISTS idx_lms_progress_user_course ON lms_progress(user_id, course_id)",
            
            # Composite indexes for common queries
            "CREATE INDEX IF NOT EXISTS idx_tickets_user_status ON tickets(user_id, status)",
            "CREATE INDEX IF NOT EXISTS idx_tickets_status_priority ON tickets(status, priority)",
            "CREATE INDEX IF NOT EXISTS idx_users_email_active ON users(email, active)",
        ]
        
        created_indexes = []
        
        try:
            for index_sql in indexes:
                try:
                    cursor.execute(index_sql)
                    index_name = index_sql.split('idx_')[1].split(' ')[0]
                    created_indexes.append(f"idx_{index_name}")
                    self.logger.info(f"✅ Created index: idx_{index_name}")
                except sqlite3.OperationalError as e:
                    if "already exists" in str(e):
                        continue
                    else:
                        self.logger.warning(f"⚠️ Index creation warning: {e}")
            
            conn.commit()
            self.logger.info(f"📈 Index optimization complete: {len(created_indexes)} indexes processed")
            
            return created_indexes
            
        except Exception as e:
            self.logger.error(f"❌ Index creation failed: {e}")
            conn.rollback()
            raise
        finally:
            conn.close()

    def vacuum_database(self) -> Dict[str, Any]:
        """Perform VACUUM operation to optimize database file"""
        conn = sqlite3.connect(self.db_path)
        
        # Get size before vacuum
        size_before = os.path.getsize(self.db_path)
        
        try:
            self.logger.info("🔧 Starting database VACUUM operation...")
            start_time = time.time()
            
            # Perform VACUUM
            conn.execute("VACUUM")
            
            end_time = time.time()
            size_after = os.path.getsize(self.db_path)
            
            result = {
                'size_before': size_before,
                'size_after': size_after,
                'space_saved': size_before - size_after,
                'percentage_saved': ((size_before - size_after) / size_before) * 100 if size_before > 0 else 0,
                'duration': end_time - start_time
            }
            
            self.logger.info(f"✅ VACUUM complete:")
            self.logger.info(f"  - Size before: {size_before / 1024 / 1024:.2f} MB")
            self.logger.info(f"  - Size after: {size_after / 1024 / 1024:.2f} MB")
            self.logger.info(f"  - Space saved: {result['space_saved'] / 1024 / 1024:.2f} MB ({result['percentage_saved']:.1f}%)")
            self.logger.info(f"  - Duration: {result['duration']:.2f} seconds")
            
            return result
            
        except Exception as e:
            self.logger.error(f"❌ VACUUM operation failed: {e}")
            raise
        finally:
            conn.close()

    def update_statistics(self):
        """Update database statistics for query optimizer"""
        conn = sqlite3.connect(self.db_path)
        
        try:
            self.logger.info("📊 Updating database statistics...")
            
            # Update statistics for all tables
            conn.execute("ANALYZE")
            
            self.logger.info("✅ Database statistics updated")
            
        except Exception as e:
            self.logger.error(f"❌ Statistics update failed: {e}")
            raise
        finally:
            conn.close()

    def optimize_queries(self) -> List[str]:
        """Analyze and suggest query optimizations"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        suggestions = []
        
        try:
            # Check for missing indexes on foreign keys
            cursor.execute("""
                SELECT DISTINCT m.name as table_name, p.from_col as column_name
                FROM sqlite_master m
                JOIN pragma_foreign_key_list(m.name) p
                WHERE m.type = 'table'
            """)
            
            foreign_keys = cursor.fetchall()
            
            for table_name, column_name in foreign_keys:
                # Check if index exists
                secure_query(query, params)
                indexes = cursor.fetchall()
                
                has_index = False
                for index in indexes:
                    secure_query(query, params)
                    index_columns = cursor.fetchall()
                    if any(col[2] == column_name for col in index_columns):
                        has_index = True
                        break
                
                if not has_index:
                    suggestion = f"Consider adding index on {table_name}.{column_name} (foreign key)"
                    suggestions.append(suggestion)
                    self.logger.warning(f"⚠️ {suggestion}")
            
            # Check for tables with many rows but no indexes
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
            tables = cursor.fetchall()
            
            for table in tables:
                table_name = table[0]
                if table_name.startswith('sqlite_'):
                    continue
                
                secure_query(query, params)
                row_count = cursor.fetchone()[0]
                
                if row_count > 1000:  # Tables with more than 1000 rows
                    secure_query(query, params)
                    indexes = cursor.fetchall()
                    
                    if len(indexes) == 0:
                        suggestion = f"Large table {table_name} ({row_count} rows) has no indexes"
                        suggestions.append(suggestion)
                        self.logger.warning(f"⚠️ {suggestion}")
            
            if not suggestions:
                self.logger.info("✅ No optimization suggestions found")
            
            return suggestions
            
        except Exception as e:
            self.logger.error(f"❌ Query optimization analysis failed: {e}")
            raise
        finally:
            conn.close()

    def cleanup_old_data(self, days_to_keep: int = 90) -> Dict[str, int]:
        """Clean up old data to improve performance"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cutoff_date = datetime.now() - timedelta(days=days_to_keep)
        cleanup_results = {}
        
        try:
            self.logger.info(f"🧹 Cleaning up data older than {days_to_keep} days...")
            
            # Clean up old logs (if log table exists)
            try:
                cursor.execute("""
                    DELETE FROM logs 
                    WHERE created_at < ?
                """, (cutoff_date,))
                cleanup_results['logs'] = cursor.rowcount
                
            except sqlite3.OperationalError:
                # Table doesn't exist
                pass
            
            # Clean up old sessions (if sessions table exists)
            try:
                cursor.execute("""
                    DELETE FROM sessions 
                    WHERE created_at < ?
                """, (cutoff_date,))
                cleanup_results['sessions'] = cursor.rowcount
                
            except sqlite3.OperationalError:
                # Table doesn't exist
                pass
            
            # Clean up completed tickets older than specified period
            try:
                cursor.execute("""
                    DELETE FROM tickets 
                    WHERE status = 'closed' AND updated_at < ?
                """, (cutoff_date,))
                cleanup_results['closed_tickets'] = cursor.rowcount
                
            except sqlite3.OperationalError:
                # Table doesn't exist
                pass
            
            conn.commit()
            
            total_cleaned = sum(cleanup_results.values())
            self.logger.info(f"✅ Cleanup complete: {total_cleaned} records removed")
            
            for table, count in cleanup_results.items():
                if count > 0:
                    self.logger.info(f"  - {table}: {count} records")
            
            return cleanup_results
            
        except Exception as e:
            self.logger.error(f"❌ Data cleanup failed: {e}")
            conn.rollback()
            raise
        finally:
            conn.close()

    def check_integrity(self) -> bool:
        """Check database integrity"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        try:
            self.logger.info("🔍 Checking database integrity...")
            
            # Run integrity check
            cursor.execute("PRAGMA integrity_check")
            result = cursor.fetchone()[0]
            
            if result == "ok":
                self.logger.info("✅ Database integrity check passed")
                return True
            else:
                self.logger.error(f"❌ Database integrity check failed: {result}")
                return False
                
        except Exception as e:
            self.logger.error(f"❌ Integrity check failed: {e}")
            return False
        finally:
            conn.close()

    def optimize_configuration(self) -> Dict[str, Any]:
        """Optimize SQLite configuration for performance"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        optimizations = {}
        
        try:
            self.logger.info("⚙️ Optimizing database configuration...")
            
            # Set optimal PRAGMA settings
            settings = {
                'journal_mode': 'WAL',  # Write-Ahead Logging for better concurrency
                'synchronous': 'NORMAL',  # Balance between safety and performance
                'cache_size': -64000,  # 64MB cache
                'temp_store': 'MEMORY',  # Store temp tables in memory
                'mmap_size': 268435456,  # 256MB memory-mapped I/O
            }
            
            for pragma, value in settings.items():
                secure_query(query, params)
                secure_query(query, params)
                current_value = cursor.fetchone()[0]
                optimizations[pragma] = {
                    'set_to': value,
                    'actual': current_value
                }
                self.logger.info(f"  - {pragma}: {current_value}")
            
            conn.commit()
            self.logger.info("✅ Database configuration optimized")
            
            return optimizations
            
        except Exception as e:
            self.logger.error(f"❌ Configuration optimization failed: {e}")
            raise
        finally:
            conn.close()

    def generate_performance_report(self) -> Dict[str, Any]:
        """Generate comprehensive performance report"""
        start_time = time.time()
        
        try:
            # Run analysis
            analysis = self.analyze_database()
            suggestions = self.optimize_queries()
            
            # Get query performance stats
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # Test query performance
            query_tests = [
                ("SELECT COUNT(*) FROM users", "User count query"),
                ("SELECT COUNT(*) FROM tickets", "Ticket count query"),
                ("SELECT * FROM tickets LIMIT 10", "Recent tickets query"),
            ]
            
            query_performance = []
            
            for query, description in query_tests:
                try:
                    query_start = time.time()
                    cursor.execute(query)
                    cursor.fetchall()
                    query_end = time.time()
                    
                    query_performance.append({
                        'query': description,
                        'duration': query_end - query_start
                    })
                except Exception as e:
                    query_performance.append({
                        'query': description,
                        'error': str(e)
                    })
            
            conn.close()
            
            report = {
                'timestamp': datetime.now().isoformat(),
                'database_analysis': analysis,
                'optimization_suggestions': suggestions,
                'query_performance': query_performance,
                'report_generation_time': time.time() - start_time
            }
            
            self.logger.info(f"📋 Performance report generated in {report['report_generation_time']:.2f}s")
            
            return report
            
        except Exception as e:
            self.logger.error(f"❌ Performance report generation failed: {e}")
            raise

    def full_optimization(self, create_backup: bool = True) -> Dict[str, Any]:
        """Perform complete database optimization"""
        optimization_start = time.time()
        
        self.logger.info("🚀 Starting full database optimization...")
        
        results = {
            'backup_created': None,
            'integrity_check': False,
            'indexes_created': [],
            'vacuum_result': {},
            'cleanup_result': {},
            'configuration_optimized': {},
            'suggestions': [],
            'success': False,
            'duration': 0
        }
        
        try:
            # Step 1: Create backup
            if create_backup:
                results['backup_created'] = self.create_backup()
            
            # Step 2: Check integrity
            results['integrity_check'] = self.check_integrity()
            if not results['integrity_check']:
                raise Exception("Database integrity check failed - aborting optimization")
            
            # Step 3: Create indexes
            results['indexes_created'] = self.create_indexes()
            
            # Step 4: Update statistics
            self.update_statistics()
            
            # Step 5: Clean up old data
            results['cleanup_result'] = self.cleanup_old_data()
            
            # Step 6: Vacuum database
            results['vacuum_result'] = self.vacuum_database()
            
            # Step 7: Optimize configuration
            results['configuration_optimized'] = self.optimize_configuration()
            
            # Step 8: Get optimization suggestions
            results['suggestions'] = self.optimize_queries()
            
            results['success'] = True
            results['duration'] = time.time() - optimization_start
            
            self.logger.info(f"🎉 Full optimization complete in {results['duration']:.2f}s")
            
            return results
            
        except Exception as e:
            results['duration'] = time.time() - optimization_start
            self.logger.error(f"❌ Full optimization failed after {results['duration']:.2f}s: {e}")
            raise

def main():
    """Main optimization script"""
    import argparse
    
    parser = argparse.ArgumentParser(description='iBridge Database Optimization')
    parser.add_argument('--db-path', default='instance/ibridge.db', 
                       help='Path to database file')
    parser.add_argument('--no-backup', action='store_true',
                       help='Skip backup creation')
    parser.add_argument('--analyze-only', action='store_true',
                       help='Only analyze database, don\'t optimize')
    parser.add_argument('--cleanup-days', type=int, default=90,
                       help='Days of data to keep during cleanup')
    
    args = parser.parse_args()
    
    optimizer = DatabaseOptimizer(args.db_path)
    
    try:
        if args.analyze_only:
            # Only generate performance report
            report = optimizer.generate_performance_report()
            print("\n" + "="*50)
            print("DATABASE PERFORMANCE REPORT")
            print("="*50)
            print(f"Database Size: {report['database_analysis']['total_size'] / 1024 / 1024:.2f} MB")
            print(f"Tables: {len(report['database_analysis']['tables'])}")
            print(f"Indexes: {len(report['database_analysis']['indexes'])}")
            print(f"Fragmentation: {report['database_analysis']['fragmentation']:.2f}%")
            
            if report['optimization_suggestions']:
                print("\nOptimization Suggestions:")
                for suggestion in report['optimization_suggestions']:
                    print(f"  - {suggestion}")
            else:
                print("\nNo optimization suggestions found.")
                
        else:
            # Perform full optimization
            results = optimizer.full_optimization(create_backup=not args.no_backup)
            
            print("\n" + "="*50)
            print("OPTIMIZATION COMPLETE")
            print("="*50)
            print(f"Duration: {results['duration']:.2f} seconds")
            print(f"Indexes Created: {len(results['indexes_created'])}")
            print(f"Records Cleaned: {sum(results['cleanup_result'].values())}")
            
            if results['vacuum_result']:
                print(f"Space Saved: {results['vacuum_result']['space_saved'] / 1024 / 1024:.2f} MB")
            
            if results['suggestions']:
                print(f"\nRemaining Suggestions: {len(results['suggestions'])}")
                
    except Exception as e:
        print(f"❌ Optimization failed: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())
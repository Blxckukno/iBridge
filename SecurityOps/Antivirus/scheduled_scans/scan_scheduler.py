
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
Scheduled Scan System
Manages scheduled system scans with various scan types and configurations
"""
import asyncio
import schedule
import threading
import time
from pathlib import Path
from typing import Dict, List, Optional, Callable
from datetime import datetime, timedelta
import json

from ..core_engine.threat_detector import ThreatDetector
from ..logging.security_logger import SecurityLogger


class ScanScheduler:
    """Manages scheduled antivirus scans"""
    
    def __init__(self, threat_detector: ThreatDetector, logger: SecurityLogger):
        self.threat_detector = threat_detector
        self.logger = logger
        
        # Scheduling state
        self.scheduler_thread = None
        self.is_running = False
        
        # Scan history
        self.scan_history = []
        self.current_scan = None
        
        # Event handlers
        self.on_scan_started: Optional[Callable] = None
        self.on_scan_completed: Optional[Callable] = None
        self.on_threat_found: Optional[Callable] = None
        
        # Default schedules
        self.default_schedules = {
            "daily_quick": {
                "enabled": True,
                "time": "02:00",
                "scan_type": "quick",
                "frequency": "daily"
            },
            "weekly_full": {
                "enabled": True,
                "day": "sunday",
                "time": "03:00",
                "scan_type": "full",
                "frequency": "weekly"
            },
            "monthly_deep": {
                "enabled": False,
                "day": 1,
                "time": "01:00",
                "scan_type": "deep",
                "frequency": "monthly"
            }
        }
    
    async def initialize(self):
        """Initialize the scan scheduler"""
        self.logger.log_info("Initializing scan scheduler")
        
        # Load scan history
        await self._load_scan_history()
        
        # Setup default schedules
        await self._setup_schedules()
        
        # Start scheduler thread
        self.is_running = True
        self.scheduler_thread = threading.Thread(target=self._run_scheduler, daemon=True)
        self.scheduler_thread.start()
        
        self.logger.log_info("Scan scheduler initialized")
    
    async def _load_scan_history(self):
        """Load scan history from file"""
        try:
            history_file = Path.home() / ".antivirus_config" / "scan_history.json"
            if history_file.exists():
                with open(history_file, 'r') as f:
                    self.scan_history = json.load(f)
                    
                # Keep only last 100 scans
                self.scan_history = self.scan_history[-100:]
                
        except Exception as e:
            self.logger.log_warning(f"Could not load scan history: {e}")
            self.scan_history = []
    
    async def _save_scan_history(self):
        """Save scan history to file"""
        try:
            history_file = Path.home() / ".antivirus_config" / "scan_history.json"
            with open(history_file, 'w') as f:
                json.dump(self.scan_history, f, indent=2)
                
        except Exception as e:
            self.logger.log_error(f"Could not save scan history: {e}")
    
    async def _setup_schedules(self):
        """Setup default scan schedules"""
        for schedule_name, config in self.default_schedules.items():
            if config["enabled"]:
                if config["frequency"] == "daily":
                    schedule.every().day.at(config["time"]).do(
                        self._schedule_scan, config["scan_type"]
                    )
                elif config["frequency"] == "weekly":
                    getattr(schedule.every(), config["day"]).at(config["time"]).do(
                        self._schedule_scan, config["scan_type"]
                    )
                elif config["frequency"] == "monthly":
                    # Monthly scheduling is handled differently
                    pass
                
                self.logger.log_info(f"Scheduled {schedule_name}: {config}")
    
    def _run_scheduler(self):
        """Run the schedule in a separate thread"""
        while self.is_running:
            schedule.run_pending()
            time.sleep(60)  # Check every minute
    
    def _schedule_scan(self, scan_type: str):
        """Schedule a scan to run"""
        asyncio.create_task(self._execute_scheduled_scan(scan_type))
    
    async def _execute_scheduled_scan(self, scan_type: str):
        """Execute a scheduled scan"""
        self.logger.log_info(f"Starting scheduled {scan_type} scan")
        
        try:
            if scan_type == "quick":
                result = await self.quick_scan()
            elif scan_type == "full":
                result = await self.full_system_scan()
            elif scan_type == "deep":
                result = await self.deep_scan()
            else:
                self.logger.log_error(f"Unknown scan type: {scan_type}")
                return
            
            # Add to history
            self.scan_history.append({
                **result,
                "scheduled": True,
                "schedule_type": scan_type
            })
            
            await self._save_scan_history()
            
            # Notify completion
            if self.on_scan_completed:
                await self.on_scan_completed(result)
                
        except Exception as e:
            self.logger.log_error(f"Scheduled scan failed: {e}")
    
    async def quick_scan(self) -> Dict:
        """Perform a quick scan of critical system areas"""
        scan_result = {
            "scan_id": f"quick_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
            "scan_type": "quick",
            "start_time": datetime.now().isoformat(),
            "paths_scanned": [],
            "files_scanned": 0,
            "threats_found": [],
            "errors": [],
            "status": "running"
        }
        
        self.current_scan = scan_result
        
        if self.on_scan_started:
            await self.on_scan_started(scan_result)
        
        self.logger.log_info("Starting quick scan")
        
        # Quick scan paths (high-risk areas)
        quick_scan_paths = [
            str(Path.home() / "Downloads"),
            str(Path.home() / "Desktop"),
            str(Path.home() / "Documents"),
            "C:\\Windows\\System32",
            "C:\\Windows\\Temp",
            str(Path.home() / "AppData" / "Local" / "Temp"),
            str(Path.home() / "AppData" / "Roaming"),
        ]
        
        try:
            for path in quick_scan_paths:
                if Path(path).exists():
                    scan_result["paths_scanned"].append(path)
                    path_result = await self._scan_path(path, max_depth=2)
                    
                    scan_result["files_scanned"] += path_result["files_scanned"]
                    scan_result["threats_found"].extend(path_result["threats_found"])
                    scan_result["errors"].extend(path_result["errors"])
            
            scan_result["end_time"] = datetime.now().isoformat()
            scan_result["duration"] = self._calculate_duration(
                scan_result["start_time"], scan_result["end_time"]
            )
            scan_result["status"] = "completed"
            
        except Exception as e:
            scan_result["status"] = "error"
            scan_result["error_message"] = str(e)
            self.logger.log_error(f"Quick scan failed: {e}")
        
        self.current_scan = None
        self.logger.log_info(f"Quick scan completed: {scan_result['files_scanned']} files, "
                           f"{len(scan_result['threats_found'])} threats")
        
        return scan_result
    
    async def full_system_scan(self) -> Dict:
        """Perform a full system scan"""
        scan_result = {
            "scan_id": f"full_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
            "scan_type": "full",
            "start_time": datetime.now().isoformat(),
            "paths_scanned": [],
            "files_scanned": 0,
            "threats_found": [],
            "errors": [],
            "status": "running"
        }
        
        self.current_scan = scan_result
        
        if self.on_scan_started:
            await self.on_scan_started(scan_result)
        
        self.logger.log_info("Starting full system scan")
        
        # Full scan paths
        full_scan_paths = [
            "C:\\",
            str(Path.home()),
        ]
        
        try:
            for path in full_scan_paths:
                if Path(path).exists():
                    scan_result["paths_scanned"].append(path)
                    path_result = await self._scan_path(path, max_depth=None)
                    
                    scan_result["files_scanned"] += path_result["files_scanned"]
                    scan_result["threats_found"].extend(path_result["threats_found"])
                    scan_result["errors"].extend(path_result["errors"])
            
            scan_result["end_time"] = datetime.now().isoformat()
            scan_result["duration"] = self._calculate_duration(
                scan_result["start_time"], scan_result["end_time"]
            )
            scan_result["status"] = "completed"
            
        except Exception as e:
            scan_result["status"] = "error"
            scan_result["error_message"] = str(e)
            self.logger.log_error(f"Full scan failed: {e}")
        
        self.current_scan = None
        self.logger.log_info(f"Full scan completed: {scan_result['files_scanned']} files, "
                           f"{len(scan_result['threats_found'])} threats")
        
        return scan_result
    
    async def deep_scan(self) -> Dict:
        """Perform a deep scan with extensive analysis"""
        scan_result = {
            "scan_id": f"deep_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
            "scan_type": "deep",
            "start_time": datetime.now().isoformat(),
            "paths_scanned": [],
            "files_scanned": 0,
            "threats_found": [],
            "errors": [],
            "status": "running"
        }
        
        self.current_scan = scan_result
        
        if self.on_scan_started:
            await self.on_scan_started(scan_result)
        
        self.logger.log_info("Starting deep scan")
        
        # Deep scan includes all accessible drives
        deep_scan_paths = []
        
        # Add all available drives
        for drive in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
            drive_path = f"{drive}:\\"
            if Path(drive_path).exists():
                deep_scan_paths.append(drive_path)
        
        try:
            for path in deep_scan_paths:
                scan_result["paths_scanned"].append(path)
                path_result = await self._scan_path(path, max_depth=None, deep=True)
                
                scan_result["files_scanned"] += path_result["files_scanned"]
                scan_result["threats_found"].extend(path_result["threats_found"])
                scan_result["errors"].extend(path_result["errors"])
            
            scan_result["end_time"] = datetime.now().isoformat()
            scan_result["duration"] = self._calculate_duration(
                scan_result["start_time"], scan_result["end_time"]
            )
            scan_result["status"] = "completed"
            
        except Exception as e:
            scan_result["status"] = "error"
            scan_result["error_message"] = str(e)
            self.logger.log_error(f"Deep scan failed: {e}")
        
        self.current_scan = None
        self.logger.log_info(f"Deep scan completed: {scan_result['files_scanned']} files, "
                           f"{len(scan_result['threats_found'])} threats")
        
        return scan_result
    
    async def custom_scan(self, paths: List[str] = None, scan_options: Dict = None) -> Dict:
        """Perform a custom scan with specified paths and options"""
        if paths is None:
            paths = [str(Path.home())]
        
        if scan_options is None:
            scan_options = {"deep": False, "max_depth": None}
        
        scan_result = {
            "scan_id": f"custom_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
            "scan_type": "custom",
            "start_time": datetime.now().isoformat(),
            "paths_scanned": [],
            "files_scanned": 0,
            "threats_found": [],
            "errors": [],
            "options": scan_options,
            "status": "running"
        }
        
        self.current_scan = scan_result
        
        if self.on_scan_started:
            await self.on_scan_started(scan_result)
        
        self.logger.log_info(f"Starting custom scan of {len(paths)} paths")
        
        try:
            for path in paths:
                if Path(path).exists():
                    scan_result["paths_scanned"].append(path)
                    path_result = await self._scan_path(
                        path, 
                        max_depth=scan_options.get("max_depth"),
                        deep=scan_options.get("deep", False)
                    )
                    
                    scan_result["files_scanned"] += path_result["files_scanned"]
                    scan_result["threats_found"].extend(path_result["threats_found"])
                    scan_result["errors"].extend(path_result["errors"])
            
            scan_result["end_time"] = datetime.now().isoformat()
            scan_result["duration"] = self._calculate_duration(
                scan_result["start_time"], scan_result["end_time"]
            )
            scan_result["status"] = "completed"
            
        except Exception as e:
            scan_result["status"] = "error"
            scan_result["error_message"] = str(e)
            self.logger.log_error(f"Custom scan failed: {e}")
        
        self.current_scan = None
        self.logger.log_info(f"Custom scan completed: {scan_result['files_scanned']} files, "
                           f"{len(scan_result['threats_found'])} threats")
        
        return scan_result
    
    async def _scan_path(self, path: str, max_depth: Optional[int] = None, deep: bool = False) -> Dict:
        """Scan a specific path"""
        result = {
            "path": path,
            "files_scanned": 0,
            "threats_found": [],
            "errors": []
        }
        
        path_obj = Path(path)
        
        try:
            if path_obj.is_file():
                # Scan single file
                file_result = await self.threat_detector.scan_file(str(path_obj))
                result["files_scanned"] = 1
                
                if file_result.get("is_malicious", False):
                    result["threats_found"].append(file_result)
                    
                    if self.on_threat_found:
                        await self.on_threat_found(file_result)
                        
            elif path_obj.is_dir():
                # Scan directory
                current_depth = 0
                
                for file_path in self._walk_directory(path_obj, max_depth):
                    if file_path.is_file():
                        try:
                            # Skip files that should be excluded
                            if self._should_exclude_file(str(file_path)):
                                continue
                            
                            file_result = await self.threat_detector.scan_file(str(file_path))
                            result["files_scanned"] += 1
                            
                            if file_result.get("is_malicious", False):
                                result["threats_found"].append(file_result)
                                
                                if self.on_threat_found:
                                    await self.on_threat_found(file_result)
                            
                            # Progress logging for long scans
                            if result["files_scanned"] % 1000 == 0:
                                self.logger.log_debug(
                                    f"Scan progress: {result['files_scanned']} files scanned"
                                )
                            
                        except Exception as e:
                            result["errors"].append({
                                "file": str(file_path),
                                "error": str(e)
                            })
        
        except Exception as e:
            result["errors"].append({
                "path": path,
                "error": str(e)
            })
        
        return result
    
    def _walk_directory(self, path: Path, max_depth: Optional[int] = None):
        """Walk directory with optional depth limit"""
        if max_depth is None:
            # No depth limit
            for item in path.rglob("*"):
                yield item
        else:
            # Limited depth
            def _walk_with_depth(current_path: Path, current_depth: int):
                if current_depth > max_depth:
                    return
                
                try:
                    for item in current_path.iterdir():
                        yield item
                        if item.is_dir():
                            yield from _walk_with_depth(item, current_depth + 1)
                except PermissionError:
                    pass
            
            yield from _walk_with_depth(path, 0)
    
    def _should_exclude_file(self, file_path: str) -> bool:
        """Check if file should be excluded from scanning"""
        file_path_obj = Path(file_path)
        
        # Skip temporary files
        if file_path_obj.name.startswith('.'):
            return True
        
        # Skip by extension
        excluded_extensions = ['.tmp', '.log', '.cache', '.lock', '.dll']
        if file_path_obj.suffix.lower() in excluded_extensions:
            return True
        
        # Skip system files
        system_exclude_patterns = [
            "pagefile.sys", "hiberfil.sys", "swapfile.sys",
            "Windows\\WinSxS", "Windows\\Installer"
        ]
        
        for pattern in system_exclude_patterns:
            if pattern in str(file_path):
                return True
        
        return False
    
    def _calculate_duration(self, start_time: str, end_time: str) -> str:
        """Calculate scan duration"""
        try:
            start = datetime.fromisoformat(start_time)
            end = datetime.fromisoformat(end_time)
            duration = end - start
            
            hours, remainder = divmod(duration.total_seconds(), 3600)
            minutes, seconds = divmod(remainder, 60)
            
            return f"{int(hours):02d}:{int(minutes):02d}:{int(seconds):02d}"
            
        except Exception:
            return "00:00:00"
    
    async def cancel_current_scan(self):
        """Cancel the currently running scan"""
        if self.current_scan:
            self.current_scan["status"] = "cancelled"
            self.current_scan["end_time"] = datetime.now().isoformat()
            self.logger.log_info(f"Scan cancelled: {self.current_scan['scan_id']}")
            self.current_scan = None
    
    def get_scan_history(self, limit: int = 50) -> List[Dict]:
        """Get scan history"""
        return self.scan_history[-limit:]
    
    def get_current_scan(self) -> Optional[Dict]:
        """Get current running scan"""
        return self.current_scan
    
    def get_last_scan_time(self) -> Optional[str]:
        """Get the time of the last completed scan"""
        if self.scan_history:
            return self.scan_history[-1].get("end_time")
        return None
    
    async def add_scheduled_scan(self, name: str, schedule_config: Dict):
        """Add a new scheduled scan"""
        self.default_schedules[name] = schedule_config
        
        # Setup the new schedule
        if schedule_config["enabled"]:
            if schedule_config["frequency"] == "daily":
                schedule.every().day.at(schedule_config["time"]).do(
                    self._schedule_scan, schedule_config["scan_type"]
                )
            elif schedule_config["frequency"] == "weekly":
                getattr(schedule.every(), schedule_config["day"]).at(schedule_config["time"]).do(
                    self._schedule_scan, schedule_config["scan_type"]
                )
        
        self.logger.log_info(f"Added scheduled scan: {name}")
    
    async def remove_scheduled_scan(self, name: str):
        """Remove a scheduled scan"""
        if name in self.default_schedules:
            del self.default_schedules[name]
            # Note: schedule library doesn't have easy way to remove specific jobs
            # Would need to track jobs separately for this feature
            self.logger.log_info(f"Removed scheduled scan: {name}")
    
    async def stop(self):
        """Stop the scan scheduler"""
        self.is_running = False
        if self.scheduler_thread:
            self.scheduler_thread.join(timeout=5)
        
        # Cancel any running scan
        if self.current_scan:
            await self.cancel_current_scan()
        
        self.logger.log_info("Scan scheduler stopped")

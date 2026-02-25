
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
Quarantine Manager
Handles isolation and removal of detected threats
"""
import asyncio
import os
import shutil
import hashlib
import json
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional
import base64
import zlib

from ..core_engine.config_manager import ConfigManager
from ..logging.security_logger import SecurityLogger


class QuarantineManager:
    """Manages quarantined files and threat removal"""
    
    def __init__(self, config_manager: ConfigManager, logger: SecurityLogger):
        self.config = config_manager
        self.logger = logger
        
        # Get quarantine directory from config
        self.quarantine_dir = self.config.get_quarantine_dir()
        self.quarantine_db_path = self.quarantine_dir / "quarantine.db"
        self.quarantine_info_path = self.quarantine_dir / "quarantine_info.json"
        
        # Quarantine database
        self.quarantine_info = {}
        
        # Statistics
        self.stats = {
            "total_quarantined": 0,
            "active_quarantined": 0,
            "restored_files": 0,
            "removed_files": 0
        }
    
    async def initialize(self):
        """Initialize the quarantine system"""
        self.logger.log_info("Initializing quarantine manager")
        
        # Create quarantine directory if it doesn't exist
        self.quarantine_dir.mkdir(parents=True, exist_ok=True)
        
        # Load quarantine information
        await self._load_quarantine_info()
        
        # Clean up old quarantine entries
        await self._cleanup_quarantine()
        
        self.logger.log_info("Quarantine manager initialized")
    
    async def _load_quarantine_info(self):
        """Load quarantine database"""
        try:
            if self.quarantine_info_path.exists():
                with open(self.quarantine_info_path, 'r') as f:
                    self.quarantine_info = json.load(f)
            else:
                self.quarantine_info = {}
                
        except Exception as e:
            self.logger.log_error(f"Error loading quarantine info: {e}")
            self.quarantine_info = {}
    
    async def _save_quarantine_info(self):
        """Save quarantine database"""
        try:
            with open(self.quarantine_info_path, 'w') as f:
                json.dump(self.quarantine_info, f, indent=2)
                
        except Exception as e:
            self.logger.log_error(f"Error saving quarantine info: {e}")
    
    async def quarantine_file(self, threat_info: Dict) -> bool:
        """Quarantine a malicious file"""
        try:
            file_path = threat_info.get("file_path")
            if not file_path or not Path(file_path).exists():
                return False
            
            file_path = Path(file_path)
            
            # Generate quarantine ID
            quarantine_id = self._generate_quarantine_id(file_path)
            
            # Create quarantine entry
            quarantine_entry = {
                "original_path": str(file_path),
                "quarantine_time": datetime.now().isoformat(),
                "threat_info": threat_info,
                "file_hash": await self._calculate_file_hash(file_path),
                "is_encrypted": True,
                "status": "quarantined"
            }
            
            # Move and encrypt file
            quarantine_file_path = self.quarantine_dir / f"{quarantine_id}.quar"
            await self._encrypt_and_move_file(file_path, quarantine_file_path)
            
            # Update quarantine info
            self.quarantine_info[quarantine_id] = quarantine_entry
            await self._save_quarantine_info()
            
            # Update statistics
            self.stats["total_quarantined"] += 1
            self.stats["active_quarantined"] += 1
            
            self.logger.log_warning(f"File quarantined: {file_path}")
            return True
            
        except Exception as e:
            self.logger.log_error(f"Failed to quarantine file {file_path}: {e}")
            return False
    
    async def restore_file(self, quarantine_id: str) -> bool:
        """Restore a quarantined file to its original location"""
        try:
            if quarantine_id not in self.quarantine_info:
                return False
            
            entry = self.quarantine_info[quarantine_id]
            original_path = Path(entry["original_path"])
            quarantine_file_path = self.quarantine_dir / f"{quarantine_id}.quar"
            
            # Check if original path is safe
            if original_path.exists():
                backup_path = original_path.with_suffix(original_path.suffix + ".bak")
                shutil.move(str(original_path), str(backup_path))
            
            # Decrypt and restore file
            await self._decrypt_and_restore_file(quarantine_file_path, original_path)
            
            # Update entry
            entry["status"] = "restored"
            entry["restore_time"] = datetime.now().isoformat()
            await self._save_quarantine_info()
            
            # Update statistics
            self.stats["active_quarantined"] -= 1
            self.stats["restored_files"] += 1
            
            self.logger.log_info(f"File restored: {original_path}")
            return True
            
        except Exception as e:
            self.logger.log_error(f"Failed to restore quarantined file {quarantine_id}: {e}")
            return False
    
    async def remove_threat(self, quarantine_id: str) -> bool:
        """Permanently remove a quarantined threat"""
        try:
            if quarantine_id not in self.quarantine_info:
                return False
            
            entry = self.quarantine_info[quarantine_id]
            quarantine_file_path = self.quarantine_dir / f"{quarantine_id}.quar"
            
            # Securely delete the quarantined file
            await self._secure_delete_file(quarantine_file_path)
            
            # Update entry
            entry["status"] = "removed"
            entry["removal_time"] = datetime.now().isoformat()
            await self._save_quarantine_info()
            
            # Update statistics
            self.stats["active_quarantined"] -= 1
            self.stats["removed_files"] += 1
            
            self.logger.log_warning(f"Threat removed: {entry['original_path']}")
            return True
            
        except Exception as e:
            self.logger.log_error(f"Failed to remove threat {quarantine_id}: {e}")
            return False
    
    async def _encrypt_and_move_file(self, source_path: Path, dest_path: Path):
        """Encrypt and move file to quarantine"""
        try:
            # Read file content
            with open(source_path, 'rb') as f:
                content = f.read()
            
            # Compress content
            compressed = zlib.compress(content)
            
            # Simple encryption (for demonstration - in production use strong encryption)
            encrypted = base64.b64encode(compressed)
            
            # Write encrypted content
            with open(dest_path, 'wb') as f:
                f.write(encrypted)
            
            # Securely delete original
            await self._secure_delete_file(source_path)
            
        except Exception as e:
            raise Exception(f"Failed to encrypt and move file: {e}")
    
    async def _decrypt_and_restore_file(self, source_path: Path, dest_path: Path):
        """Decrypt and restore quarantined file"""
        try:
            # Read encrypted content
            with open(source_path, 'rb') as f:
                encrypted = f.read()
            
            # Decrypt and decompress
            compressed = base64.b64decode(encrypted)
            content = zlib.decompress(compressed)
            
            # Write restored file
            with open(dest_path, 'wb') as f:
                f.write(content)
                
        except Exception as e:
            raise Exception(f"Failed to decrypt and restore file: {e}")
    
    async def _secure_delete_file(self, file_path: Path):
        """Securely delete a file by overwriting with random data"""
        try:
            if not file_path.exists():
                return
            
            # Get file size
            file_size = file_path.stat().st_size
            
            # Overwrite file content multiple times
            for i in range(3):  # Number of overwrite passes
                with open(file_path, 'wb') as f:
                    # Write random data
                    f.write(os.urandom(file_size))
                    # Flush to disk
                    f.flush()
                    os.fsync(f.fileno())
            
            # Finally delete the file
            file_path.unlink()
            
        except Exception as e:
            raise Exception(f"Failed to securely delete file: {e}")
    
    def _generate_quarantine_id(self, file_path: Path) -> str:
        """Generate a unique quarantine ID for a file"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        file_hash = hashlib.md5(str(file_path).encode()).hexdigest()[:8]
        return f"QUAR_{timestamp}_{file_hash}"
    
    async def _calculate_file_hash(self, file_path: Path) -> str:
        """Calculate SHA-256 hash of a file"""
        sha256_hash = hashlib.sha256()
        
        with open(file_path, 'rb') as f:
            for byte_block in iter(lambda: f.read(4096), b""):
                sha256_hash.update(byte_block)
        
        return sha256_hash.hexdigest()
    
    async def _cleanup_quarantine(self):
        """Clean up old quarantine entries"""
        # Remove entries for non-existent files
        removed_entries = []
        
        for qid, entry in self.quarantine_info.items():
            quarantine_file_path = self.quarantine_dir / f"{qid}.quar"
            if not quarantine_file_path.exists() and entry["status"] == "quarantined":
                removed_entries.append(qid)
        
        for qid in removed_entries:
            del self.quarantine_info[qid]
        
        await self._save_quarantine_info()
    
    async def get_quarantine_list(self) -> List[Dict]:
        """Get list of quarantined items"""
        quarantine_list = []
        
        for qid, entry in self.quarantine_info.items():
            if entry["status"] == "quarantined":
                quarantine_list.append({
                    "id": qid,
                    "original_path": entry["original_path"],
                    "quarantine_time": entry["quarantine_time"],
                    "threat_info": entry["threat_info"]
                })
        
        return quarantine_list
    
    async def get_quarantine_count(self) -> int:
        """Get count of actively quarantined items"""
        return self.stats["active_quarantined"]
    
    def get_quarantine_stats(self) -> Dict:
        """Get quarantine statistics"""
        return self.stats.copy()
    
    async def export_quarantine_info(self, export_path: Path):
        """Export quarantine information to file"""
        try:
            with open(export_path, 'w') as f:
                json.dump(self.quarantine_info, f, indent=2)
            
            self.logger.log_info(f"Quarantine information exported to: {export_path}")
            return True
            
        except Exception as e:
            self.logger.log_error(f"Failed to export quarantine info: {e}")
            return False


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
Auto-Updater System
Automatic update system with digital signatures and rollback capability
"""

import os
import sys
import json
import hashlib
import zipfile
import tempfile
import shutil
import subprocess
import threading
import time
import requests
from pathlib import Path
from datetime import datetime, timedelta
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa, padding
from cryptography.hazmat.backends import default_backend
import logging

class AutoUpdater:
    """
    Professional auto-updater with security and reliability features
    """
    
    def __init__(self, app_root=None, config_file=None):
        self.app_root = Path(app_root) if app_root else Path(__file__).parent.parent.parent
        self.updater_dir = self.app_root / "deployment" / "updater"
        self.updater_dir.mkdir(parents=True, exist_ok=True)
        
        # Configuration
        self.config_file = config_file or (self.updater_dir / "updater_config.json")
        self.config = self._load_config()
        
        # Update settings
        self.update_server_url = self.config.get('update_server_url', 'https://updates.ibridge-security.com')
        self.check_interval_hours = self.config.get('check_interval_hours', 24)
        self.auto_install = self.config.get('auto_install', False)
        self.backup_count = self.config.get('backup_count', 3)
        
        # Directories
        self.downloads_dir = self.updater_dir / "downloads"
        self.backups_dir = self.updater_dir / "backups"
        self.temp_dir = self.updater_dir / "temp"
        
        for directory in [self.downloads_dir, self.backups_dir, self.temp_dir]:
            directory.mkdir(exist_ok=True)
        
        # Current version info
        self.current_version = self._get_current_version()
        self.product_id = self.config.get('product_id', 'ibridge-antivirus-pro')
        
        # Security
        self.public_key_path = self.updater_dir / "update_public_key.pem"
        self.signature_verification = self.config.get('signature_verification', True)
        
        # Update state
        self.update_in_progress = False
        self.last_check_time = None
        self.available_updates = []
        
        # Logging
        self.logger = self._setup_logging()
        
        # Background update checker
        self.update_checker_thread = None
        self.stop_checker = threading.Event()
        
        self.logger.info("Auto-updater initialized")
    
    def _load_config(self):
        """Load updater configuration"""
        default_config = {
            'update_server_url': 'https://updates.ibridge-security.com',
            'check_interval_hours': 24,
            'auto_install': False,
            'signature_verification': True,
            'backup_count': 3,
            'product_id': 'ibridge-antivirus-pro',
            'update_channel': 'stable',
            'retry_attempts': 3,
            'retry_delay_seconds': 300,
            'bandwidth_limit_kbps': 1024,
            'notification_enabled': True
        }
        
        try:
            if self.config_file.exists():
                with open(self.config_file, 'r') as f:
                    user_config = json.load(f)
                    default_config.update(user_config)
        except Exception as e:
            print(f"Error loading config: {e}")
        
        return default_config
    
    def _save_config(self):
        """Save updater configuration"""
        try:
            with open(self.config_file, 'w') as f:
                json.dump(self.config, f, indent=2)
        except Exception as e:
            self.logger.error(f"Error saving config: {e}")
    
    def _setup_logging(self):
        """Setup logging for updater"""
        logger = logging.getLogger('AutoUpdater')
        logger.setLevel(logging.INFO)
        
        # File handler
        log_file = self.updater_dir / "updater.log"
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
    
    def _get_current_version(self):
        """Get current application version"""
        try:
            version_file = self.app_root / "version.json"
            if version_file.exists():
                with open(version_file, 'r') as f:
                    version_info = json.load(f)
                    return version_info.get('version', '1.0.0')
            else:
                # Default version
                return '1.0.0'
        except Exception as e:
            self.logger.error(f"Error getting current version: {e}")
            return '1.0.0'
    
    def start_background_checker(self):
        """Start background update checker"""
        if self.update_checker_thread and self.update_checker_thread.is_alive():
            return False
        
        self.stop_checker.clear()
        self.update_checker_thread = threading.Thread(target=self._background_check_loop, daemon=True)
        self.update_checker_thread.start()
        
        self.logger.info("Background update checker started")
        return True
    
    def stop_background_checker(self):
        """Stop background update checker"""
        if self.update_checker_thread and self.update_checker_thread.is_alive():
            self.stop_checker.set()
            self.update_checker_thread.join(timeout=5)
            self.logger.info("Background update checker stopped")
    
    def _background_check_loop(self):
        """Background update checking loop"""
        while not self.stop_checker.is_set():
            try:
                # Check if it's time to check for updates
                if self._should_check_for_updates():
                    self.logger.info("Performing scheduled update check")
                    self.check_for_updates()
                
                # Wait for next check (check every hour, but only update based on interval)
                self.stop_checker.wait(timeout=3600)  # 1 hour
                
            except Exception as e:
                self.logger.error(f"Error in background update checker: {e}")
                self.stop_checker.wait(timeout=300)  # 5 minutes on error
    
    def _should_check_for_updates(self):
        """Determine if it's time to check for updates"""
        if not self.last_check_time:
            return True
        
        time_since_check = datetime.now() - self.last_check_time
        return time_since_check.total_seconds() >= (self.check_interval_hours * 3600)
    
    def check_for_updates(self):
        """Check for available updates"""
        try:
            self.logger.info("Checking for updates...")
            self.last_check_time = datetime.now()
            
            # Build update check request
            update_url = f"{self.update_server_url}/api/updates/check"
            
            request_data = {
                'product_id': self.product_id,
                'current_version': self.current_version,
                'platform': sys.platform,
                'architecture': 'x64' if sys.maxsize > 2**32 else 'x86',
                'channel': self.config.get('update_channel', 'stable'),
                'client_id': self._get_client_id()
            }
            
            # Make request
            response = requests.post(
                update_url,
                json=request_data,
                timeout=30,
                headers={'User-Agent': f'iBridge-Updater/{self.current_version}'}
            )
            
            if response.status_code == 200:
                update_info = response.json()
                self.available_updates = update_info.get('updates', [])
                
                if self.available_updates:
                    self.logger.info(f"Found {len(self.available_updates)} available updates")
                    
                    # Auto-install if enabled
                    if self.auto_install:
                        self._auto_install_updates()
                    else:
                        self._notify_updates_available()
                else:
                    self.logger.info("No updates available")
                
                return self.available_updates
            else:
                self.logger.error(f"Update check failed: {response.status_code}")
                return []
                
        except Exception as e:
            self.logger.error(f"Error checking for updates: {e}")
            return []
    
    def _get_client_id(self):
        """Get unique client identifier"""
        try:
            client_id_file = self.updater_dir / "client_id.txt"
            
            if client_id_file.exists():
                return client_id_file.read_text().strip()
            else:
                # Generate new client ID
                import uuid
                client_id = str(uuid.uuid4())
                client_id_file.write_text(client_id)
                return client_id
        except Exception:
            return "unknown"
    
    def download_update(self, update_info):
        """Download update package"""
        try:
            self.logger.info(f"Downloading update: {update_info['version']}")
            
            download_url = update_info['download_url']
            filename = update_info['filename']
            expected_hash = update_info['sha256_hash']
            file_size = update_info['file_size']
            
            download_path = self.downloads_dir / filename
            
            # Download with progress tracking
            response = requests.get(download_url, stream=True)
            response.raise_for_status()
            
            downloaded_size = 0
            hash_calculator = hashlib.sha256()
            
            with open(download_path, 'wb') as f:
                for chunk in response.iter_content(chunk_size=8192):
                    if chunk:
                        f.write(chunk)
                        hash_calculator.update(chunk)
                        downloaded_size += len(chunk)
                        
                        # Progress callback
                        progress = (downloaded_size / file_size) * 100
                        self._update_download_progress(progress)
            
            # Verify download
            actual_hash = hash_calculator.hexdigest()
            if actual_hash != expected_hash:
                raise ValueError(f"Hash mismatch: expected {expected_hash}, got {actual_hash}")
            
            self.logger.info(f"Download completed: {download_path}")
            return download_path
            
        except Exception as e:
            self.logger.error(f"Download failed: {e}")
            return None
    
    def _update_download_progress(self, progress):
        """Update download progress"""
        # This could be connected to UI progress bar
        if int(progress) % 10 == 0:  # Log every 10%
            self.logger.info(f"Download progress: {progress:.1f}%")
    
    def verify_update_signature(self, update_path, signature_path):
        """Verify update package digital signature"""
        try:
            if not self.signature_verification:
                self.logger.warning("Signature verification disabled")
                return True
            
            if not self.public_key_path.exists():
                self.logger.error("Public key not found for signature verification")
                return False
            
            # Load public key
            with open(self.public_key_path, 'rb') as f:
                public_key = serialization.load_pem_public_key(f.read(), backend=default_backend())

            if not isinstance(public_key, rsa.RSAPublicKey):
                self.logger.error("Public key is not an RSA key, cannot verify signature.")
                return False
            
            # Read signature
            with open(signature_path, 'rb') as f:
                signature = f.read()
            
            # Read update file
            with open(update_path, 'rb') as f:
                update_data = f.read()
            
            # Verify signature
            public_key.verify(
                signature,
                update_data,
                padding.PSS(
                    mgf=padding.MGF1(hashes.SHA256()),
                    salt_length=padding.PSS.MAX_LENGTH
                ),
                hashes.SHA256()
            )
            
            self.logger.info("Update signature verification successful")
            return True
            
        except Exception as e:
            self.logger.error(f"Signature verification failed: {e}")
            return False
    
    def create_backup(self):
        """Create backup of current installation"""
        try:
            self.logger.info("Creating installation backup...")
            
            backup_name = f"backup_{self.current_version}_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
            backup_path = self.backups_dir / backup_name
            
            # Create backup archive
            with zipfile.ZipFile(f"{backup_path}.zip", 'w', zipfile.ZIP_DEFLATED) as backup_zip:
                for root, dirs, files in os.walk(self.app_root):
                    # Skip temporary and backup directories
                    dirs[:] = [d for d in dirs if d not in ['temp', 'backups', 'downloads', '__pycache__']]
                    
                    for file in files:
                        if not file.endswith('.pyc'):
                            file_path = Path(root) / file
                            arc_path = file_path.relative_to(self.app_root)
                            backup_zip.write(file_path, arc_path)
            
            # Cleanup old backups
            self._cleanup_old_backups()
            
            self.logger.info(f"Backup created: {backup_path}.zip")
            return f"{backup_path}.zip"
            
        except Exception as e:
            self.logger.error(f"Backup creation failed: {e}")
            return None
    
    def _cleanup_old_backups(self):
        """Remove old backup files"""
        try:
            backup_files = list(self.backups_dir.glob("backup_*.zip"))
            backup_files.sort(key=lambda x: x.stat().st_mtime, reverse=True)
            
            # Keep only the specified number of backups
            for old_backup in backup_files[self.backup_count:]:
                old_backup.unlink()
                self.logger.info(f"Removed old backup: {old_backup}")
                
        except Exception as e:
            self.logger.error(f"Error cleaning up backups: {e}")
    
    def install_update(self, update_path, backup_path=None):
        """Install update package"""
        # Initialize temp_extract_dir to ensure it's always defined
        temp_extract_dir = self.temp_dir / "update_extract"
        
        try:
            self.logger.info("Installing update...")
            self.update_in_progress = True
            
            # Extract update package
            if temp_extract_dir.exists():
                shutil.rmtree(temp_extract_dir)
            temp_extract_dir.mkdir()
            
            with zipfile.ZipFile(update_path, 'r') as update_zip:
                update_zip.extractall(temp_extract_dir)
            
            # Read update manifest
            manifest_path = temp_extract_dir / "update_manifest.json"
            if not manifest_path.exists():
                raise ValueError("Update manifest not found")
            
            with open(manifest_path, 'r') as f:
                manifest = json.load(f)
            
            # Validate update compatibility
            if not self._validate_update_compatibility(manifest):
                raise ValueError("Update is not compatible with current installation")
            
            # Stop services before update
            self._stop_services()
            
            try:
                # Apply update files
                self._apply_update_files(temp_extract_dir, manifest)
                
                # Update version information
                self._update_version_info(manifest['version'])
                
                # Run post-update scripts
                self._run_post_update_scripts(temp_extract_dir)
                
                # Restart services
                self._start_services()
                
                self.logger.info(f"Update installed successfully: {manifest['version']}")
                return True
                
            except Exception as e:
                # Rollback on failure
                self.logger.error(f"Update installation failed: {e}")
                if backup_path:
                    self._rollback_update(backup_path)
                raise
            
        except Exception as e:
            self.logger.error(f"Update installation error: {e}")
            return False
        finally:
            self.update_in_progress = False
            
            # Cleanup temp files
            if temp_extract_dir.exists():
                shutil.rmtree(temp_extract_dir)
    
    def _validate_update_compatibility(self, manifest):
        """Validate update compatibility"""
        try:
            # Check minimum version requirement
            min_version = manifest.get('minimum_version')
            if min_version and self._compare_versions(self.current_version, min_version) < 0:
                self.logger.error(f"Current version {self.current_version} is below minimum required {min_version}")
                return False
            
            # Check platform compatibility
            supported_platforms = manifest.get('supported_platforms', [])
            if supported_platforms and sys.platform not in supported_platforms:
                self.logger.error(f"Platform {sys.platform} not supported")
                return False
            
            # Check file integrity
            files_to_update = manifest.get('files', [])
            for file_info in files_to_update:
                file_path = Path(file_info['path'])
                if file_info.get('required', False) and not file_path.exists():
                    self.logger.error(f"Required file not found: {file_path}")
                    return False
            
            return True
            
        except Exception as e:
            self.logger.error(f"Compatibility validation error: {e}")
            return False
    
    def _compare_versions(self, version1, version2):
        """Compare version strings"""
        def version_key(v):
            return tuple(map(int, v.split('.')))
        
        v1_key = version_key(version1)
        v2_key = version_key(version2)
        
        if v1_key < v2_key:
            return -1
        elif v1_key > v2_key:
            return 1
        else:
            return 0
    
    def _stop_services(self):
        """Stop application services before update"""
        try:
            services = [
                "iBridgeAntivirusService",
                "iBridgeFirewallService"
            ]
            
            for service in services:
                try:
                    subprocess.run(["sc", "stop", service], 
                                 capture_output=True, check=False, timeout=30)
                    self.logger.info(f"Stopped service: {service}")
                except Exception as e:
                    self.logger.warning(f"Could not stop service {service}: {e}")
            
            # Wait for services to stop
            time.sleep(5)
            
        except Exception as e:
            self.logger.error(f"Error stopping services: {e}")
    
    def _start_services(self):
        """Start application services after update"""
        try:
            services = [
                "iBridgeAntivirusService",
                "iBridgeFirewallService"
            ]
            
            for service in services:
                try:
                    subprocess.run(["sc", "start", service], 
                                 capture_output=True, check=False, timeout=30)
                    self.logger.info(f"Started service: {service}")
                except Exception as e:
                    self.logger.warning(f"Could not start service {service}: {e}")
                    
        except Exception as e:
            self.logger.error(f"Error starting services: {e}")
    
    def _apply_update_files(self, extract_dir, manifest):
        """Apply update files to installation"""
        try:
            files_to_update = manifest.get('files', [])
            
            for file_info in files_to_update:
                source_path = extract_dir / file_info['source']
                dest_path = self.app_root / file_info['path']
                
                # Create destination directory if needed
                dest_path.parent.mkdir(parents=True, exist_ok=True)
                
                # Copy/move file based on operation
                operation = file_info.get('operation', 'replace')
                
                if operation == 'replace':
                    shutil.copy2(source_path, dest_path)
                elif operation == 'delete':
                    if dest_path.exists():
                        dest_path.unlink()
                elif operation == 'append':
                    with open(source_path, 'rb') as src, open(dest_path, 'ab') as dst:
                        dst.write(src.read())
                
                self.logger.debug(f"Applied {operation}: {file_info['path']}")
            
        except Exception as e:
            self.logger.error(f"Error applying update files: {e}")
            raise
    
    def _update_version_info(self, new_version):
        """Update version information"""
        try:
            version_info = {
                'version': new_version,
                'updated_at': datetime.now().isoformat(),
                'previous_version': self.current_version
            }
            
            version_file = self.app_root / "version.json"
            with open(version_file, 'w') as f:
                json.dump(version_info, f, indent=2)
            
            self.current_version = new_version
            
        except Exception as e:
            self.logger.error(f"Error updating version info: {e}")
    
    def _run_post_update_scripts(self, extract_dir):
        """Run post-update scripts"""
        try:
            scripts_dir = extract_dir / "post_update_scripts"
            if not scripts_dir.exists():
                return
            
            for script_file in scripts_dir.glob("*.py"):
                try:
                    self.logger.info(f"Running post-update script: {script_file.name}")
                    subprocess.run([sys.executable, str(script_file)], 
                                 check=True, timeout=300)
                except Exception as e:
                    self.logger.error(f"Post-update script failed: {script_file.name}: {e}")
                    
        except Exception as e:
            self.logger.error(f"Error running post-update scripts: {e}")
    
    def _rollback_update(self, backup_path):
        """Rollback to previous version"""
        try:
            self.logger.info("Rolling back update...")
            
            # Stop services
            self._stop_services()
            
            # Extract backup
            with zipfile.ZipFile(backup_path, 'r') as backup_zip:
                backup_zip.extractall(self.app_root)
            
            # Restart services
            self._start_services()
            
            self.logger.info("Rollback completed")
            
        except Exception as e:
            self.logger.error(f"Rollback failed: {e}")
    
    def _auto_install_updates(self):
        """Automatically install available updates"""
        try:
            for update_info in self.available_updates:
                self.logger.info(f"Auto-installing update: {update_info['version']}")
                
                # Download update
                update_path = self.download_update(update_info)
                if not update_path:
                    continue
                
                # Verify signature if available
                signature_path = update_path.with_suffix('.sig')
                if signature_path.exists():
                    if not self.verify_update_signature(update_path, signature_path):
                        self.logger.error("Signature verification failed, skipping update")
                        continue
                
                # Create backup
                backup_path = self.create_backup()
                
                # Install update
                if self.install_update(update_path, backup_path):
                    self.logger.info(f"Auto-update successful: {update_info['version']}")
                    self._notify_update_installed(update_info)
                else:
                    self.logger.error(f"Auto-update failed: {update_info['version']}")
                    
        except Exception as e:
            self.logger.error(f"Auto-install error: {e}")
    
    def _notify_updates_available(self):
        """Notify user about available updates"""
        try:
            if self.config.get('notification_enabled', True):
                # This would integrate with the notification system
                notification_data = {
                    'title': 'Updates Available',
                    'message': f"{len(self.available_updates)} updates available",
                    'type': 'info',
                    'action_buttons': ['Install Now', 'Later']
                }
                self.logger.info(f"Notification: {notification_data['message']}")
                
        except Exception as e:
            self.logger.error(f"Error sending notification: {e}")
    
    def _notify_update_installed(self, update_info):
        """Notify user about installed update"""
        try:
            if self.config.get('notification_enabled', True):
                notification_data = {
                    'title': 'Update Installed',
                    'message': f"Successfully updated to version {update_info['version']}",
                    'type': 'success'
                }
                self.logger.info(f"Notification: {notification_data['message']}")
                
        except Exception as e:
            self.logger.error(f"Error sending notification: {e}")
    
    def get_update_status(self):
        """Get current update status"""
        return {
            'current_version': self.current_version,
            'last_check_time': self.last_check_time.isoformat() if self.last_check_time else None,
            'available_updates': len(self.available_updates),
            'update_in_progress': self.update_in_progress,
            'auto_install_enabled': self.auto_install,
            'next_check_time': (self.last_check_time + timedelta(hours=self.check_interval_hours)).isoformat() if self.last_check_time else None
        }
    
    def configure_updates(self, **kwargs):
        """Configure update settings"""
        try:
            for key, value in kwargs.items():
                if key in self.config:
                    self.config[key] = value
                    setattr(self, key, value)
            
            self._save_config()
            self.logger.info("Update configuration saved")
            
        except Exception as e:
            self.logger.error(f"Error configuring updates: {e}")

def main():
    """Main updater function for testing"""
    updater = AutoUpdater()
    
    print("iBridge Antivirus Pro - Auto Updater")
    print("=" * 40)
    
    # Check for updates
    updates = updater.check_for_updates()
    
    if updates:
        print(f"Found {len(updates)} available updates:")
        for update in updates:
            print(f"  - Version {update['version']}: {update['description']}")
    else:
        print("No updates available")
    
    # Show current status
    status = updater.get_update_status()
    print("\\nUpdate Status:")
    for key, value in status.items():
        print(f"  {key}: {value}")

if __name__ == "__main__":
    main()